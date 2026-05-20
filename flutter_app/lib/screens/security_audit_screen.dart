import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/nex_item.dart';
import '../services/password_generator_service.dart';
import '../services/security_audit_service.dart';
import '../state/vault_state_notifier.dart';
import 'health_ring_chart.dart';

// ---------------------------------------------------------------------------
// SecurityAuditScreen — production-grade vault health dashboard
// ---------------------------------------------------------------------------

class SecurityAuditScreen extends ConsumerStatefulWidget {
  const SecurityAuditScreen({super.key});

  @override
  ConsumerState<SecurityAuditScreen> createState() =>
      _SecurityAuditScreenState();
}

class _SecurityAuditScreenState extends ConsumerState<SecurityAuditScreen> {
  final _auditService = SecurityAuditService();
  final _generator = PasswordGeneratorService();

  AuditResult? _result;
  bool _isLoading = true;
  bool _isFixingAll = false;

  @override
  void initState() {
    super.initState();
    _runAudit();
  }

  Future<void> _runAudit() async {
    setState(() {
      _isLoading = true;
    });

    final vaultNotifier = ref.read(vaultStateProvider.notifier);
    final items = await vaultNotifier.getAllItems();
    final result = _auditService.analyze(items);

    if (mounted) {
      setState(() {
        _result = result;
        _isLoading = false;
      });
    }
  }

  Future<void> _fixItem(AuditIssue issue) async {
    final vaultNotifier = ref.read(vaultStateProvider.notifier);
    final item = issue.item;

    // Generate a strong replacement password
    final newPassword = _generator.generate(length: 20);

    // Replace the password field value
    final fieldIndex = item.fields.indexWhere(
      (f) => f.name == issue.field,
    );
    if (fieldIndex == -1) return;

    item.fields[fieldIndex].value = newPassword;
    item.fields[fieldIndex].decryptedValue = newPassword;
    item.updatedAt = DateTime.now();

    // Save to Isar
    await vaultNotifier.updateItem(item);

    // Re-run audit to reflect changes
    await _runAudit();
  }

  Future<void> _fixAll() async {
    if (_result == null) return;
    setState(() => _isFixingAll = true);

    final criticalIssues = _result!.issues
        .where((i) => i.severity == AuditSeverity.critical)
        .toList();

    for (final issue in criticalIssues) {
      await _fixItem(issue);
    }

    if (mounted) {
      setState(() => _isFixingAll = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fixed ${criticalIssues.length} issues'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.teal[900],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[950],
      appBar: AppBar(
        title: const Text(
          'Security Audit',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        actions: [
          if (_result != null && _result!.weakCount > 0)
            TextButton.icon(
              onPressed: _isFixingAll ? null : _fixAll,
              icon: _isFixingAll
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.tealAccent),
                    )
                  : const Icon(Icons.auto_fix_high, size: 18),
              label: Text(
                _isFixingAll ? 'Fixing...' : 'Fix All',
                style: const TextStyle(color: Colors.tealAccent),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _runAudit,
            tooltip: 'Re-run audit',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent))
          : _result == null
              ? const Center(
                  child: Text('No audit data',
                      style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _runAudit,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // ── Health ring chart ────────────────────────
                      _buildHealthSection(),

                      const SizedBox(height: 28),

                      // ── Summary stats row ───────────────────────
                      _buildStatsRow(),

                      const SizedBox(height: 28),

                      // ── Issues list ─────────────────────────────
                      _buildIssuesSection(),
                    ],
                  ),
                ),
    );
  }

  // ── Health section ────────────────────────────────────────────────────

  Widget _buildHealthSection() {
    final score = _result!.healthIndex;
    final label = _healthLabel(score);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          HealthRingChart(score: score, size: 180, strokeWidth: 14),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              color: _scoreColor(score),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _healthDescription(score),
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Stats row ─────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return Row(
      children: [
        _StatTile(
          label: 'Passwords',
          value: '${_result!.totalPasswords}',
          icon: Icons.key,
          color: Colors.tealAccent,
        ),
        const SizedBox(width: 12),
        _StatTile(
          label: 'Weak',
          value: '${_result!.weakCount}',
          icon: Icons.warning_amber,
          color: _result!.weakCount > 0 ? Colors.redAccent : Colors.greenAccent,
        ),
        const SizedBox(width: 12),
        _StatTile(
          label: 'Reused',
          value: '${_result!.reusedCount}',
          icon: Icons.copy,
          color: _result!.reusedCount > 0
              ? Colors.orangeAccent
              : Colors.greenAccent,
        ),
      ],
    );
  }

  // ── Issues list ───────────────────────────────────────────────────────

  Widget _buildIssuesSection() {
    if (_result!.issues.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey[900]?.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          children: [
            Icon(Icons.verified, color: Colors.greenAccent, size: 48),
            const SizedBox(height: 12),
            const Text(
              'All Clear!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No security issues found in your vault.',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Issues Found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_result!.issues.length}',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._result!.issues.map((issue) => _IssueCard(
              issue: issue,
              onFix: () => _fixItem(issue),
            )),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  String _healthLabel(double score) {
    if (score >= 0.9) return 'Excellent';
    if (score >= 0.8) return 'Good';
    if (score >= 0.6) return 'Fair';
    if (score >= 0.35) return 'Poor';
    return 'Critical';
  }

  String _healthDescription(double score) {
    if (score >= 0.9)
      return 'Your vault is in excellent condition.';
    if (score >= 0.8)
      return 'Minor issues detected. Consider fixing the warnings below.';
    if (score >= 0.6)
      return 'Some passwords need attention. Tap Fix to strengthen them.';
    if (score >= 0.35)
      return 'Multiple weak passwords detected. Fix them now to stay safe.';
    return 'Critical: your vault has severely compromised passwords.';
  }

  Color _scoreColor(double value) {
    if (value < 0.35) return const Color(0xFFEF4444);
    if (value < 0.6) return const Color(0xFFF59E0B);
    return const Color(0xFF2DD4BF);
  }
}

// ---------------------------------------------------------------------------
// Stat tile
// ---------------------------------------------------------------------------

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[900]?.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Issue card
// ---------------------------------------------------------------------------

class _IssueCard extends StatelessWidget {
  final AuditIssue issue;
  final VoidCallback onFix;

  const _IssueCard({required this.issue, required this.onFix});

  @override
  Widget build(BuildContext context) {
    final isCritical = issue.severity == AuditSeverity.critical;
    final accentColor = isCritical ? Colors.redAccent : Colors.orangeAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Severity icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCritical ? Icons.error_outline : Icons.warning_amber_outlined,
              color: accentColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        issue.item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isCritical ? 'CRITICAL' : 'WARNING',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  issue.message,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),

                // Fix button
                SizedBox(
                  height: 30,
                  child: OutlinedButton.icon(
                    onPressed: onFix,
                    icon: const Icon(Icons.auto_fix_high, size: 14),
                    label: const Text(
                      'Generate Strong Password',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.tealAccent,
                      side: BorderSide(
                          color: Colors.tealAccent.withOpacity(0.4)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

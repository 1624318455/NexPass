import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/app_localizations.dart';
import '../services/password_generator_service.dart';
import '../services/security_audit_service.dart';
import '../state/vault_state_notifier.dart';
import 'health_ring_chart.dart';

class SecurityAuditScreen extends ConsumerStatefulWidget {
  const SecurityAuditScreen({super.key});

  @override
  ConsumerState<SecurityAuditScreen> createState() => _SecurityAuditScreenState();
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
    setState(() => _isLoading = true);
    final items = await ref.read(vaultStateProvider.notifier).getAllItems();
    final result = _auditService.analyze(items);
    if (mounted) setState(() { _result = result; _isLoading = false; });
  }

  Future<void> _fixItem(AuditIssue issue) async {
    final item = issue.item;
    final newPassword = _generator.generate(length: 20);
    final idx = item.fields.indexWhere((f) => f.name == issue.field);
    if (idx == -1) return;
    item.fields[idx].value = newPassword;
    item.fields[idx].decryptedValue = newPassword;
    item.updatedAt = DateTime.now();
    await ref.read(vaultStateProvider.notifier).updateItem(item);
    await _runAudit();
  }

  Future<void> _fixAll() async {
    if (_result == null) return;
    setState(() => _isFixingAll = true);
    final criticals = _result!.issues.where((i) => i.severity == AuditSeverity.critical).toList();
    for (final issue in criticals) { await _fixItem(issue); }
    if (mounted) {
      setState(() => _isFixingAll = false);
      final S = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.fixedCount(criticals.length)), behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF161B22), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: Text(S.securityAudit, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          if (_result != null && _result!.weakCount > 0)
            TextButton(
              onPressed: _isFixingAll ? null : _fixAll,
              child: Text(_isFixingAll ? S.fixing : S.fixAll,
                  style: const TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.w600)),
            ),
          TextButton(onPressed: _runAudit, child: const Text('\u{1F504}', style: TextStyle(fontSize: 18))),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2DD4BF)))
          : _result == null
              ? Center(child: Text(S.noAuditData, style: const TextStyle(color: Color(0xFF8B949E))))
              : RefreshIndicator(
                  onRefresh: _runAudit,
                  child: ListView(padding: const EdgeInsets.all(20), children: [
                    _buildHealthSection(S),
                    const SizedBox(height: 24),
                    _buildStatsRow(S),
                    const SizedBox(height: 24),
                    _buildIssuesSection(S),
                  ]),
                ),
    );
  }

  Widget _buildHealthSection(S) {
    final score = _result!.healthIndex;
    final label = score >= 0.9 ? S.excellent : score >= 0.8 ? S.good : score >= 0.6 ? S.fair : score >= 0.35 ? S.poor : S.critical;
    final color = _scoreColor(score);
    final desc = score >= 0.9 ? S.healthExcellent : score >= 0.8 ? S.healthGood : score >= 0.6 ? S.healthFair : score >= 0.35 ? S.healthPoor : S.healthCritical;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF21262D))),
      child: Column(children: [
        HealthRingChart(score: score, size: 180, strokeWidth: 14, label: S.healthLabel),
        const SizedBox(height: 16),
        Text(label, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(desc, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 13)),
      ]),
    );
  }

  Widget _buildStatsRow(S) {
    return Row(children: [
      _statTile('\u{1F511}', '${_result!.totalPasswords}', S.statPasswords, const Color(0xFF2DD4BF)),
      const SizedBox(width: 10),
      _statTile('\u{26A0}', '${_result!.weakCount}', S.statWeak,
          _result!.weakCount > 0 ? const Color(0xFFF85149) : const Color(0xFF3FB950)),
      const SizedBox(width: 10),
      _statTile('\u{1F4CB}', '${_result!.reusedCount}', S.statReused,
          _result!.reusedCount > 0 ? const Color(0xFFD29922) : const Color(0xFF3FB950)),
    ]);
  }

  Widget _statTile(String emoji, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF21262D))),
        child: Column(children: [
          Text(emoji, style: TextStyle(fontSize: 18, color: color)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildIssuesSection(S) {
    if (_result!.issues.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF21262D))),
        child: Column(children: [
          const Text('\u{2705}', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(S.allClear, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(S.noIssuesFound, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 13)),
        ]),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(S.issuesFound, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFFF85149).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Text('${_result!.issues.length}', style: const TextStyle(color: Color(0xFFF85149), fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 12),
        ..._result!.issues.map((issue) => _issueCard(issue, () => _fixItem(issue), S)),
      ],
    );
  }

  Widget _issueCard(AuditIssue issue, VoidCallback onFix, S) {
    final isCrit = issue.severity == AuditSeverity.critical;
    final color = isCrit ? const Color(0xFFF85149) : const Color(0xFFD29922);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(isCrit ? '\u{26A0}\u{FE0F}' : '\u{26A0}', style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(issue.item.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                    child: Text(isCrit ? S.severityCritical : S.severityWarning, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(issue.message, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12, height: 1.4)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onFix,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.4)), borderRadius: BorderRadius.circular(6)),
                    child: Text(S.generateStrongPassword, style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(double v) {
    if (v < 0.35) return const Color(0xFFF85149);
    if (v < 0.6) return const Color(0xFFD29922);
    return const Color(0xFF2DD4BF);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../i18n/app_localizations.dart';
import '../services/password_generator_service.dart';
import '../services/security_audit_service.dart';
import '../state/vault_state_notifier.dart';
import '../theme/nex_theme.dart';
import '../widgets/nex_icons.dart';
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
  void initState() { super.initState(); _runAudit(); }

  Future<void> _runAudit() async {
    setState(() => _isLoading = true);
    final items = await ref.read(vaultStateProvider.notifier).getAllItems();
    final result = _auditService.analyze(items);
    if (mounted) setState(() { _result = result; _isLoading = false; });
  }

  Future<void> _fixItem(AuditIssue issue) async {
    final item = issue.item;
    final pw = _generator.generate(length: 20);
    final idx = item.fields.indexWhere((f) => f.name == issue.field);
    if (idx == -1) return;
    item.fields[idx].value = pw;
    item.fields[idx].decryptedValue = pw;
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
        SnackBar(content: Text(S.fixedCount(criticals.length))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: NexTheme.background,
      appBar: AppBar(
        title: Text(S.securityAudit, style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (_result != null && _result!.weakCount > 0)
            TextButton(
              onPressed: _isFixingAll ? null : _fixAll,
              child: Text(_isFixingAll ? S.fixing : S.fixAll,
                  style: const TextStyle(color: NexTheme.primary, fontWeight: FontWeight.w600)),
            ),
          IconButton(onPressed: _runAudit, icon: const NexIcon(NexIconType.refresh, size: 18)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: NexTheme.primary))
          : _result == null
              ? Center(child: Text(S.noAuditData, style: const TextStyle(color: NexTheme.textMuted)))
              : RefreshIndicator(
                  onRefresh: _runAudit,
                  child: ListView(padding: const EdgeInsets.all(NexTheme.xl), children: [
                    _healthSection(S),
                    const SizedBox(height: NexTheme.xxl),
                    _statsRow(S),
                    const SizedBox(height: NexTheme.xxl),
                    _issuesSection(S),
                  ]),
                ),
    );
  }

  Widget _healthSection(S) {
    final score = _result!.healthIndex;
    final label = score >= 0.9 ? S.excellent : score >= 0.8 ? S.good : score >= 0.6 ? S.fair : score >= 0.35 ? S.poor : S.critical;
    final color = _scoreColor(score);
    final desc = score >= 0.9 ? S.healthExcellent : score >= 0.8 ? S.healthGood : score >= 0.6 ? S.healthFair : score >= 0.35 ? S.healthPoor : S.healthCritical;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: NexTheme.xxl),
      decoration: BoxDecoration(color: NexTheme.surface, borderRadius: BorderRadius.circular(NexTheme.rXl), border: Border.all(color: NexTheme.border)),
      child: Column(children: [
        HealthRingChart(score: score, size: 180, strokeWidth: 14, label: S.healthLabel),
        const SizedBox(height: NexTheme.lg),
        Text(label, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: NexTheme.xs),
        Text(desc, style: const TextStyle(color: NexTheme.textSecondary, fontSize: 13)),
      ]),
    );
  }

  Widget _statsRow(S) {
    return Row(children: [
      _statTile(NexIconType.key, '${_result!.totalPasswords}', S.statPasswords, NexTheme.primary),
      const SizedBox(width: NexTheme.md),
      _statTile(NexIconType.warning, '${_result!.weakCount}', S.statWeak,
          _result!.weakCount > 0 ? NexTheme.danger : NexTheme.success),
      const SizedBox(width: NexTheme.md),
      _statTile(NexIconType.copy, '${_result!.reusedCount}', S.statReused,
          _result!.reusedCount > 0 ? NexTheme.warning : NexTheme.success),
    ]);
  }

  Widget _statTile(NexIconType icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: NexTheme.surface, borderRadius: BorderRadius.circular(NexTheme.rMd), border: Border.all(color: NexTheme.border)),
        child: Column(children: [
          NexIcon(icon, size: 18, color: color),
          const SizedBox(height: NexTheme.sm),
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: NexTheme.xs),
          Text(label, style: const TextStyle(color: NexTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _issuesSection(S) {
    if (_result!.issues.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: NexTheme.surface, borderRadius: BorderRadius.circular(NexTheme.rXl), border: Border.all(color: NexTheme.border)),
        child: Column(children: [
          const NexIcon(NexIconType.check, size: 48, color: NexTheme.success),
          const SizedBox(height: NexTheme.lg),
          Text(S.allClear, style: const TextStyle(color: NexTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: NexTheme.xs),
          Text(S.noIssuesFound, style: const TextStyle(color: NexTheme.textSecondary, fontSize: 13)),
        ]),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(S.issuesFound, style: const TextStyle(color: NexTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(width: NexTheme.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: NexTheme.dangerDim, borderRadius: BorderRadius.circular(NexTheme.rSm)),
            child: Text('${_result!.issues.length}', style: const TextStyle(color: NexTheme.danger, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: NexTheme.md),
        ..._result!.issues.map((issue) => _issueCard(issue, () => _fixItem(issue), S)),
      ],
    );
  }

  Widget _issueCard(AuditIssue issue, VoidCallback onFix, S) {
    final isCrit = issue.severity == AuditSeverity.critical;
    final color = isCrit ? NexTheme.danger : NexTheme.warning;
    final dimColor = isCrit ? NexTheme.dangerDim : NexTheme.warningDim;
    return Container(
      margin: const EdgeInsets.only(bottom: NexTheme.md),
      padding: const EdgeInsets.all(NexTheme.md),
      decoration: BoxDecoration(color: NexTheme.surface, borderRadius: BorderRadius.circular(NexTheme.rMd), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: dimColor, borderRadius: BorderRadius.circular(NexTheme.rSm)),
          child: NexIcon(isCrit ? NexIconType.alertCircle : NexIconType.warning, size: 16, color: color),
        ),
        const SizedBox(width: NexTheme.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(issue.item.name, style: const TextStyle(color: NexTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: dimColor, borderRadius: BorderRadius.circular(3)),
                child: Text(isCrit ? S.severityCritical : S.severityWarning,
                    style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
            ]),
            const SizedBox(height: NexTheme.xs),
            Text(issue.message, style: const TextStyle(color: NexTheme.textSecondary, fontSize: 12, height: 1.4)),
            const SizedBox(height: NexTheme.md),
            GestureDetector(
              onTap: onFix,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: NexTheme.primaryDim,
                  borderRadius: BorderRadius.circular(NexTheme.rSm),
                  border: Border.all(color: NexTheme.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const NexIcon(NexIconType.refresh, size: 12, color: NexTheme.primary),
                    const SizedBox(width: 6),
                    Text(S.generateStrongPassword, style: const TextStyle(color: NexTheme.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Color _scoreColor(double v) {
    if (v < 0.35) return NexTheme.danger;
    if (v < 0.6) return NexTheme.warning;
    return NexTheme.primary;
  }
}

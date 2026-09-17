import 'package:flutter/material.dart';
import '../i18n/app_localizations.dart';
import '../services/crypto_utils.dart';
import '../theme/nex_theme.dart';
import '../widgets/nex_icons.dart';

/// P2-11 (B9): Security Whitepaper — trust display, minimal slice.
///
/// Shows the audit badge slot + LIVE KDF parameters (read from
/// [CryptoService] constants so the UI can never over-claim) + the
/// encryption flow. No native changes, no attachments, trilingual.
class SecurityWhitepaperScreen extends StatelessWidget {
  const SecurityWhitepaperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(S.whitepaperTitle)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(NexTheme.lg, NexTheme.md, NexTheme.lg,
            MediaQuery.of(context).padding.bottom + NexTheme.xxl),
        children: [
          _badgeCard(S, cs, context),
          const SizedBox(height: NexTheme.md),
          _paramCard(S, cs, context),
          const SizedBox(height: NexTheme.md),
          _flowCard(S, cs, context),
          const SizedBox(height: NexTheme.md),
          _hygieneCard(S, cs, context),
        ],
      ),
    );
  }

  // ── Audit badge slot (honest: self-audited, third-party pending) ──────

  Widget _badgeCard(dynamic S, ColorScheme cs, BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(NexTheme.lg),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(NexTheme.rMd),
              ),
              child: Center(
                  child: NexIcon(NexIconType.shield,
                      size: 24, color: cs.onPrimaryContainer)),
            ),
            const SizedBox(width: NexTheme.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.wpAuditTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(S.wpAuditBody,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── LIVE KDF parameters (never hardcode — read from CryptoService) ────

  Widget _paramCard(dynamic S, ColorScheme cs, BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget row(String k, String v) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
                child: Text(k,
                    style: text.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant))),
            Text(v,
                style: text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [])),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(NexTheme.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.wpKdfTitle,
                style:
                    text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: NexTheme.sm),
            row('Argon2id iterations',
                '${CryptoService.argon2Iterations}'),
            row('Argon2id memory',
                '${CryptoService.argon2MemoryKB ~/ 1024} MB'),
            row('Argon2id parallelism',
                '${CryptoService.argon2Parallelism}'),
            row('Field cipher', 'AES-256-GCM'),
            row('File cipher', 'Isar AES-256-GCM'),
            const SizedBox(height: NexTheme.sm),
            Text(S.wpKdfNote,
                style:
                    text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  // ── Encryption flow (static architecture, matches CLAUDE.md) ──────────

  Widget _flowCard(dynamic S, ColorScheme cs, BuildContext context) {
    final steps = [S.wpFlow1, S.wpFlow2, S.wpFlow3, S.wpFlow4];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(NexTheme.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.wpFlowTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: NexTheme.sm),
            for (int i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22, height: 22,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${i + 1}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    color: cs.onSecondaryContainer,
                                    fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: NexTheme.sm),
                    Expanded(
                        child: Text(steps[i] as String,
                            style: Theme.of(context).textTheme.bodySmall)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Hygiene facts ─────────────────────────────────────────────────────

  Widget _hygieneCard(dynamic S, ColorScheme cs, BuildContext context) {
    final items = [S.wpHygiene1, S.wpHygiene2, S.wpHygiene3];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(NexTheme.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.wpHygieneTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: NexTheme.sm),
            for (final h in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NexIcon(NexIconType.check,
                        size: 16, color: cs.primary),
                    const SizedBox(width: NexTheme.sm),
                    Expanded(
                        child: Text(h as String,
                            style: Theme.of(context).textTheme.bodySmall)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

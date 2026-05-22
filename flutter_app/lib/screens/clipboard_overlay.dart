import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../i18n/app_localizations.dart';
import '../services/clipboard_service.dart';
import '../theme/nex_theme.dart';
import '../widgets/nex_icons.dart';

class DualClipboardOverlay extends ConsumerStatefulWidget {
  const DualClipboardOverlay({super.key});

  @override
  ConsumerState<DualClipboardOverlay> createState() => _DualClipboardOverlayState();
}

class _DualClipboardOverlayState extends ConsumerState<DualClipboardOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final clipState = ref.watch(dualClipboardProvider);
    if (!clipState.isVisible) return const SizedBox.shrink();

    final notifier = ref.read(dualClipboardProvider.notifier);
    final remaining = clipState.secondsRemaining;
    final progress = remaining / DualClipboardNotifier.cacheDurationSeconds;
    final S = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Positioned(
          top: MediaQuery.of(context).padding.top + NexTheme.sm,
          left: NexTheme.lg, right: NexTheme.lg,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(NexTheme.rXl),
                border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 6))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(NexTheme.xl),
                child: Stack(
                  children: [
                    Positioned(bottom: 0, left: 0,
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(height: 2, color: cs.primary.withValues(alpha: 0.5)),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(NexTheme.lg),
                      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          NexIcon(NexIconType.clipboard, size: 18, color: cs.primary),
                          const SizedBox(width: NexTheme.sm),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(S.dualClipboardActive, style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: cs.primary, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                              const SizedBox(height: 2),
                              Text(clipState.itemName, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: cs.onSurface, fontWeight: FontWeight.w600),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            ]),
                          ),
                          GestureDetector(
                            onTap: () { _ctrl.reverse().then((_) => notifier.dismiss()); },
                            child: NexIcon(NexIconType.close, size: 16, color: cs.outline),
                          ),
                        ]),

                        const SizedBox(height: NexTheme.lg),

                        Row(children: [
                          NexIcon(NexIconType.clock, size: 14, color: cs.outline),
                          const SizedBox(width: NexTheme.sm),
                          Text(S.totpToClipboard, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Clipboard.setData(ClipboardData(text: clipState.totpCode)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius: BorderRadius.circular(NexTheme.rSm),
                                border: Border.all(color: cs.outlineVariant),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Text(clipState.totpCode, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: cs.primary, fontFamily: 'monospace', fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                                const SizedBox(width: NexTheme.sm),
                                NexIcon(NexIconType.copy, size: 12, color: cs.primary),
                              ]),
                            ),
                          ),
                        ]),

                        const SizedBox(height: NexTheme.md),

                        Row(children: [
                          NexIcon(NexIconType.brain, size: 14, color: cs.outline),
                          const SizedBox(width: NexTheme.sm),
                          Text(S.passwordToRam, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: remaining > 10 ? NexTheme.success : remaining > 5 ? NexTheme.warning : NexTheme.danger,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: NexTheme.sm),
                          Text('${remaining}s', style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: remaining > 10 ? NexTheme.success : remaining > 5 ? NexTheme.warning : NexTheme.danger,
                            fontFamily: 'monospace', fontWeight: FontWeight.w700)),
                        ]),

                        const SizedBox(height: NexTheme.md),

                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(NexTheme.rSm),
                          ),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            NexIcon(NexIconType.info, size: 14, color: cs.primary),
                            const SizedBox(width: NexTheme.sm),
                            Expanded(
                              child: Text(S.clipboardCountdown(remaining),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.5)),
                            ),
                          ]),
                        ),

                        const SizedBox(height: NexTheme.sm),

                        GestureDetector(
                          onTap: () {
                            final pwd = notifier.consumePassword();
                            if (pwd != null) {
                              Clipboard.setData(ClipboardData(text: pwd));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Password ready to paste')),
                              );
                            }
                            notifier.dismiss();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(NexTheme.rSm),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                NexIcon(NexIconType.copy, size: 14, color: cs.surface),
                                const SizedBox(width: NexTheme.sm),
                                Text(S.quickPaste, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.surface, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

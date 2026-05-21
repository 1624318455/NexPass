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

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: NexTheme.lg, right: NexTheme.lg,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: NexTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(NexTheme.rXl),
                border: Border.all(color: NexTheme.primary.withOpacity(0.2)),
                boxShadow: [BoxShadow(color: NexTheme.primary.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(NexTheme.xl),
                child: Stack(
                  children: [
                    // Progress bar
                    Positioned(bottom: 0, left: 0,
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(height: 2, color: NexTheme.primary.withOpacity(0.5)),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(NexTheme.lg),
                      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // Header
                        Row(children: [
                          const NexIcon(NexIconType.clipboard, size: 18, color: NexTheme.primary),
                          const SizedBox(width: NexTheme.sm),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(S.dualClipboardActive, style: const TextStyle(
                                color: NexTheme.primary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                              const SizedBox(height: 2),
                              Text(clipState.itemName, style: const TextStyle(
                                color: NexTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            ]),
                          ),
                          GestureDetector(
                            onTap: () { _ctrl.reverse().then((_) => notifier.dismiss()); },
                            child: const NexIcon(NexIconType.close, size: 16, color: NexTheme.textMuted),
                          ),
                        ]),

                        const SizedBox(height: NexTheme.lg),

                        // TOTP row
                        Row(children: [
                          const NexIcon(NexIconType.clock, size: 14, color: NexTheme.textMuted),
                          const SizedBox(width: NexTheme.sm),
                          Text(S.totpToClipboard, style: const TextStyle(color: NexTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Clipboard.setData(ClipboardData(text: clipState.totpCode)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: NexTheme.background,
                                borderRadius: BorderRadius.circular(NexTheme.rSm),
                                border: Border.all(color: NexTheme.border),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Text(clipState.totpCode, style: const TextStyle(
                                  color: NexTheme.primary, fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                                const SizedBox(width: NexTheme.sm),
                                const NexIcon(NexIconType.copy, size: 12, color: NexTheme.primary),
                              ]),
                            ),
                          ),
                        ]),

                        const SizedBox(height: NexTheme.md),

                        // RAM row
                        Row(children: [
                          const NexIcon(NexIconType.brain, size: 14, color: NexTheme.textMuted),
                          const SizedBox(width: NexTheme.sm),
                          Text(S.passwordToRam, style: const TextStyle(color: NexTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: remaining > 10 ? NexTheme.success : remaining > 5 ? NexTheme.warning : NexTheme.danger,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: NexTheme.sm),
                          Text('${remaining}s', style: TextStyle(
                            color: remaining > 10 ? NexTheme.success : remaining > 5 ? NexTheme.warning : NexTheme.danger,
                            fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w700)),
                        ]),

                        const SizedBox(height: NexTheme.md),

                        // Guidance
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: NexTheme.primaryDim.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(NexTheme.rSm),
                          ),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const NexIcon(NexIconType.info, size: 14, color: NexTheme.primary),
                            const SizedBox(width: NexTheme.sm),
                            Expanded(
                              child: Text(S.clipboardCountdown(remaining),
                                style: const TextStyle(color: NexTheme.textSecondary, fontSize: 12, height: 1.5)),
                            ),
                          ]),
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/app_localizations.dart';
import '../services/clipboard_service.dart';

/// An animated overlay that appears when the dual-clipboard flow activates.
///
/// Displays:
/// - TOTP code copied to system clipboard
/// - Password cached in secure RAM with live countdown
/// - Guidance text for the two-step paste flow
///
/// Auto-dismisses when the RAM cache expires or the user taps to close.
class DualClipboardOverlay extends ConsumerStatefulWidget {
  const DualClipboardOverlay({super.key});

  @override
  ConsumerState<DualClipboardOverlay> createState() =>
      _DualClipboardOverlayState();
}

class _DualClipboardOverlayState extends ConsumerState<DualClipboardOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clipState = ref.watch(dualClipboardProvider);
    final S = AppLocalizations.of(context);

    if (!clipState.isVisible) return const SizedBox.shrink();

    final notifier = ref.read(dualClipboardProvider.notifier);
    final remaining = clipState.secondsRemaining;
    final progress = remaining / DualClipboardNotifier.cacheDurationSeconds;

    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: child,
          ),
        );
      },
      child: Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A2E35), Color(0xFF0F1F24)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.tealAccent.withOpacity( 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.tealAccent.withOpacity( 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Countdown progress bar
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.tealAccent.withOpacity( 0.6),
                                Colors.tealAccent.withOpacity( 0.1),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header row ──────────────────────────
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.tealAccent.withOpacity( 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('\u{1F6E1}', style: TextStyle(fontSize: 18)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    S.dualClipboardActive,
                                    style: const TextStyle(
                                      color: Colors.tealAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    clipState.itemName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                _animCtrl.reverse().then((_) {
                                  notifier.dismiss();
                                });
                              },
                              child: const Text('\u{2716}', style: TextStyle(color: Color(0xFF8B949E), fontSize: 16)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // ── TOTP row ────────────────────────────
                        _InfoRow(
                          emoji: '\u{23F0}',
                          label: S.totpToClipboard,
                          child: GestureDetector(
                            onTap: () {
                              Clipboard.setData(
                                  ClipboardData(text: clipState.totpCode));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity( 0.4),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.tealAccent.withOpacity( 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    clipState.totpCode,
                                    style: const TextStyle(
                                      color: Colors.tealAccent,
                                      fontFamily: 'monospace',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('\u{1F4CB}', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ── Password RAM cache row ──────────────
                        _InfoRow(
                          emoji: '\u{1F9E0}',
                          label: S.passwordToRam,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: remaining > 10
                                      ? Colors.greenAccent
                                      : remaining > 5
                                          ? Colors.orangeAccent
                                          : Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${remaining}s',
                                style: TextStyle(
                                  color: remaining > 10
                                      ? Colors.greenAccent
                                      : remaining > 5
                                          ? Colors.orangeAccent
                                          : Colors.redAccent,
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── Guidance text ───────────────────────
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.tealAccent.withOpacity( 0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('\u{2139}\u{FE0F}', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  S.clipboardCountdown(remaining),
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reusable row widget ─────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String emoji;
  final String label;
  final Widget child;

  const _InfoRow({
    required this.emoji,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        child,
      ],
    );
  }
}

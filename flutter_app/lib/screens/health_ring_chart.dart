import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/nex_theme.dart';

/// An animated ring chart that visualises a 0–1 health score.
///
/// The ring fills clockwise from the top, with colour transitions:
///   red (< 0.35) → orange (< 0.6) → teal (≥ 0.6)
///
/// A large percentage label is rendered in the centre.
class HealthRingChart extends StatefulWidget {
  /// Normalised health score between 0.0 and 1.0.
  final double score;

  /// Ring diameter in logical pixels.
  final double size;

  /// Stroke width of the ring.
  final double strokeWidth;

  /// Animation duration when [score] changes.
  final Duration duration;

  /// Label below the percentage (localized).
  final String label;

  const HealthRingChart({
    super.key,
    required this.score,
    this.size = 180,
    this.strokeWidth = 14,
    this.duration = const Duration(milliseconds: 900),
    this.label = 'Health',
  });

  @override
  State<HealthRingChart> createState() => _HealthRingChartState();
}

class _HealthRingChartState extends State<HealthRingChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _prevScore = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = Tween<double>(begin: 0, end: widget.score).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(HealthRingChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.score - widget.score).abs() > 0.001) {
      _prevScore = _anim.value;
      _anim = Tween<double>(begin: _prevScore, end: widget.score).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
      );
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final current = _anim.value;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: current,
              strokeWidth: widget.strokeWidth,
              trackColor: cs.outlineVariant,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(current * 100).round()}%',
                    style: TextStyle(
                      color: _scoreColor(current),
                      fontSize: widget.size * 0.22,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: cs.outline,
                      fontSize: widget.size * 0.075,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _scoreColor(double value) {
    if (value < 0.35) return NexTheme.danger;
    if (value < 0.6) return NexTheme.warning;
    return NexTheme.success;
  }
}

// ---------------------------------------------------------------------------
// CustomPainter — the actual ring arc
// ---------------------------------------------------------------------------

class _RingPainter extends CustomPainter {
  final double progress; // 0.0 – 1.0
  final double strokeWidth;
  final Color trackColor;

  _RingPainter({required this.progress, required this.strokeWidth, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - strokeWidth / 2;

    // ── Background track ─────────────────────────────────────────
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // ── Foreground arc ───────────────────────────────────────────
    final sweepAngle = 2 * math.pi * progress;
    final startAngle = -math.pi / 2; // 12 o'clock

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [
          _progressColor(0.0),
          _progressColor(progress),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );

    // ── Glow dot at the arc tip ──────────────────────────────────
    if (progress > 0.01) {
      final tipAngle = startAngle + sweepAngle;
      final tipOffset = Offset(
        center.dx + radius * math.cos(tipAngle),
        center.dy + radius * math.sin(tipAngle),
      );

      final glowPaint = Paint()
        ..color = _progressColor(progress).withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(tipOffset, strokeWidth / 2 + 2, glowPaint);

      final dotPaint = Paint()..color = _progressColor(progress);
      canvas.drawCircle(tipOffset, strokeWidth / 2 - 1, dotPaint);
    }
  }

  Color _progressColor(double value) {
    if (value < 0.35) return NexTheme.danger;
    if (value < 0.6) return NexTheme.warning;
    return NexTheme.success;
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.strokeWidth != strokeWidth;
}

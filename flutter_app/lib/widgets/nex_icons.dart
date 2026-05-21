import 'dart:math' show pi, cos, sin;
import 'package:flutter/material.dart';

enum NexIconType {
  shield, lock, gear, search, chevronRight, close,
  person, globe, stickyNote, clock, key,
  copy, trash, plus, refresh, language,
  warning, check, info, alertCircle,
  clipboard, brain, cloud,
}

class NexIcon extends StatelessWidget {
  final NexIconType type;
  final double size;
  final Color color;

  const NexIcon(this.type, {super.key, this.size = 20, this.color = const Color(0xFF7D8590)});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _NexIconPainter(type: type, color: color),
    );
  }
}

class _NexIconPainter extends CustomPainter {
  final NexIconType type;
  final Color color;

  _NexIconPainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final s = size.width;
    final cx = s / 2;
    final cy = s / 2;
    final r = s * 0.42;

    switch (type) {
      case NexIconType.shield:
        _drawShield(canvas, paint, s, cx, cy, r);
      case NexIconType.lock:
        _drawLock(canvas, paint, s, cx, cy, r);
      case NexIconType.gear:
        _drawGear(canvas, paint, s, cx, cy, r);
      case NexIconType.search:
        _drawSearch(canvas, paint, s, cx, cy, r);
      case NexIconType.chevronRight:
        _drawChevronRight(canvas, paint, s, cx, cy, r);
      case NexIconType.close:
        _drawClose(canvas, paint, s, cx, cy, r);
      case NexIconType.person:
        _drawPerson(canvas, paint, s, cx, cy, r);
      case NexIconType.globe:
        _drawGlobe(canvas, paint, s, cx, cy, r);
      case NexIconType.stickyNote:
        _drawStickyNote(canvas, paint, s, cx, cy, r);
      case NexIconType.clock:
        _drawClock(canvas, paint, s, cx, cy, r);
      case NexIconType.key:
        _drawKey(canvas, paint, s, cx, cy, r);
      case NexIconType.copy:
        _drawCopy(canvas, paint, s, cx, cy, r);
      case NexIconType.trash:
        _drawTrash(canvas, paint, s, cx, cy, r);
      case NexIconType.plus:
        _drawPlus(canvas, paint, s, cx, cy, r);
      case NexIconType.refresh:
        _drawRefresh(canvas, paint, s, cx, cy, r);
      case NexIconType.language:
        _drawLanguage(canvas, paint, s, cx, cy, r);
      case NexIconType.warning:
        _drawWarning(canvas, paint, s, cx, cy, r);
      case NexIconType.check:
        _drawCheck(canvas, paint, s, cx, cy, r);
      case NexIconType.info:
        _drawInfo(canvas, paint, s, cx, cy, r);
      case NexIconType.alertCircle:
        _drawAlertCircle(canvas, paint, s, cx, cy, r);
      case NexIconType.clipboard:
        _drawClipboard(canvas, paint, s, cx, cy, r);
      case NexIconType.brain:
        _drawBrain(canvas, paint, s, cx, cy, r);
      case NexIconType.cloud:
        _drawCloud(canvas, paint, s, cx, cy, r);
    }
  }

  void _drawShield(Canvas c, Paint p, double s, double cx, double cy, double r) {
    final path = Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx + r * 0.85, cy - r * 0.55)
      ..lineTo(cx + r * 0.85, cy + r * 0.1)
      ..quadraticBezierTo(cx + r * 0.6, cy + r * 0.85, cx, cy + r)
      ..quadraticBezierTo(cx - r * 0.6, cy + r * 0.85, cx - r * 0.85, cy + r * 0.1)
      ..lineTo(cx - r * 0.85, cy - r * 0.55)
      ..close();
    c.drawPath(path, p);
  }

  void _drawLock(Canvas c, Paint p, double s, double cx, double cy, double r) {
    final arcR = r * 0.5;
    final arcRect = Rect.fromCenter(center: Offset(cx, cy - r * 0.15), width: arcR * 2, height: arcR * 1.8);
    c.drawArc(arcRect, pi, pi, false, p);
    final bodyR = r * 0.65;
    c.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + r * 0.35), width: bodyR * 2, height: bodyR * 1.1),
      const Radius.circular(3),
    ), p);
  }

  void _drawGear(Canvas c, Paint p, double s, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy), r * 0.35, p);
    for (var i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      final x1 = cx + r * 0.55 * cos(angle);
      final y1 = cy + r * 0.55 * sin(angle);
      final x2 = cx + r * 0.78 * cos(angle);
      final y2 = cy + r * 0.78 * sin(angle);
      c.drawLine(Offset(x1, y1), Offset(x2, y2), p);
    }
  }

  void _drawSearch(Canvas c, Paint p, double s, double cx, double cy, double r) {
    c.drawCircle(Offset(cx - r * 0.15, cy - r * 0.15), r * 0.55, p);
    final lx = cx + r * 0.25;
    final ly = cy + r * 0.25;
    c.drawLine(Offset(lx, ly), Offset(lx + r * 0.55, ly + r * 0.55), p);
  }

  void _drawChevronRight(Canvas c, Paint p, double s, double cx, double cy, double r) {
    final path = Path()
      ..moveTo(cx - r * 0.4, cy - r * 0.5)
      ..lineTo(cx + r * 0.2, cy)
      ..lineTo(cx - r * 0.4, cy + r * 0.5);
    c.drawPath(path, p);
  }

  void _drawClose(Canvas c, Paint p, double s, double cx, double cy, double r) {
    final d = r * 0.5;
    c.drawLine(Offset(cx - d, cy - d), Offset(cx + d, cy + d), p);
    c.drawLine(Offset(cx + d, cy - d), Offset(cx - d, cy + d), p);
  }

  void _drawPerson(Canvas c, Paint p, double s, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy - r * 0.3), r * 0.3, p);
    c.drawArc(
      Rect.fromCenter(center: Offset(cx, cy + r * 0.45), width: r * 1.6, height: r * 1.0),
      pi, pi, false, p,
    );
  }

  void _drawGlobe(Canvas c, Paint p, double s, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy), r * 0.7, p);
    c.drawLine(Offset(cx - r * 0.7, cy), Offset(cx + r * 0.7, cy), p);
    c.drawArc(Rect.fromCenter(center: Offset(cx, cy), width: r * 0.6, height: r * 1.4),
      -pi / 2, pi, false, p);
  }

  void _drawStickyNote(Canvas c, Paint p, double s, double cx, double cy, double r) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: r * 1.5, height: r * 1.5),
      const Radius.circular(3),
    );
    c.drawRRect(rect, p);
    c.drawLine(Offset(cx - r * 0.45, cy - r * 0.3), Offset(cx + r * 0.45, cy - r * 0.3), p);
    c.drawLine(Offset(cx - r * 0.45, cy), Offset(cx + r * 0.2, cy), p);
  }

  void _drawClock(Canvas c, Paint p, double s, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy), r * 0.7, p);
    c.drawLine(Offset(cx, cy), Offset(cx, cy - r * 0.4), p);
    c.drawLine(Offset(cx, cy), Offset(cx + r * 0.3, cy + r * 0.1), p);
  }

  void _drawKey(Canvas c, Paint p, double s, double cx, double cy, double r) {
    c.drawCircle(Offset(cx - r * 0.25, cy - r * 0.1), r * 0.35, p);
    c.drawLine(Offset(cx - r * 0.05, cy + r * 0.15), Offset(cx + r * 0.6, cy + r * 0.55), p);
    c.drawLine(Offset(cx + r * 0.4, cy + r * 0.35), Offset(cx + r * 0.55, cy + r * 0.2), p);
  }

  void _drawCopy(Canvas c, Paint p, double s, double cx, double cy, double r) {
    final s1 = r * 0.55;
    c.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + r * 0.1, cy + r * 0.1), width: s1 * 1.4, height: s1 * 1.5),
      const Radius.circular(2),
    ), p);
    final s2 = r * 0.45;
    c.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - r * 0.15, cy - r * 0.15), width: s2 * 1.4, height: s2 * 1.5),
      const Radius.circular(2),
    ), p);
  }

  void _drawTrash(Canvas c, Paint p, double s, double cx, double cy, double r) {
    c.drawLine(Offset(cx - r * 0.5, cy - r * 0.3), Offset(cx + r * 0.5, cy - r * 0.3), p);
    c.drawLine(Offset(cx - r * 0.25, cy - r * 0.65), Offset(cx + r * 0.25, cy - r * 0.65), p);
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy - r * 0.05), width: r * 1.2, height: r * 1.0),
      const Radius.circular(2),
    );
    c.drawRRect(body, p);
  }

  void _drawPlus(Canvas c, Paint p, double s, double cx, double cy, double r) {
    c.drawLine(Offset(cx, cy - r * 0.6), Offset(cx, cy + r * 0.6), p);
    c.drawLine(Offset(cx - r * 0.6, cy), Offset(cx + r * 0.6, cy), p);
  }

  void _drawRefresh(Canvas c, Paint p, double s, double cx, double cy, double r) {
    c.drawArc(Rect.fromCenter(center: Offset(cx, cy), width: r * 1.3, height: r * 1.3),
      -pi / 4, pi * 1.6, false, p);
    final tip = Offset(cx + r * 0.55, cy - r * 0.55);
    c.drawLine(Offset(cx + r * 0.55, cy - r * 0.85), tip, p);
    c.drawLine(tip, Offset(cx + r * 0.85, cy - r * 0.45), p);
  }

  void _drawLanguage(Canvas c, Paint p, double s, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy), r * 0.7, p);
    c.drawLine(Offset(cx, cy - r * 0.7), Offset(cx, cy + r * 0.7), p);
    c.drawArc(Rect.fromCenter(center: Offset(cx, cy), width: r * 1.4, height: r * 1.2),
      0, pi, false, p);
    c.drawLine(Offset(cx - r * 0.35, cy - r * 0.35), Offset(cx + r * 0.35, cy - r * 0.35), p);
  }

  void _drawWarning(Canvas c, Paint p, double s, double cx, double cy, double r) {
    final path = Path()
      ..moveTo(cx, cy - r * 0.75)
      ..lineTo(cx + r * 0.65, cy + r * 0.55)
      ..lineTo(cx - r * 0.65, cy + r * 0.55)
      ..close();
    c.drawPath(path, p);
    c.drawLine(Offset(cx, cy - r * 0.15), Offset(cx, cy + r * 0.2), p);
    c.drawCircle(Offset(cx, cy + r * 0.38), 2, p);
  }

  void _drawCheck(Canvas c, Paint p, double s, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy), r * 0.7, p);
    final path = Path()
      ..moveTo(cx - r * 0.3, cy)
      ..lineTo(cx - r * 0.05, cy + r * 0.3)
      ..lineTo(cx + r * 0.35, cy - r * 0.3);
    c.drawPath(path, p);
  }

  void _drawInfo(Canvas c, Paint p, double s, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy), r * 0.7, p);
    c.drawCircle(Offset(cx, cy - r * 0.3), 2, p);
    c.drawLine(Offset(cx, cy - r * 0.05), Offset(cx, cy + r * 0.35), p);
  }

  void _drawAlertCircle(Canvas c, Paint p, double s, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy), r * 0.7, p);
    c.drawLine(Offset(cx, cy - r * 0.35), Offset(cx, cy + r * 0.05), p);
    c.drawCircle(Offset(cx, cy + r * 0.25), 2, p);
  }

  void _drawClipboard(Canvas c, Paint p, double s, double cx, double cy, double r) {
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + r * 0.05), width: r * 1.2, height: r * 1.4),
      const Radius.circular(3),
    );
    c.drawRRect(body, p);
    final clip = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy - r * 0.5), width: r * 0.7, height: r * 0.4),
      const Radius.circular(2),
    );
    c.drawRRect(clip, p);
  }

  void _drawBrain(Canvas c, Paint p, double s, double cx, double cy, double r) {
    c.drawArc(Rect.fromCenter(center: Offset(cx - r * 0.1, cy - r * 0.05), width: r * 0.8, height: r * 1.1),
      -pi / 2, pi, false, p);
    c.drawArc(Rect.fromCenter(center: Offset(cx + r * 0.1, cy - r * 0.05), width: r * 0.8, height: r * 1.1),
      pi / 2, pi, false, p);
  }

  void _drawCloud(Canvas c, Paint p, double s, double cx, double cy, double r) {
    final path = Path()
      ..moveTo(cx - r * 0.5, cy + r * 0.2)
      ..quadraticBezierTo(cx - r * 0.7, cy - r * 0.3, cx - r * 0.2, cy - r * 0.35)
      ..quadraticBezierTo(cx - r * 0.05, cy - r * 0.75, cx + r * 0.3, cy - r * 0.45)
      ..quadraticBezierTo(cx + r * 0.7, cy - r * 0.35, cx + r * 0.6, cy + r * 0.1)
      ..quadraticBezierTo(cx + r * 0.55, cy + r * 0.4, cx, cy + r * 0.4)
      ..quadraticBezierTo(cx - r * 0.45, cy + r * 0.42, cx - r * 0.5, cy + r * 0.2);
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_NexIconPainter old) => old.type != type || old.color != color;
}

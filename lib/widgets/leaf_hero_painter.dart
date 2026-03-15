import 'package:flutter/material.dart';
import 'dart:math' as math;

class LeafHeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // ── Dashed spinning ring 1 ──────────────────────────────────────────────
    _drawDashedCircle(
      canvas,
      Offset(cx, cy),
      size.height * 0.44,
      const Color(0xFF4A8C3F).withOpacity(0.35),
      1.5,
    );

    // ── Dashed spinning ring 2 (smaller) ───────────────────────────────────
    _drawDashedCircle(
      canvas,
      Offset(cx, cy),
      size.height * 0.32,
      const Color(0xFFC8442A).withOpacity(0.2),
      1.2,
    );

    // ── Leaf body ──────────────────────────────────────────────────────────
    final leafPath = Path();
    final lw = size.width * 0.22;
    final lh = size.height * 0.78;
    final lx = cx - lw / 2;
    final ly = cy - lh / 2 + 6;

    leafPath.moveTo(cx, ly + lh * 0.12); // top tip
    leafPath.cubicTo(
      cx + lw * 0.8, ly + lh * 0.04,
      cx + lw * 1.05, ly + lh * 0.45,
      cx, ly + lh,
    );
    leafPath.cubicTo(
      cx - lw * 1.05, ly + lh * 0.45,
      cx - lw * 0.8, ly + lh * 0.04,
      cx, ly + lh * 0.12,
    );

    final leafPaint = Paint()
      ..color = const Color(0xFF4A8C3F).withOpacity(0.9)
      ..style = PaintingStyle.fill;
    canvas.drawPath(leafPath, leafPaint);

    // ── Leaf highlight (lighter inner shape) ───────────────────────────────
    final highlightPath = Path();
    final hlw = lw * 0.8;
    final hlh = lh * 0.9;
    final hlx = cx;
    final hly = ly + lh * 0.08;

    highlightPath.moveTo(hlx, hly);
    highlightPath.cubicTo(
      hlx + hlw * 0.5, hly + hlh * 0.04,
      hlx + hlw * 0.6, hly + hlh * 0.5,
      hlx, hly + hlh,
    );
    highlightPath.cubicTo(
      hlx - hlw * 0.6, hly + hlh * 0.5,
      hlx - hlw * 0.5, hly + hlh * 0.04,
      hlx, hly,
    );

    final highlightPaint = Paint()
      ..color = const Color(0xFF5AA84E).withOpacity(0.55)
      ..style = PaintingStyle.fill;
    canvas.drawPath(highlightPath, highlightPaint);

    // ── Center vein ────────────────────────────────────────────────────────
    final veinPaint = Paint()
      ..color = const Color(0xFF3A7030).withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx, ly + lh * 0.15),
      Offset(cx, ly + lh * 0.95),
      veinPaint,
    );

    // Side veins
    final sideVein = Paint()
      ..color = const Color(0xFF3A7030).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(cx, ly + lh * 0.35), Offset(cx - lw * 0.7, ly + lh * 0.2), sideVein);
    canvas.drawLine(Offset(cx, ly + lh * 0.5), Offset(cx + lw * 0.7, ly + lh * 0.38), sideVein);
    canvas.drawLine(Offset(cx, ly + lh * 0.65), Offset(cx - lw * 0.65, ly + lh * 0.55), sideVein);

    // ── Disease spots ──────────────────────────────────────────────────────
    final spotPaint = Paint()
      ..color = const Color(0xFFC8442A).withOpacity(0.7)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(cx - lw * 0.5, cy + 4), 8, spotPaint);

    final spotPaint2 = Paint()
      ..color = const Color(0xFFC8442A).withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx + lw * 0.55, cy - 8), 7, spotPaint2);
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double strokeWidth,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    const dashCount = 20;
    const dashAngle = (2 * math.pi) / dashCount;
    const gapFraction = 0.4;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      final sweepAngle = dashAngle * (1 - gapFraction);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

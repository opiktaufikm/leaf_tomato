import 'package:flutter/material.dart';

class ScannerBox extends StatelessWidget {
  final AnimationController scanAnimation;
  final bool isDetecting;

  const ScannerBox({
    super.key,
    required this.scanAnimation,
    required this.isDetecting,
  });

  @override
  Widget build(BuildContext context) {
    const boxSize = 200.0;
    const cornerSize = 24.0;
    const cornerThickness = 2.5;
    const cornerColor = Color(0xFF5DCF4E);
    const cornerRadius = 5.0;

    return SizedBox(
      width: boxSize,
      height: boxSize,
      child: Stack(
        children: [
          // ── Corner brackets ───────────────────────────────────────────────
          // Top-left
          Positioned(
            top: 0, left: 0,
            child: _Corner(
              alignment: Alignment.topLeft,
              size: cornerSize,
              thickness: cornerThickness,
              color: cornerColor,
              radius: cornerRadius,
            ),
          ),
          // Top-right
          Positioned(
            top: 0, right: 0,
            child: _Corner(
              alignment: Alignment.topRight,
              size: cornerSize,
              thickness: cornerThickness,
              color: cornerColor,
              radius: cornerRadius,
            ),
          ),
          // Bottom-left
          Positioned(
            bottom: 0, left: 0,
            child: _Corner(
              alignment: Alignment.bottomLeft,
              size: cornerSize,
              thickness: cornerThickness,
              color: cornerColor,
              radius: cornerRadius,
            ),
          ),
          // Bottom-right
          Positioned(
            bottom: 0, right: 0,
            child: _Corner(
              alignment: Alignment.bottomRight,
              size: cornerSize,
              thickness: cornerThickness,
              color: cornerColor,
              radius: cornerRadius,
            ),
          ),

          // ── Animated scan line ─────────────────────────────────────────────
          AnimatedBuilder(
            animation: scanAnimation,
            builder: (context, child) {
              return Positioned(
                top: scanAnimation.value * (boxSize - 2),
                left: 16,
                right: 16,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFF5DCF4E).withOpacity(0.9),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              );
            },
          ),

          // ── Simulated leaf ─────────────────────────────────────────────────
          Center(
            child: Opacity(
              opacity: 0.7,
              child: CustomPaint(
                size: const Size(80, 72),
                painter: _MiniLeafPainter(isDetecting: isDetecting),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── L-shaped corner bracket ────────────────────────────────────────────────────
class _Corner extends StatelessWidget {
  final Alignment alignment;
  final double size;
  final double thickness;
  final Color color;
  final double radius;

  const _Corner({
    required this.alignment,
    required this.size,
    required this.thickness,
    required this.color,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment == Alignment.topLeft ||
        alignment == Alignment.bottomLeft;
    final isTop = alignment == Alignment.topLeft ||
        alignment == Alignment.topRight;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          isLeft: isLeft,
          isTop: isTop,
          color: color,
          thickness: thickness,
          cornerRadius: radius,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool isLeft;
  final bool isTop;
  final Color color;
  final double thickness;
  final double cornerRadius;

  _CornerPainter({
    required this.isLeft,
    required this.isTop,
    required this.color,
    required this.thickness,
    required this.cornerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (isTop && isLeft) {
      path.moveTo(0, size.height * 0.8);
      path.lineTo(0, cornerRadius);
      path.quadraticBezierTo(0, 0, cornerRadius, 0);
      path.lineTo(size.width * 0.8, 0);
    } else if (isTop && !isLeft) {
      path.moveTo(size.width * 0.2, 0);
      path.lineTo(size.width - cornerRadius, 0);
      path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);
      path.lineTo(size.width, size.height * 0.8);
    } else if (!isTop && isLeft) {
      path.moveTo(0, size.height * 0.2);
      path.lineTo(0, size.height - cornerRadius);
      path.quadraticBezierTo(
          0, size.height, cornerRadius, size.height);
      path.lineTo(size.width * 0.8, size.height);
    } else {
      path.moveTo(size.width * 0.2, size.height);
      path.lineTo(size.width - cornerRadius, size.height);
      path.quadraticBezierTo(
          size.width, size.height, size.width, size.height - cornerRadius);
      path.lineTo(size.width, size.height * 0.2);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Simple leaf silhouette inside viewfinder ───────────────────────────────────
class _MiniLeafPainter extends CustomPainter {
  final bool isDetecting;

  const _MiniLeafPainter({required this.isDetecting});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final leafPath = Path()
      ..moveTo(cx, 0)
      ..cubicTo(
          cx + size.width * 0.5, 2, cx + size.width * 0.55, size.height * 0.5, cx, size.height)
      ..cubicTo(
          cx - size.width * 0.55, size.height * 0.5, cx - size.width * 0.5, 2, cx, 0);

    canvas.drawPath(
      leafPath,
      Paint()
        ..color = const Color(0xFF3A7030).withOpacity(0.8)
        ..style = PaintingStyle.fill,
    );

    // vein
    canvas.drawLine(
      Offset(cx, 4),
      Offset(cx, size.height - 4),
      Paint()
        ..color = const Color(0xFF5AA84E).withOpacity(0.5)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );

    if (isDetecting) {
      canvas.drawCircle(
        Offset(cx - 14, cy + 4),
        6,
        Paint()
          ..color = const Color(0xFFD4692A).withOpacity(0.85)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(cx + 16, cy - 7),
        5,
        Paint()
          ..color = const Color(0xFFD4692A).withOpacity(0.6)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

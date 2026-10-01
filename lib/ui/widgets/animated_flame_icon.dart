import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A small, continuously flickering flame drawn with [CustomPainter].
///
/// Unlike a static SVG, the silhouette's control points are re-computed
/// every frame from layered sine waves, so the tips actually wander the way
/// a real flame does — not just a uniform scale/opacity pulse.
class AnimatedFlameIcon extends StatefulWidget {
  final double size;

  const AnimatedFlameIcon({super.key, this.size = 16});

  @override
  State<AnimatedFlameIcon> createState() => _AnimatedFlameIconState();
}

class _AnimatedFlameIconState extends State<AnimatedFlameIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: Size.square(widget.size),
        painter: _FlamePainter(_controller.value),
      ),
    );
  }
}

class _FlamePainter extends CustomPainter {
  final double t;

  _FlamePainter(this.t);

  double _wobble(double freq, double phase, double amp) =>
      amp * math.sin(2 * math.pi * (t * freq + phase));

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Outer flame — wavering tip and shoulders.
    final tipX = w * 0.5 + _wobble(1.0, 0.0, w * 0.07);
    final rightX = w * 0.86 + _wobble(1.15, 0.6, w * 0.045);
    final leftX = w * 0.15 + _wobble(1.3, 0.25, w * 0.045);

    final outer = Path()
      ..moveTo(w * 0.5, h * 0.04)
      ..cubicTo(w * 0.5, h * 0.18, rightX, h * 0.3, rightX, h * 0.52)
      ..cubicTo(rightX, h * 0.76, w * 0.66, h * 0.94, w * 0.5, h * 0.94)
      ..cubicTo(w * 0.34, h * 0.94, leftX, h * 0.76, leftX, h * 0.52)
      ..cubicTo(leftX, h * 0.3, w * 0.42, h * 0.18, tipX, h * 0.04)
      ..close();

    final outerRect = Rect.fromLTWH(0, 0, w, h);
    final outerPaint = Paint()
      ..shader = const LinearGradient(
        // Deliberately its own red, not AppTheme.danger — a streak flame and
        // an error state happening to share a hex would be coincidental.
        colors: [Color(0xFFFBBF24), Color(0xFFE11D48)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(outerRect);
    canvas.drawPath(outer, outerPaint);

    // Inner core — flickers slightly out of phase with the outer silhouette.
    final coreRightX = w * 0.68 + _wobble(1.6, 0.75, w * 0.03);
    final coreLeftX = w * 0.32 + _wobble(1.8, 0.1, w * 0.03);

    final inner = Path()
      ..moveTo(w * 0.5, h * 0.42)
      ..cubicTo(w * 0.5, h * 0.5, coreRightX, h * 0.55, coreRightX, h * 0.68)
      ..cubicTo(coreRightX, h * 0.82, w * 0.58, h * 0.9, w * 0.5, h * 0.9)
      ..cubicTo(w * 0.42, h * 0.9, coreLeftX, h * 0.82, coreLeftX, h * 0.68)
      ..cubicTo(coreLeftX, h * 0.55, w * 0.5, h * 0.5, w * 0.5, h * 0.42)
      ..close();

    final innerRect = Rect.fromLTWH(w * 0.25, h * 0.4, w * 0.5, h * 0.5);
    final innerPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFEF3C7), Color(0xFFF97316)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(innerRect);
    canvas.drawPath(inner, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _FlamePainter oldDelegate) => oldDelegate.t != t;
}

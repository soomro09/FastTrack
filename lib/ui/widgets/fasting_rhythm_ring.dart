import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A two-tone ring that shows the real fasting/eating split of the current
/// plan (e.g. 16:8 → 2/3 indigo, 1/3 amber), drawn with [CustomPainter] so
/// it can redraw itself when the plan changes and rotate slowly (one full
/// turn per 24 "seconds" — a nod to the daily cycle it represents).
class FastingRhythmRing extends StatefulWidget {
  final int targetHours;
  final double size;

  const FastingRhythmRing({
    super.key,
    required this.targetHours,
    this.size = 44,
  });

  @override
  State<FastingRhythmRing> createState() => _FastingRhythmRingState();
}

class _FastingRhythmRingState extends State<FastingRhythmRing>
    with TickerProviderStateMixin {
  late final AnimationController _drawController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _drawAnim = CurvedAnimation(
    parent: _drawController,
    curve: Curves.easeOutCubic,
  );
  late final AnimationController _rotateController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _drawController.forward();
  }

  @override
  void didUpdateWidget(covariant FastingRhythmRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetHours != widget.targetHours) {
      _drawController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _drawController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fastFraction = widget.targetHours.clamp(1, 23) / 24.0;
    return AnimatedBuilder(
      animation: Listenable.merge([_drawAnim, _rotateController]),
      builder: (context, _) => CustomPaint(
        size: Size.square(widget.size),
        painter: _RhythmRingPainter(
          fastFraction: fastFraction,
          drawProgress: _drawAnim.value,
          rotation: _rotateController.value * 2 * math.pi,
        ),
      ),
    );
  }
}

class _RhythmRingPainter extends CustomPainter {
  final double fastFraction;
  final double drawProgress;
  final double rotation;

  _RhythmRingPainter({
    required this.fastFraction,
    required this.drawProgress,
    required this.rotation,
  });

  static const _fastColors = [
    AppTheme.primaryGradientStart,
    AppTheme.primaryGradientEnd,
  ];
  static const _eatColors = [AppTheme.accentLight, AppTheme.accent];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - size.width * 0.11;
    final strokeWidth = size.width * 0.2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    canvas.drawCircle(
      center,
      radius * 0.55,
      Paint()..color = AppTheme.primary.withAlpha(18),
    );

    final totalSweep = 2 * math.pi * drawProgress;
    final fastFull = 2 * math.pi * fastFraction;
    final fastSweep = math.min(totalSweep, fastFull);
    final eatSweep = math.max(0.0, totalSweep - fastFull);

    if (fastSweep > 0) {
      canvas.drawArc(
        rect,
        startAngle,
        fastSweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..shader = const LinearGradient(colors: _fastColors).createShader(rect),
      );
    }

    if (eatSweep > 0) {
      canvas.drawArc(
        rect,
        startAngle + fastFull,
        eatSweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..shader = const LinearGradient(colors: _eatColors).createShader(rect),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RhythmRingPainter oldDelegate) =>
      oldDelegate.fastFraction != fastFraction ||
      oldDelegate.drawProgress != drawProgress ||
      oldDelegate.rotation != rotation;
}

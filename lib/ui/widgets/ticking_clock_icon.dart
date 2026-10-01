import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_svgs.dart';

/// The history-tab empty state: a static gradient ring (SVG) with two hands
/// that tick continuously, drawn on top with [CustomPainter] so they can
/// rotate independently around the exact center of the ring.
class TickingClockIcon extends StatefulWidget {
  final double size;

  const TickingClockIcon({super.key, this.size = 100});

  @override
  State<TickingClockIcon> createState() => _TickingClockIconState();
}

class _TickingClockIconState extends State<TickingClockIcon>
    with TickerProviderStateMixin {
  late final AnimationController _hourController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 48),
  )..repeat();
  late final AnimationController _minuteController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.string(
            AppSvgs.emptyHistoryFace,
            width: widget.size,
            height: widget.size,
          ),
          AnimatedBuilder(
            animation: Listenable.merge([_hourController, _minuteController]),
            builder: (context, _) => CustomPaint(
              size: Size.square(widget.size),
              painter: _ClockHandsPainter(
                hourAngle: _hourController.value * 2 * math.pi,
                minuteAngle: _minuteController.value * 2 * math.pi,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClockHandsPainter extends CustomPainter {
  final double hourAngle;
  final double minuteAngle;

  _ClockHandsPainter({required this.hourAngle, required this.minuteAngle});

  void _drawHand(
    Canvas canvas,
    Offset center,
    double angle,
    double length,
    double strokeWidth,
    Color color,
  ) {
    final end = center + Offset(math.sin(angle) * length, -math.cos(angle) * length);
    canvas.drawLine(
      center,
      end,
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    _drawHand(canvas, center, hourAngle, size.width * 0.17, size.width * 0.045,
        const Color(0xFF0F766E));
    _drawHand(canvas, center, minuteAngle, size.width * 0.27, size.width * 0.045,
        const Color(0xFFC2703D));
    canvas.drawCircle(center, size.width * 0.055, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _ClockHandsPainter oldDelegate) =>
      oldDelegate.hourAngle != hourAngle || oldDelegate.minuteAngle != minuteAngle;
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AnimatedTimerRing extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final bool isFasting;
  final Duration elapsedTime;
  final Duration remainingTime;
  final int targetHours;
  final VoidCallback? onAdjustStartTime;

  const AnimatedTimerRing({
    super.key,
    required this.progress,
    required this.isFasting,
    required this.elapsedTime,
    required this.remainingTime,
    required this.targetHours,
    this.onAdjustStartTime,
  });

  @override
  State<AnimatedTimerRing> createState() => _AnimatedTimerRingState();
}

class _AnimatedTimerRingState extends State<AnimatedTimerRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isFasting) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedTimerRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFasting && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isFasting && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = d.inHours;
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "${twoDigits(hours)}:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final percentage = (widget.progress * 100).toInt();

    // The ring's fill (widget.progress) is already clamped at the target,
    // but the big digital readout used raw elapsed time and kept climbing
    // past it. Cap the displayed time the same way so both stop together.
    final targetDuration = Duration(hours: widget.targetHours);
    final displayedElapsed = widget.elapsedTime > targetDuration
        ? targetDuration
        : widget.elapsedTime;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = widget.isFasting ? _pulseAnimation.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Center(
        child: SizedBox(
          width: 270,
          height: 270,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ambient outer glow — a single soft halo instead of a stacked one
              if (widget.isFasting)
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha(isDark ? 40 : 22),
                        blurRadius: 40,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                ),

              // Custom Painter for track and gradient progress arc
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: widget.progress),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, animatedProgress, _) {
                  return CustomPaint(
                    size: const Size(260, 260),
                    painter: _RingPainter(
                      progress: animatedProgress,
                      trackColor: isDark
                          ? AppTheme.darkCard
                          : AppTheme.lightBorder,
                      gradientColors: widget.isFasting
                          ? const [
                              AppTheme.primaryGradientStart,
                              AppTheme.primaryGradientEnd,
                            ]
                          : [
                              AppTheme.textTertiary(isDark),
                              AppTheme.textSecondary(isDark),
                            ],
                    ),
                  );
                },
              ),

              // Inner Content
              Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                  boxShadow: AppTheme.shadowMd(isDark),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.isFasting
                              ? AppTheme.primary.withAlpha(30)
                              : AppTheme.subtleSurface(isDark),
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.isFasting
                                    ? AppTheme.success
                                    : AppTheme.textSecondary(isDark),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.isFasting ? 'FASTING' : 'READY',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: widget.isFasting
                                    ? (isDark
                                        ? AppTheme.primaryGradientStart
                                        : AppTheme.primary)
                                    : AppTheme.textSecondary(isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Time Display
                      Text(
                        _formatDuration(displayedElapsed),
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Target and Percentage
                      Text(
                        widget.isFasting
                            ? '$percentage% · Target ${widget.targetHours}h'
                            : 'Plan: ${widget.targetHours}h Fast',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Remaining indicator or adjust button
                      if (widget.isFasting)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.hourglass_bottom_rounded,
                              size: 13,
                              color: AppTheme.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.remainingTime == Duration.zero
                                  ? 'Goal Completed!'
                                  : '-${_formatDuration(widget.remainingTime)} left',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: widget.remainingTime == Duration.zero
                                    ? AppTheme.success
                                    : AppTheme.warning,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final List<Color> gradientColors;

  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 18.0;

    // Background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0.001) return;

    // Progress Arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    const startAngle = -math.pi / 2;

    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: gradientColors,
        startAngle: 0,
        endAngle: 2 * math.pi,
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);

    // Glowing tip indicator dot
    final tipAngle = startAngle + sweepAngle;
    final tipX = center.dx + radius * math.cos(tipAngle);
    final tipY = center.dy + radius * math.sin(tipAngle);

    final dotGlowPaint = Paint()
      ..color = gradientColors.last.withAlpha(120)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(tipX, tipY), strokeWidth / 2 + 2, dotGlowPaint);

    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(tipX, tipY), strokeWidth / 3.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor;
  }
}

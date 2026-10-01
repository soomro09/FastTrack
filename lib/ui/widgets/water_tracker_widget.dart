import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/water_provider.dart';
import '../../core/theme/app_theme.dart';

class WaterTrackerWidget extends ConsumerStatefulWidget {
  const WaterTrackerWidget({super.key});

  @override
  ConsumerState<WaterTrackerWidget> createState() => _WaterTrackerWidgetState();
}

class _WaterTrackerWidgetState extends ConsumerState<WaterTrackerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    // Continuous wave animation loop
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _showAddCustomAmountDialog(BuildContext context) {
    final controller = TextEditingController();
    const presets = [100, 150, 250, 350, 500, 750];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              title: const Row(
                children: [
                  Icon(Icons.local_drink_rounded, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Text(
                    'Add Water',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      suffixText: 'mL',
                      floatingLabelStyle: const TextStyle(color: AppTheme.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presets.map((ml) {
                      return ActionChip(
                        label: Text('${ml}mL'),
                        backgroundColor: AppTheme.primary.withAlpha(isDark ? 35 : 20),
                        labelStyle: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          side: BorderSide.none,
                        ),
                        onPressed: () {
                          ref.read(waterProvider.notifier).addWater(ml);
                          Navigator.of(ctx).pop();
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
                  onPressed: () {
                    final val = int.tryParse(controller.text);
                    if (val != null && val > 0) {
                      ref.read(waterProvider.notifier).addWater(val);
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showGoalSettingsDialog(BuildContext context, int currentGoal) {
    final controller = TextEditingController(text: currentGoal.toString());
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          backgroundColor: isDark
              ? AppTheme.darkSurface
              : AppTheme.lightSurface,
          title: const Row(
            children: [
              Icon(Icons.local_drink_rounded, color: AppTheme.primary),
              SizedBox(width: 8),
              Text(
                'Daily Water Goal',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Target Intake (mL)',
              suffixText: 'mL',
              floatingLabelStyle: const TextStyle(color: AppTheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                borderSide: const BorderSide(color: AppTheme.primary, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
              onPressed: () {
                final val = int.tryParse(controller.text);
                if (val != null && val > 0) {
                  ref.read(waterProvider.notifier).setGoal(val);
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final waterState = ref.watch(waterProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final percentage = waterState.percentOfGoal;

    return Card(
      elevation: 0,
      color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.border(isDark)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: "Hydration Tracker" + Arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(isDark ? 35 : 20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.water_drop_rounded,
                        color: AppTheme.primary,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Hydration Tracker',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppTheme.textPrimary(isDark),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => _showGoalSettingsDialog(context, waterState.goalMl),
                  icon: const Icon(Icons.edit_outlined),
                  iconSize: 16,
                  tooltip: 'Edit daily goal',
                  color: AppTheme.primary,
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Main Body: Left metrics + Right interactive animated droplet with +/- buttons
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Column: 1250 mL, / 2500 mL, 50% completed
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${waterState.currentMl}',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                              color: AppTheme.textPrimary(isDark),
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'mL',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary(isDark),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '/ ${waterState.goalMl} mL',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary(isDark),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$percentage% completed',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: waterState.progress >= 1.0
                              ? AppTheme.success
                              : AppTheme.textTertiary(isDark),
                        ),
                      ),
                    ],
                  ),
                ),

                // Right Controls: [-] button, Animated Droplet, [+] button
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Minus Button
                    _CircularActionButton(
                      icon: Icons.remove,
                      color: AppTheme.primary,
                      isDark: isDark,
                      onPressed: waterState.currentMl > 0
                          ? () => ref
                                .read(waterProvider.notifier)
                                .removeWater(250)
                          : null,
                    ),
                    const SizedBox(width: 12),

                    // Central Animated Liquid Glass
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0.0,
                        end: waterState.progress,
                      ),
                      duration: const Duration(milliseconds: 650),
                      curve: Curves.easeOutCubic,
                      builder: (context, smoothLevel, _) {
                        return AnimatedBuilder(
                          animation: _waveController,
                          builder: (context, _) {
                            return _AnimatedGlass(
                              fillProgress: smoothLevel,
                              wavePhase: _waveController.value,
                              isDark: isDark,
                              isOverGoal: percentage >= 100,
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 12),

                    // Plus Button
                    _CircularActionButton(
                      icon: Icons.add,
                      color: AppTheme.primary,
                      isDark: isDark,
                      onPressed: () =>
                          ref.read(waterProvider.notifier).addWater(250),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // "Add Custom Amount" — lets users log something other than the
            // fixed 250mL increment (a half-empty bottle, a small cup, etc).
            Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: InkWell(
                  onTap: () => _showAddCustomAmountDialog(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_circle_outline_rounded, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Add custom amount',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular outlined button matching the user's reference image
class _CircularActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback? onPressed;

  const _CircularActionButton({
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isEnabled
                  ? color.withAlpha(isDark ? 220 : 255)
                  : AppTheme.border(isDark),
              width: 1.8,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isEnabled ? color : AppTheme.textTertiary(isDark),
          ),
        ),
      ),
    );
  }
}

/// Glass container with continuous animated sine wave liquid filling
class _AnimatedGlass extends StatelessWidget {
  final double fillProgress; // 0.0 to 1.0
  final double wavePhase; // 0.0 to 1.0 loop
  final bool isDark;
  final bool isOverGoal;

  const _AnimatedGlass({
    required this.fillProgress,
    required this.wavePhase,
    required this.isDark,
    required this.isOverGoal,
  });

  @override
  Widget build(BuildContext context) {
    const glassWidth = 62.0;
    const glassHeight = 78.0;

    return SizedBox(
      width: glassWidth,
      height: glassHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipPath(
            clipper: const _GlassClipper(),
            child: Stack(
              children: [
                // Continuous moving liquid wave inside the glass — capped at
                // fillProgress<=1.0 by the caller, a glass can't overflow.
                CustomPaint(
                  size: const Size(glassWidth, glassHeight),
                  painter: _LiquidWavePainter(
                    progress: fillProgress,
                    phase: wavePhase,
                    isDark: isDark,
                  ),
                ),

                // Diagonal highlight streak — sells the glass material
                Positioned(
                  left: glassWidth * 0.28,
                  top: glassHeight * 0.15,
                  child: Transform.rotate(
                    angle: -0.14,
                    child: Container(
                      width: glassWidth * 0.09,
                      height: glassHeight * 0.72,
                      color: Colors.white.withAlpha(isDark ? 35 : 55),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Outline + rim + goal-reached glow, drawn unclipped so the stroke
          // isn't cut in half by the ClipPath above.
          CustomPaint(
            size: const Size(glassWidth, glassHeight),
            painter: _GlassOutlinePainter(
              isDark: isDark,
              isOverGoal: isOverGoal,
            ),
          ),
        ],
      ),
    );
  }
}

/// Clips children into a tapered drinking-glass shape — wider rim, narrower
/// rounded base, matching a real glass silhouette rather than a teardrop.
class _GlassClipper extends CustomClipper<Path> {
  const _GlassClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    path.moveTo(w * 0.15, h * 0.125); // top-left rim
    path.lineTo(w * 0.85, h * 0.125); // top-right rim
    path.lineTo(w * 0.7167, h * 0.8625); // down right side
    path.cubicTo(
      w * 0.7167,
      h * 0.90625,
      w * 0.6833,
      h * 0.9375,
      w * 0.65,
      h * 0.9375,
    ); // rounded bottom-right corner
    path.lineTo(w * 0.35, h * 0.9375); // flat base
    path.cubicTo(
      w * 0.3167,
      h * 0.9375,
      w * 0.2833,
      h * 0.90625,
      w * 0.2833,
      h * 0.8625,
    ); // rounded bottom-left corner
    path.lineTo(w * 0.15, h * 0.125); // up left side back to start

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Draws the glass's outline and rim on top of the clipped fill, plus a soft
/// success-colored glow hugging the glass shape once the goal is exceeded.
class _GlassOutlinePainter extends CustomPainter {
  final bool isDark;
  final bool isOverGoal;

  _GlassOutlinePainter({required this.isDark, required this.isOverGoal});

  @override
  void paint(Canvas canvas, Size size) {
    final path = const _GlassClipper().getClip(size);
    final strokeColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    if (isOverGoal) {
      final glowPaint = Paint()
        ..color = AppTheme.success.withAlpha(140)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawPath(path, glowPaint);
    }

    final outlinePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(path, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _GlassOutlinePainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.isOverGoal != isOverGoal;
}

/// CustomPainter that renders layered animated sine waves for flowing liquid
class _LiquidWavePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final double phase; // 0.0 to 1.0
  final bool isDark;

  _LiquidWavePainter({
    required this.progress,
    required this.phase,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.001) return;

    final w = size.width;
    final h = size.height;

    // The water level line from top (h = 100% full, 0 = empty)
    final clampedProgress = progress.clamp(0.0, 1.0);
    final waterLevelY = h - (clampedProgress * h);

    // Wave parameters
    final amplitude = (progress >= 0.98 || progress <= 0.04) ? 1.5 : 4.0;
    final angularFrequency = (2 * math.pi) / w;

    // 1. Back wave (darker cyan/blue tone with phase offset)
    final backPaint = Paint()
      ..color = AppTheme.cyan.withAlpha(isDark ? 160 : 130)
      ..style = PaintingStyle.fill;

    final backPath = Path();
    backPath.moveTo(0, h);
    backPath.lineTo(0, waterLevelY);

    for (double x = 0; x <= w; x += 1.5) {
      final y =
          waterLevelY +
          amplitude *
              math.sin(
                angularFrequency * x + (phase * 2 * math.pi) + math.pi / 2,
              );
      backPath.lineTo(x, y);
    }
    backPath.lineTo(w, h);
    backPath.close();
    canvas.drawPath(backPath, backPaint);

    // 2. Front wave (vibrant blue matching the user's reference image)
    final frontPaint = Paint()
      ..shader =
          const LinearGradient(
            colors: [AppTheme.cyan, AppTheme.cyanLight],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ).createShader(
            Rect.fromLTWH(
              0,
              waterLevelY - amplitude,
              w,
              h - waterLevelY + amplitude,
            ),
          )
      ..style = PaintingStyle.fill;

    final frontPath = Path();
    frontPath.moveTo(0, h);
    frontPath.lineTo(0, waterLevelY);

    for (double x = 0; x <= w; x += 1.5) {
      final y =
          waterLevelY +
          amplitude * math.sin(angularFrequency * x + (phase * 2 * math.pi));
      frontPath.lineTo(x, y);
    }
    frontPath.lineTo(w, h);
    frontPath.close();
    canvas.drawPath(frontPath, frontPaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.phase != phase ||
        oldDelegate.isDark != isDark;
  }
}

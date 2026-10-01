import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'dart:math' as math;
import '../../models/weight_log.dart';
import '../../core/theme/app_theme.dart';

class SteppedWeightChart extends StatefulWidget {
  final List<WeightLog> logs;
  final String unitLabel;
  final VoidCallback? onViewAll;
  final VoidCallback? onAddWeight;

  const SteppedWeightChart({
    super.key,
    required this.logs,
    this.unitLabel = 'kg',
    this.onViewAll,
    this.onAddWeight,
  });

  @override
  State<SteppedWeightChart> createState() => _SteppedWeightChartState();
}

class _SteppedWeightChartState extends State<SteppedWeightChart> {
  int? _selectedPointIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: "Weight" on left, "view all" on right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Weight',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                if (widget.logs.isNotEmpty)
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    child: InkWell(
                      onTap: widget.onViewAll,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View All',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppTheme.primaryGradientStart : AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: isDark ? AppTheme.primaryGradientStart : AppTheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Content: Stepped chart or starter guidance
            if (widget.logs.length >= 2)
              _buildChartArea(isDark)
            else if (widget.logs.length == 1)
              _buildSingleLogState(isDark)
            else
              _buildEmptyState(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildChartArea(bool isDark) {
    // Show up to the last 7 logs so the chart is clean, legible, and uncrowded
    final displayLogs = widget.logs.length > 7
        ? widget.logs.sublist(widget.logs.length - 7)
        : widget.logs;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanDown: (details) => _handleTouch(details.localPosition, constraints.maxWidth, displayLogs),
          onPanUpdate: (details) => _handleTouch(details.localPosition, constraints.maxWidth, displayLogs),
          onTapUp: (details) => _handleTouch(details.localPosition, constraints.maxWidth, displayLogs),
          child: SizedBox(
            height: 200,
            width: constraints.maxWidth,
            child: CustomPaint(
              size: Size(constraints.maxWidth, 200),
              painter: _SteppedWeightChartPainter(
                logs: displayLogs,
                isDark: isDark,
                selectedIndex: _selectedPointIndex,
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTouch(Offset localPosition, double width, List<WeightLog> displayLogs) {
    const leftMargin = 38.0;
    const rightMargin = 16.0;
    final plotWidth = width - leftMargin - rightMargin;
    final count = displayLogs.length;
    if (count < 2) return;

    final stepX = plotWidth / (count - 1);
    final touchX = (localPosition.dx - leftMargin).clamp(0.0, plotWidth);
    final nearestIndex = (touchX / stepX).round().clamp(0, count - 1);

    if (_selectedPointIndex != nearestIndex) {
      setState(() {
        _selectedPointIndex = nearestIndex;
      });
    }
  }

  Widget _buildSingleLogState(bool isDark) {
    final log = widget.logs.first;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.subtleSurface(isDark),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(isDark ? 50 : 30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flag_rounded, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Starting Baseline Logged',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${log.weight.toStringAsFixed(1)} ${widget.unitLabel} recorded on ${DateFormat('MMM d').format(log.date)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Log one more weigh-in to render your stepped progress curve and track your trend!',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: widget.onAddWeight,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Log Second Weigh-in'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.subtleSurface(isDark),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        children: [
          Icon(
            Icons.monitor_weight_outlined,
            size: 40,
            color: AppTheme.textTertiary(isDark),
          ),
          const SizedBox(height: 10),
          Text(
            'No Weight Entries Yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Set your baseline weight to begin tracking your transformation and fasting benefits.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: widget.onAddWeight,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Set Starting Baseline'),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SteppedWeightChartPainter extends CustomPainter {
  final List<WeightLog> logs;
  final bool isDark;
  final int? selectedIndex;

  _SteppedWeightChartPainter({
    required this.logs,
    required this.isDark,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (logs.length < 2) return;

    const double leftMargin = 36.0;
    const double rightMargin = 16.0;
    const double topMargin = 40.0; // Space for speech bubbles
    const double bottomMargin = 28.0; // Space for DD.MM date labels

    final double plotWidth = size.width - leftMargin - rightMargin;
    final double plotHeight = size.height - topMargin - bottomMargin;

    // Find min and max weight
    double minW = logs.first.weight;
    double maxW = logs.first.weight;
    for (final l in logs) {
      if (l.weight < minW) minW = l.weight;
      if (l.weight > maxW) maxW = l.weight;
    }

    // Ensure there's a visible range
    if ((maxW - minW) < 1.0) {
      maxW += 1.0;
      minW -= 1.0;
    }

    // Pick a "nice" grid step (0.5, 1, 2, 5, 10...kg) so the axis always
    // shows a handful of readable ticks — a fixed 0.5 step used to cram
    // dozens of overlapping labels into the chart for wide weight ranges.
    final double rawRange = math.max(0.5, maxW - minW);
    const candidateSteps = [0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 25.0, 50.0];
    double step = candidateSteps.last;
    for (final s in candidateSteps) {
      if (rawRange / s <= 4) {
        step = s;
        break;
      }
    }

    final double gridMin = (minW / step).floor() * step;
    final double gridMax = (maxW / step).ceil() * step;
    final double range = math.max(step, gridMax - gridMin);

    final List<double> ticks = [];
    for (double v = gridMin; v <= gridMax + step * 0.01; v += step) {
      ticks.add(double.parse(v.toStringAsFixed(1)));
    }

    // Helper functions for mapping coordinates
    double getY(double weight) {
      final norm = (weight - gridMin) / range;
      return topMargin + (plotHeight * (1.0 - norm));
    }

    double getX(int index) {
      return leftMargin + (plotWidth * index / (logs.length - 1));
    }

    // Draw horizontal dashed grid lines and Y-axis tick labels
    final dashPaint = Paint()
      ..color = AppTheme.border(isDark)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final tickTextPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );

    for (final tick in ticks) {
      final y = getY(tick);

      // Draw dashed line
      _drawDashedLine(canvas, Offset(leftMargin, y), Offset(size.width - rightMargin, y), dashPaint);

      // Format label: if whole number, e.g. "72"; if .5, e.g. ".5"
      final isWhole = (tick % 1.0 == 0);
      final labelText = isWhole ? tick.toInt().toString() : '.5';

      tickTextPainter.text = TextSpan(
        text: labelText,
        style: TextStyle(
          fontSize: isWhole ? 11 : 10,
          fontWeight: isWhole ? FontWeight.w600 : FontWeight.w500,
          color: isWhole ? AppTheme.textSecondary(isDark) : AppTheme.textTertiary(isDark),
        ),
      );
      tickTextPainter.layout();
      tickTextPainter.paint(
        canvas,
        Offset(leftMargin - tickTextPainter.width - 8, y - (tickTextPainter.height / 2)),
      );
    }

    // Prepare point coordinates
    final points = <Offset>[];
    for (int i = 0; i < logs.length; i++) {
      points.add(Offset(getX(i), getY(logs[i].weight)));
    }

    // Construct the stepped curve with smooth fillet transitions
    // Using cubic beziers: horizontal near the source point, curving smoothly to horizontal at next point
    final linePath = Path()..moveTo(points[0].dx, points[0].dy);
    final fillPath = Path()..moveTo(points[0].dx, size.height - bottomMargin);
    fillPath.lineTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final dx = p2.dx - p1.dx;

      // Gentle horizontal hold then smooth transition:
      // Control point 1 stays at y1, control point 2 aligns with y2
      final cp1 = Offset(p1.dx + dx * 0.55, p1.dy);
      final cp2 = Offset(p1.dx + dx * 0.45, p2.dy);

      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
      fillPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }

    // Complete fill path down to baseline
    fillPath.lineTo(points.last.dx, size.height - bottomMargin);
    fillPath.close();

    // Fill gradient: a single success green fading to transparent
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.success.withAlpha(isDark ? 90 : 80),
          AppTheme.success.withAlpha(isDark ? 30 : 25),
          AppTheme.success.withAlpha(0),
        ],
      ).createShader(Rect.fromLTWH(leftMargin, topMargin, plotWidth, plotHeight))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Stroke line
    final linePaint = Paint()
      ..color = AppTheme.success
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(linePath, linePaint);

    // Draw bottom X-axis labels (DD.MM)
    final datePainter = TextPainter(textDirection: TextDirection.ltr, textAlign: TextAlign.center);
    for (int i = 0; i < logs.length; i++) {
      final dateStr = DateFormat('dd.MM').format(logs[i].date);
      datePainter.text = TextSpan(
        text: dateStr,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: (selectedIndex == i)
              ? AppTheme.textPrimary(isDark)
              : AppTheme.textSecondary(isDark),
        ),
      );
      datePainter.layout();
      datePainter.paint(
        canvas,
        Offset(points[i].dx - (datePainter.width / 2), size.height - bottomMargin + 8),
      );
    }

    // Draw Data Point Dots & Floating Speech Bubbles — the bubble reads as a
    // dark tooltip in both themes, so it uses one fixed dark surface rather
    // than a theme-swapped pair.
    const bubbleBg = AppTheme.darkSurface;

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final isSelected = (selectedIndex == i);

      // Point dot
      final dotBgPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final dotStrokePaint = Paint()
        ..color = AppTheme.success
        ..strokeWidth = isSelected ? 3.5 : 2.5
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(p, isSelected ? 5.5 : 4.0, dotBgPaint);
      canvas.drawCircle(p, isSelected ? 5.5 : 4.0, dotStrokePaint);

      // Determine if speech bubble should be shown for this point:
      // Show for all points if count <= 4, or for the selected point, or for first & last points
      final shouldShowBubble = (logs.length <= 4) || isSelected || (selectedIndex == null && (i == 0 || i == logs.length - 1));

      if (shouldShowBubble) {
        _drawSpeechBubble(
          canvas: canvas,
          targetPoint: p,
          text: logs[i].weight.toStringAsFixed(1),
          bubbleColor: bubbleBg,
          isHighlight: isSelected,
        );
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 4.0;
    const double dashSpace = 4.0;
    double startX = p1.dx;
    final double y = p1.dy;

    while (startX < p2.dx) {
      final double endX = math.min(startX + dashWidth, p2.dx);
      canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
      startX += dashWidth + dashSpace;
    }
  }

  void _drawSpeechBubble({
    required Canvas canvas,
    required Offset targetPoint,
    required String text,
    required Color bubbleColor,
    required bool isHighlight,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final bubbleWidth = textPainter.width + 16.0;
    const bubbleHeight = 22.0;
    const pointerHeight = 5.0;
    const pointerWidth = 8.0;

    final bubbleCenter = Offset(targetPoint.dx, targetPoint.dy - pointerHeight - (bubbleHeight / 2) - 4);
    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: bubbleCenter,
        width: bubbleWidth,
        height: bubbleHeight,
      ),
      const Radius.circular(8),
    );

    final bubblePath = Path()
      ..addRRect(bubbleRect)
      ..moveTo(targetPoint.dx - (pointerWidth / 2), bubbleCenter.dy + (bubbleHeight / 2))
      ..lineTo(targetPoint.dx, targetPoint.dy - 3)
      ..lineTo(targetPoint.dx + (pointerWidth / 2), bubbleCenter.dy + (bubbleHeight / 2))
      ..close();

    // Shadow
    canvas.drawShadow(bubblePath, Colors.black.withAlpha(80), isHighlight ? 5.0 : 3.0, false);

    // Background
    final paint = Paint()
      ..color = bubbleColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(bubblePath, paint);

    // Text inside bubble
    textPainter.paint(
      canvas,
      Offset(
        bubbleCenter.dx - (textPainter.width / 2),
        bubbleCenter.dy - (textPainter.height / 2),
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _SteppedWeightChartPainter oldDelegate) {
    return oldDelegate.logs != logs ||
        oldDelegate.isDark != isDark ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

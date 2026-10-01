import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/fasting_provider.dart';
import '../../core/database/db_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../models/fasting_log.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/ticking_clock_icon.dart';

enum _HistoryPeriod { week, month }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  static const _sessionsPreviewCount = 5;

  _HistoryPeriod _period = _HistoryPeriod.week;

  // 0 = current period, negative = periods back in time. Never positive —
  // you can't page into the future.
  int _offset = 0;

  void _setPeriod(_HistoryPeriod period) {
    if (period == _period) return;
    setState(() {
      _period = period;
      _offset = 0;
    });
  }

  void _stepOffset(int delta) {
    final next = _offset + delta;
    if (next > 0) return;
    setState(() => _offset = next);
  }

  DateTime _weekMonday(int offset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisMonday = today.subtract(Duration(days: today.weekday - 1));
    return thisMonday.add(Duration(days: 7 * offset));
  }

  DateTime _monthAnchor(int offset) {
    final now = DateTime.now();
    return DateTime(now.year, now.month + offset, 1);
  }

  String _periodLabel() {
    if (_period == _HistoryPeriod.week) {
      if (_offset == 0) return 'This Week';
      if (_offset == -1) return 'Last Week';
      final monday = _weekMonday(_offset);
      final sunday = monday.add(const Duration(days: 6));
      final sameYear = monday.year == sunday.year;
      final start = DateFormat('MMM d').format(monday);
      final end = DateFormat(sameYear ? 'MMM d' : 'MMM d, yyyy').format(sunday);
      return '$start – $end';
    } else {
      if (_offset == 0) return 'This Month';
      if (_offset == -1) return 'Last Month';
      return DateFormat('MMMM yyyy').format(_monthAnchor(_offset));
    }
  }

  void _showAllSessionsSheet(BuildContext context, WidgetRef ref, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusXl),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkBorder
                          : AppTheme.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      'All Sessions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, _) {
                        final historyAsync = ref.watch(fastingHistoryProvider);
                        return historyAsync.when(
                          data: (logs) {
                            if (logs.isEmpty) {
                              Navigator.of(ctx).pop();
                              return const SizedBox.shrink();
                            }
                            return ListView.builder(
                              padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                              itemCount: logs.length,
                              itemBuilder: (context, index) =>
                                  _buildSessionCard(
                                    context,
                                    ref,
                                    logs[index],
                                    isDark,
                                  ),
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (_, _) => const SizedBox.shrink(),
                        );
                      },
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

  Future<void> _deleteLog(
    BuildContext context,
    WidgetRef ref,
    FastingLog log,
  ) async {
    if (log.id == null) return;
    await DatabaseHelper.instance.deleteFastingLog(log.id!);
    ref.invalidate(fastingHistoryProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Fast entry deleted'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await DatabaseHelper.instance.insertFastingLog(
                FastingLog(
                  startTime: log.startTime,
                  endTime: log.endTime,
                  targetDurationHours: log.targetDurationHours,
                  isCompleted: log.isCompleted,
                ),
              );
              ref.invalidate(fastingHistoryProvider);
            },
          ),
        ),
      );
    }
  }

  String _getProtocolLabel(int targetHours) {
    if (targetHours == 14) return '14:10';
    if (targetHours == 16) return '16:8';
    if (targetHours == 18) return '18:6';
    if (targetHours == 20) return '20:4';
    if (targetHours >= 23) return 'OMAD';
    if (targetHours > 0 && targetHours < 24) {
      return '$targetHours:${24 - targetHours}';
    }
    return '${targetHours}h';
  }

  _WeeklyConsistencySummary _calculateWeeklyConsistency(
    List<FastingLog> logs,
    DateTime monday,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final days = <_DailyConsistencyData>[];
    double currentWeekTotal = 0.0;

    for (int i = 0; i < 7; i++) {
      final dayDate = monday.add(Duration(days: i));
      double dayHours = 0.0;

      for (final log in logs) {
        final logEndDay = DateTime(
          log.endTime.year,
          log.endTime.month,
          log.endTime.day,
        );
        if (logEndDay.year == dayDate.year &&
            logEndDay.month == dayDate.month &&
            logEndDay.day == dayDate.day) {
          dayHours += log.endTime.difference(log.startTime).inMinutes / 60.0;
        }
      }

      currentWeekTotal += dayHours;
      days.add(
        _DailyConsistencyData(
          label: dayLabels[i],
          date: dayDate,
          hours: dayHours,
          isToday: dayDate.isAtSameMomentAs(today),
        ),
      );
    }

    // Previous week calculation: from 7 days before Monday up to Monday
    final prevMonday = monday.subtract(const Duration(days: 7));
    double prevWeekTotal = 0.0;
    for (final log in logs) {
      if (log.endTime.isAfter(
            prevMonday.subtract(const Duration(seconds: 1)),
          ) &&
          log.endTime.isBefore(monday)) {
        prevWeekTotal += log.endTime.difference(log.startTime).inMinutes / 60.0;
      }
    }

    final diff = currentWeekTotal - prevWeekTotal;

    return _WeeklyConsistencySummary(
      totalHours: currentWeekTotal,
      diffVsLastWeek: diff,
      days: days,
    );
  }

  double _hoursOnDay(List<FastingLog> logs, DateTime day) {
    double total = 0.0;
    for (final log in logs) {
      final logEndDay = DateTime(
        log.endTime.year,
        log.endTime.month,
        log.endTime.day,
      );
      if (logEndDay.year == day.year &&
          logEndDay.month == day.month &&
          logEndDay.day == day.day) {
        total += log.endTime.difference(log.startTime).inMinutes / 60.0;
      }
    }
    return total;
  }

  _MonthlyConsistencySummary _calculateMonthlyConsistency(
    List<FastingLog> logs,
    DateTime monthAnchor,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysInMonth = DateUtils.getDaysInMonth(
      monthAnchor.year,
      monthAnchor.month,
    );

    final days = <_DailyConsistencyData>[];
    double monthTotal = 0.0;

    for (int i = 0; i < daysInMonth; i++) {
      final dayDate = DateTime(monthAnchor.year, monthAnchor.month, i + 1);
      final dayHours = _hoursOnDay(logs, dayDate);
      monthTotal += dayHours;
      days.add(
        _DailyConsistencyData(
          label: '${i + 1}',
          date: dayDate,
          hours: dayHours,
          isToday: dayDate.isAtSameMomentAs(today),
        ),
      );
    }

    final prevMonthAnchor = DateTime(
      monthAnchor.year,
      monthAnchor.month - 1,
      1,
    );
    double prevMonthTotal = 0.0;
    for (final log in logs) {
      if (!log.endTime.isBefore(prevMonthAnchor) &&
          log.endTime.isBefore(monthAnchor)) {
        prevMonthTotal +=
            log.endTime.difference(log.startTime).inMinutes / 60.0;
      }
    }

    return _MonthlyConsistencySummary(
      monthAnchor: monthAnchor,
      totalHours: monthTotal,
      diffVsLastMonth: monthTotal - prevMonthTotal,
      days: days,
      leadingBlanks: monthAnchor.weekday - 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(fastingHistoryProvider);
    final stats = ref.watch(fastingStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: historyAsync.when(
          data: (logs) {
            final weeklySummary = _period == _HistoryPeriod.week
                ? _calculateWeeklyConsistency(logs, _weekMonday(_offset))
                : null;
            final monthlySummary = _period == _HistoryPeriod.month
                ? _calculateMonthlyConsistency(logs, _monthAnchor(_offset))
                : null;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Screen Title
                        FadeSlideIn(
                          child: Text(
                            'History',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.lightTextPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Week / Month toggle
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 30),
                          child: SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<_HistoryPeriod>(
                              showSelectedIcon: false,
                              style: AppTheme.primarySegmentedButtonStyle(isDark),
                              segments: const [
                                ButtonSegment(
                                  value: _HistoryPeriod.week,
                                  label: Text('Week'),
                                ),
                                ButtonSegment(
                                  value: _HistoryPeriod.month,
                                  label: Text('Month'),
                                ),
                              ],
                              selected: {_period},
                              onSelectionChanged: (selection) =>
                                  _setPeriod(selection.first),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Prev / next period navigation
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 45),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => _stepOffset(-1),
                                icon: const Icon(Icons.chevron_left_rounded),
                                color: AppTheme.textSecondary(isDark),
                                constraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 44,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _periodLabel(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary(isDark),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _offset < 0
                                    ? () => _stepOffset(1)
                                    : null,
                                icon: const Icon(Icons.chevron_right_rounded),
                                color: AppTheme.textSecondary(isDark),
                                constraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 44,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Weekly or Monthly Consistency Card
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 60),
                          child: weeklySummary != null
                              ? _buildWeeklyConsistencyCard(
                                  weeklySummary,
                                  isDark,
                                )
                              : _buildMonthlyConsistencyCard(
                                  monthlySummary!,
                                  isDark,
                                  context,
                                  logs,
                                ),
                        ),
                        const SizedBox(height: 14),

                        // 4. 2x2 Stats Grid with indicator dots (from user screenshot 1)
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 90),
                          child: _buildStatsGrid(stats, isDark),
                        ),
                        const SizedBox(height: 26),

                        // 5. Sessions Header (from user screenshot 1)
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 120),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Sessions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.lightTextPrimary,
                                ),
                              ),
                              Text(
                                '${logs.length} total',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),

                // Sessions Content — capped preview, same idea as Profile's
                // Recent Entries: show a handful inline, push the rest behind
                // "View All" instead of letting the page grow indefinitely.
                if (logs.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
                    sliver: SliverToBoxAdapter(child: _buildEmptyState(isDark)),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == _sessionsPreviewCount) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Center(
                                child: TextButton(
                                  onPressed: () => _showAllSessionsSheet(
                                    context,
                                    ref,
                                    isDark,
                                  ),
                                  child: Text(
                                    'View all ${logs.length} sessions',
                                  ),
                                ),
                              ),
                            );
                          }
                          final log = logs[index];
                          return FadeSlideIn(
                            delay: Duration(
                              milliseconds: 20 * math.min(index, 6),
                            ),
                            child: _buildSessionCard(context, ref, log, isDark),
                          );
                        },
                        childCount: logs.length > _sessionsPreviewCount
                            ? _sessionsPreviewCount + 1
                            : logs.length,
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) =>
              Center(child: Text('Error loading history: $err')),
        ),
      ),
    );
  }

  // WEEKLY CONSISTENCY CARD (Matching user screenshot 1)
  Widget _buildWeeklyConsistencyCard(
    _WeeklyConsistencySummary summary,
    bool isDark,
  ) {
    final diff = summary.diffVsLastWeek;
    final isPositiveDiff = diff >= 0;
    final diffText =
        '${isPositiveDiff ? "+" : ""}${diff.toStringAsFixed(1)}h vs last week';

    // Calculate max hours across the week to scale bar heights
    double maxHours = 0.0;
    for (final day in summary.days) {
      if (day.hours > maxHours) maxHours = day.hours;
    }
    final scaleBase = math.max(
      maxHours,
      16.0,
    ); // 16h as natural baseline ceiling

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: "WEEKLY CONSISTENCY"
            Text(
              'WEEKLY CONSISTENCY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),

            // Row: "96.4h" on left, "+8.2h vs last week" on right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${summary.totalHours.toStringAsFixed(1)}h',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
                Text(
                  diffText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isPositiveDiff ? AppTheme.success : AppTheme.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 7 Vertical Bars (M, T, W, T, F, S, S)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: summary.days.asMap().entries.map((dayEntry) {
                final dayIndex = dayEntry.key;
                final day = dayEntry.value;
                const double maxBarHeight = 62.0;
                const double minBarHeight = 10.0;

                final normalizedHeight = day.hours <= 0
                    ? minBarHeight
                    : math.max(
                        minBarHeight,
                        (day.hours / scaleBase) * maxBarHeight,
                      );

                // Standout/goal-met days pop with the copper accent, other
                // active days use the calmer primary teal, zero-hour days
                // stay a muted neutral placeholder.
                final isHighlight =
                    day.hours >= 14.0 ||
                    (day.hours > 0 && day.hours == maxHours);
                final hasHours = day.hours > 0;

                Gradient? barGradient;
                Color? barSolidColor;

                if (isHighlight) {
                  barGradient = const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppTheme.accentLight, AppTheme.accent],
                  );
                } else if (hasHours) {
                  barGradient = const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppTheme.primaryGradientStart, AppTheme.primary],
                  );
                } else {
                  barSolidColor = isDark
                      ? AppTheme.darkCard
                      : AppTheme.lightBorder;
                }

                return Tooltip(
                  message:
                      '${day.label}: ${day.hours.toStringAsFixed(1)}h fasted',
                  child: Column(
                    children: [
                      // Rounded bar — grows in from 0, staggered per day
                      _GrowInBar(
                        width: 32,
                        height: normalizedHeight,
                        delay: Duration(milliseconds: 70 * dayIndex),
                        borderRadius: BorderRadius.circular(10),
                        gradient: barGradient,
                        color: barSolidColor,
                        boxShadow: hasHours
                            ? [
                                BoxShadow(
                                  color:
                                      (isHighlight
                                              ? AppTheme.accent
                                              : AppTheme.primary)
                                          .withAlpha(isDark ? 50 : 30),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      const SizedBox(height: 10),
                      // Day label (M, T, W, T, F, S, S)
                      Text(
                        day.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: day.isToday
                              ? (isDark ? Colors.white : Colors.black)
                              : (isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // MONTHLY CONSISTENCY CARD — calendar-style daily heatmap
  Widget _buildMonthlyConsistencyCard(
    _MonthlyConsistencySummary summary,
    bool isDark,
    BuildContext context,
    List<FastingLog> logs,
  ) {
    final diff = summary.diffVsLastMonth;
    final isPositiveDiff = diff >= 0;
    final diffText =
        '${isPositiveDiff ? "+" : ""}${diff.toStringAsFixed(1)}h vs last month';
    const weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MONTHLY CONSISTENCY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppTheme.textSecondary(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${summary.totalHours.toStringAsFixed(1)}h',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    color: AppTheme.textPrimary(isDark),
                  ),
                ),
                Text(
                  diffText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isPositiveDiff ? AppTheme.success : AppTheme.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Weekday header row
            Row(
              children: weekdayLabels
                  .map(
                    (l) => Expanded(
                      child: Center(
                        child: Text(
                          l,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary(isDark),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),

            // Calendar grid heatmap
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              children: [
                for (int i = 0; i < summary.leadingBlanks; i++)
                  const SizedBox.shrink(),
                for (final day in summary.days)
                  _buildMonthDayCell(day, isDark, context, logs),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthDayCell(
    _DailyConsistencyData day,
    bool isDark,
    BuildContext context,
    List<FastingLog> logs,
  ) {
    final hasHours = day.hours > 0;
    final isHighlight = day.hours >= 14.0;

    Color cellColor;
    Color textColor;
    if (isHighlight) {
      // Goal met (>=14h) — same "complete" green used by the session badges.
      cellColor = AppTheme.success.withAlpha(isDark ? 90 : 60);
      textColor = isDark ? Colors.white : AppTheme.success;
    } else if (hasHours) {
      // Fasted but under goal — same "ended early" amber used elsewhere.
      final intensity = (day.hours / 14).clamp(0.25, 1.0);
      cellColor = AppTheme.warning.withAlpha((intensity * 110).round());
      textColor = AppTheme.textPrimary(isDark);
    } else {
      cellColor = AppTheme.subtleSurface(isDark);
      textColor = AppTheme.textTertiary(isDark);
    }

    return Tooltip(
      message:
          '${DateFormat('MMM d').format(day.date)}: '
          '${day.hours.toStringAsFixed(1)}h fasted',
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showDaySessionsSheet(context, day.date, logs, isDark),
        child: Container(
          decoration: BoxDecoration(
            color: cellColor,
            borderRadius: BorderRadius.circular(8),
            border: day.isToday
                ? Border.all(color: AppTheme.primary, width: 1.6)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            day.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: day.isToday ? FontWeight.w800 : FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  void _showDaySessionsSheet(
    BuildContext context,
    DateTime day,
    List<FastingLog> logs,
    bool isDark,
  ) {
    final dayLogs = logs.where((log) {
      final endDay = DateTime(
        log.endTime.year,
        log.endTime.month,
        log.endTime.day,
      );
      return endDay.isAtSameMomentAs(day);
    }).toList();
    final totalHours = dayLogs.fold<double>(
      0.0,
      (sum, log) =>
          sum + log.endTime.difference(log.startTime).inMinutes / 60.0,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.7,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusXl),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkBorder
                          : AppTheme.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('EEEE, MMM d').format(day),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary(isDark),
                          ),
                        ),
                        Text(
                          '${totalHours.toStringAsFixed(1)}h fasted',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: dayLogs.isEmpty
                        ? Center(
                            child: Text(
                              'No fasting sessions ended on this day',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary(isDark),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                            itemCount: dayLogs.length,
                            itemBuilder: (context, index) => _buildSessionCard(
                              context,
                              ref,
                              dayLogs[index],
                              isDark,
                            ),
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

  // 2x2 STATS GRID WITH COLORED INDICATOR DOTS (Matching user screenshot 1)
  Widget _buildStatsGrid(FastingStats stats, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            // Card 1: Total fasts (Moss green dot)
            Expanded(
              child: _MetricCard(
                title: 'Total fasts',
                value: '${stats.totalFasts}',
                subtitle: '${stats.completedFasts} completed',
                dotColor: AppTheme.success,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            // Card 2: Total hours (Teal dot)
            Expanded(
              child: _MetricCard(
                title: 'Total hours',
                value: '${stats.totalHours.round()}h',
                subtitle: 'Fasted time',
                dotColor: AppTheme.primary,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Card 3: Longest fast (Gold dot)
            Expanded(
              child: _MetricCard(
                title: 'Longest fast',
                value: '${stats.longestFastHours.toStringAsFixed(1)}h',
                subtitle: 'Personal record',
                dotColor: AppTheme.gold,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            // Card 4: Current streak (Orange dot)
            Expanded(
              child: _MetricCard(
                title: 'Current streak',
                value: '${stats.currentStreak}d',
                subtitle: 'Keep it going',
                dotColor: AppTheme.tangerine,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // SESSIONS CARD (Matching user screenshot 1 with left accent bar and COMPLETE badge)
  Widget _buildSessionCard(
    BuildContext context,
    WidgetRef ref,
    FastingLog log,
    bool isDark,
  ) {
    final duration = log.endTime.difference(log.startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final isCompleted = log.isCompleted;

    final protocol = _getProtocolLabel(log.targetDurationHours);
    final startFormatted = DateFormat('EEE, MMM d · h:mm a')
        .format(log.startTime);
    final endFormatted = DateFormat('h:mm a').format(log.endTime);

    return Dismissible(
      key: ValueKey(log.id ?? log.startTime.toIso8601String()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.danger,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => _deleteLog(context, ref, log),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Accent Vertical Bar (|)
              Container(
                width: 3.5,
                height: 38,
                decoration: BoxDecoration(
                  color: isCompleted ? AppTheme.success : AppTheme.warning,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: "16h 04m"  [COMPLETE]           16:8
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${hours}h  ${minutes.toString().padLeft(2, '0')}m',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Pill Badge: COMPLETE or ENDED EARLY
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppTheme.successBadgeBg(isDark)
                                : AppTheme.warningBadgeBg(isDark),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isCompleted ? 'COMPLETE' : 'ENDED EARLY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: isCompleted
                                  ? AppTheme.successBadgeText(isDark)
                                  : AppTheme.warningBadgeText(isDark),
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Protocol tag: e.g. 16:8
                        Text(
                          protocol,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textTertiary(isDark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Row 2: Date & time range: "Mon, Sep 7 · 8:12 PM → 12:16 PM"
                    Text(
                      '$startFormatted → $endFormatted',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          const TickingClockIcon(size: 90),
          const SizedBox(height: 18),
          Text(
            'No Fasts Recorded Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start your first fast on the Timer tab. Once completed, your sessions and weekly consistency will appear here automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// A bar that grows from 0 up to [height] after [delay] — used to stagger
/// the weekly consistency chart in on load instead of popping in at once.
class _GrowInBar extends StatefulWidget {
  final double width;
  final double height;
  final Duration delay;
  final BorderRadius borderRadius;
  final Gradient? gradient;
  final Color? color;
  final List<BoxShadow>? boxShadow;

  const _GrowInBar({
    required this.width,
    required this.height,
    required this.delay,
    required this.borderRadius,
    this.gradient,
    this.color,
    this.boxShadow,
  });

  @override
  State<_GrowInBar> createState() => _GrowInBarState();
}

class _GrowInBarState extends State<_GrowInBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _grow = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _delayTimer = Timer(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _grow,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height * _grow.value,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          gradient: widget.gradient,
          color: widget.color,
          boxShadow: widget.boxShadow,
        ),
      ),
    );
  }
}

// 2x2 Metric Card Component with Top-Right Indicator Dot
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color dotColor;
  final bool isDark;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.dotColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Indicator Dot
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withAlpha(100),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Large Value
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 2),

            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper models for weekly consistency
class _DailyConsistencyData {
  final String label;
  final DateTime date;
  final double hours;
  final bool isToday;

  const _DailyConsistencyData({
    required this.label,
    required this.date,
    required this.hours,
    required this.isToday,
  });
}

class _WeeklyConsistencySummary {
  final double totalHours;
  final double diffVsLastWeek;
  final List<_DailyConsistencyData> days;

  const _WeeklyConsistencySummary({
    required this.totalHours,
    required this.diffVsLastWeek,
    required this.days,
  });
}

class _MonthlyConsistencySummary {
  final DateTime monthAnchor;
  final double totalHours;
  final double diffVsLastMonth;
  final List<_DailyConsistencyData> days;
  final int leadingBlanks;

  const _MonthlyConsistencySummary({
    required this.monthAnchor,
    required this.totalHours,
    required this.diffVsLastMonth,
    required this.days,
    required this.leadingBlanks,
  });
}

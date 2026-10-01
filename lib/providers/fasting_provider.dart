import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/fasting_log.dart';
import '../core/database/db_helper.dart';
import '../core/theme/app_theme.dart';
import '../core/notifications/notification_service.dart';
import 'notification_settings_provider.dart';

// Metabolic stage model
class MetabolicStage {
  final String title;
  final String subtitle;
  final String description;
  final double startHour;
  final double endHour;
  final Color color;
  final IconData icon;

  const MetabolicStage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.startHour,
    required this.endHour,
    required this.color,
    required this.icon,
  });

  static const List<MetabolicStage> stages = [
    MetabolicStage(
      title: 'Digestion & Blood Sugar',
      subtitle: '0 - 4 hours',
      description: 'Your body is digesting food. Blood glucose and insulin levels rise, providing quick energy.',
      startHour: 0,
      endHour: 4,
      color: AppTheme.cyan,
      icon: Icons.restaurant,
    ),
    MetabolicStage(
      title: 'Blood Sugar Stabilizing',
      subtitle: '4 - 8 hours',
      description: 'Blood sugar normalizes and insulin drops. Your stomach is resting and energy transitions from food to stored glycogen.',
      startHour: 4,
      endHour: 8,
      color: Color(0xFF14B8A6),
      icon: Icons.electric_bolt,
    ),
    MetabolicStage(
      title: 'Fat Burning Starts',
      subtitle: '8 - 12 hours',
      description: 'Glycogen reserves deplete. Your liver signals your body to begin burning stored body fat for energy.',
      startHour: 8,
      endHour: 12,
      color: Color(0xFF65A30D),
      icon: Icons.local_fire_department,
    ),
    MetabolicStage(
      title: 'Ketosis Acceleration',
      subtitle: '12 - 16 hours',
      description: 'Fat breakdown produces ketones. Mental clarity often sharpens and metabolism shifts fully to burning fat.',
      startHour: 12,
      endHour: 16,
      color: Color(0xFFD97706),
      icon: Icons.psychology,
    ),
    MetabolicStage(
      title: 'Autophagy & Cellular Repair',
      subtitle: '16 - 24 hours',
      description: 'Cellular cleanup (autophagy) kicks into high gear. Cells eliminate damaged components and renew themselves.',
      startHour: 16,
      endHour: 24,
      color: Color(0xFF7C3AED),
      icon: Icons.auto_awesome,
    ),
    MetabolicStage(
      title: 'Deep Rejuvenation',
      subtitle: '24+ hours',
      description: 'Growth hormone increases, systemic inflammation plunges, and immune cell regeneration is triggered.',
      startHour: 24,
      endHour: 999,
      color: Color(0xFFC2703D),
      icon: Icons.favorite,
    ),
  ];

  static MetabolicStage currentStage(double elapsedHours) {
    for (final s in stages) {
      if (elapsedHours >= s.startHour && elapsedHours < s.endHour) {
        return s;
      }
    }
    return stages.last;
  }
}

// Represents the state of the fasting timer
class FastingState {
  final bool isFasting;
  final DateTime? startTime;
  final int targetHours;
  final Duration elapsedTime;

  FastingState({
    required this.isFasting,
    this.startTime,
    required this.targetHours,
    required this.elapsedTime,
  });

  DateTime? get targetEndTime {
    if (startTime == null) return null;
    return startTime!.add(Duration(hours: targetHours));
  }

  double get progress {
    if (!isFasting || targetHours <= 0) return 0.0;
    final targetSecs = targetHours * 3600;
    if (targetSecs == 0) return 0.0;
    return (elapsedTime.inSeconds / targetSecs).clamp(0.0, 1.0);
  }

  Duration get remainingTime {
    if (!isFasting) return Duration.zero;
    final total = Duration(hours: targetHours);
    final remaining = total - elapsedTime;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isGoalReached => elapsedTime.inHours >= targetHours;

  MetabolicStage get currentMetabolicStage =>
      MetabolicStage.currentStage(elapsedTime.inMinutes / 60.0);

  FastingState copyWith({
    bool? isFasting,
    DateTime? startTime,
    int? targetHours,
    Duration? elapsedTime,
  }) {
    return FastingState(
      isFasting: isFasting ?? this.isFasting,
      startTime: startTime ?? this.startTime,
      targetHours: targetHours ?? this.targetHours,
      elapsedTime: elapsedTime ?? this.elapsedTime,
    );
  }
}

class FastingNotifier extends Notifier<FastingState> {
  Timer? _timer;

  @override
  FastingState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    Future.microtask(() => _loadState());
    return FastingState(
      isFasting: false,
      targetHours: 16,
      elapsedTime: Duration.zero,
    );
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final isFasting = prefs.getBool('isFasting') ?? false;
    final targetHours = prefs.getInt('targetHours') ?? 16;

    if (isFasting) {
      final startTimeStr = prefs.getString('startTime');
      if (startTimeStr != null) {
        final startTime = DateTime.parse(startTimeStr);
        state = state.copyWith(
          isFasting: true,
          startTime: startTime,
          targetHours: targetHours,
          elapsedTime: DateTime.now().difference(startTime),
        );
        _startTimer();
      }
    } else {
      state = state.copyWith(targetHours: targetHours);
    }
  }

  Future<void> startFast([DateTime? customStartTime]) async {
    final start = customStartTime ?? DateTime.now();
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isFasting', true);
    await prefs.setString('startTime', start.toIso8601String());

    state = state.copyWith(
      isFasting: true,
      startTime: start,
      elapsedTime: DateTime.now().difference(start),
    );
    _startTimer();
    await _rescheduleAlerts(start, state.targetHours);
  }

  Future<void> updateStartTime(DateTime newStart) async {
    if (!state.isFasting) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('startTime', newStart.toIso8601String());

    state = state.copyWith(
      startTime: newStart,
      elapsedTime: DateTime.now().difference(newStart),
    );
    await _rescheduleAlerts(newStart, state.targetHours);
  }

  Future<void> _rescheduleAlerts(DateTime start, int targetHours) async {
    final settings = ref.read(notificationSettingsProvider);
    await NotificationService.instance.cancelFastingAlerts();
    await NotificationService.instance.scheduleFastingAlerts(
      startTime: start,
      targetHours: targetHours,
      stageMilestones: settings.stageMilestones,
      startEndAlerts: settings.fastStartEndAlerts,
    );
  }

  Future<FastingLog?> endFast() async {
    _timer?.cancel();
    await NotificationService.instance.cancelFastingAlerts();
    FastingLog? savedLog;

    if (state.startTime != null) {
      final now = DateTime.now();
      final duration = now.difference(state.startTime!);

      savedLog = FastingLog(
        startTime: state.startTime!,
        endTime: now,
        targetDurationHours: state.targetHours,
        isCompleted: duration.inHours >= state.targetHours,
      );
      await DatabaseHelper.instance.insertFastingLog(savedLog);
      ref.invalidate(fastingHistoryProvider);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFasting', false);
    await prefs.remove('startTime');

    state = state.copyWith(
      isFasting: false,
      startTime: null,
      elapsedTime: Duration.zero,
    );

    return savedLog;
  }

  Future<void> updateTargetHours(int hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('targetHours', hours);
    state = state.copyWith(targetHours: hours);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.startTime != null) {
        state = state.copyWith(
          elapsedTime: DateTime.now().difference(state.startTime!),
        );
      }
    });
  }
}

final fastingProvider = NotifierProvider<FastingNotifier, FastingState>(() {
  return FastingNotifier();
});

// A provider to fetch fasting history
final fastingHistoryProvider = FutureProvider<List<FastingLog>>((ref) async {
  return await DatabaseHelper.instance.getFastingLogs();
});

// Computed fasting statistics provider
class FastingStats {
  final int totalFasts;
  final int completedFasts;
  final double totalHours;
  final double longestFastHours;
  final int currentStreak;

  const FastingStats({
    required this.totalFasts,
    required this.completedFasts,
    required this.totalHours,
    required this.longestFastHours,
    required this.currentStreak,
  });
}

final fastingStatsProvider = Provider<FastingStats>((ref) {
  final historyAsync = ref.watch(fastingHistoryProvider);
  final logs = historyAsync.value ?? [];

  if (logs.isEmpty) {
    return const FastingStats(
      totalFasts: 0,
      completedFasts: 0,
      totalHours: 0,
      longestFastHours: 0,
      currentStreak: 0,
    );
  }

  int completed = 0;
  double totalH = 0;
  double longest = 0;

  for (final log in logs) {
    final durationHours =
        log.endTime.difference(log.startTime).inMinutes / 60.0;
    totalH += durationHours;
    if (durationHours > longest) longest = durationHours;
    if (log.isCompleted) completed++;
  }

  // Calculate simple daily streak
  int streak = 0;
  DateTime checkDate = DateTime.now();
  final logDates = logs.map((l) {
    return DateTime(l.endTime.year, l.endTime.month, l.endTime.day);
  }).toSet();

  while (true) {
    final d = DateTime(checkDate.year, checkDate.month, checkDate.day);
    if (logDates.contains(d)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else if (streak == 0 && !logDates.contains(d)) {
      // Check yesterday if haven't finished fast today yet
      final yesterday = d.subtract(const Duration(days: 1));
      if (logDates.contains(yesterday)) {
        streak++;
        checkDate = yesterday.subtract(const Duration(days: 1));
      } else {
        break;
      }
    } else {
      break;
    }
  }

  return FastingStats(
    totalFasts: logs.length,
    completedFasts: completed,
    totalHours: totalH,
    longestFastHours: longest,
    currentStreak: streak,
  );
});

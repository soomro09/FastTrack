import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/notifications/notification_service.dart';
import 'notification_settings_provider.dart';

enum WaterReminderMode { defaultSchedule, every1h, every2h, every3h, custom }

extension WaterReminderModeLabel on WaterReminderMode {
  String get label {
    switch (this) {
      case WaterReminderMode.defaultSchedule:
        return 'Default (6 times a day)';
      case WaterReminderMode.every1h:
        return 'Every 1 hour';
      case WaterReminderMode.every2h:
        return 'Every 2 hours';
      case WaterReminderMode.every3h:
        return 'Every 3 hours';
      case WaterReminderMode.custom:
        return 'Custom times';
    }
  }
}

class WaterReminderSchedule {
  final WaterReminderMode mode;
  final TimeOfDay wakingStart;
  final TimeOfDay wakingEnd;
  final List<TimeOfDay> customTimes;

  const WaterReminderSchedule({
    required this.mode,
    required this.wakingStart,
    required this.wakingEnd,
    required this.customTimes,
  });

  static const List<TimeOfDay> _defaultTimes = [
    TimeOfDay(hour: 9, minute: 0),
    TimeOfDay(hour: 11, minute: 0),
    TimeOfDay(hour: 13, minute: 0),
    TimeOfDay(hour: 15, minute: 0),
    TimeOfDay(hour: 17, minute: 0),
    TimeOfDay(hour: 19, minute: 0),
  ];

  /// The concrete list of times of day reminders should fire at, resolved
  /// from whichever mode is active.
  List<TimeOfDay> resolveTimes() {
    switch (mode) {
      case WaterReminderMode.defaultSchedule:
        return _defaultTimes;
      case WaterReminderMode.custom:
        return customTimes.isEmpty ? _defaultTimes : customTimes;
      case WaterReminderMode.every1h:
      case WaterReminderMode.every2h:
      case WaterReminderMode.every3h:
        final stepHours = mode == WaterReminderMode.every1h
            ? 1
            : mode == WaterReminderMode.every2h
                ? 2
                : 3;
        final startMinutes = wakingStart.hour * 60 + wakingStart.minute;
        final endMinutes = wakingEnd.hour * 60 + wakingEnd.minute;
        final times = <TimeOfDay>[];
        for (var m = startMinutes; m <= endMinutes; m += stepHours * 60) {
          times.add(TimeOfDay(hour: m ~/ 60, minute: m % 60));
        }
        return times;
    }
  }

  String get summary {
    switch (mode) {
      case WaterReminderMode.defaultSchedule:
        return '6 times a day';
      case WaterReminderMode.custom:
        return '${customTimes.length} custom time${customTimes.length == 1 ? '' : 's'}';
      case WaterReminderMode.every1h:
      case WaterReminderMode.every2h:
      case WaterReminderMode.every3h:
        return mode.label;
    }
  }

  WaterReminderSchedule copyWith({
    WaterReminderMode? mode,
    TimeOfDay? wakingStart,
    TimeOfDay? wakingEnd,
    List<TimeOfDay>? customTimes,
  }) {
    return WaterReminderSchedule(
      mode: mode ?? this.mode,
      wakingStart: wakingStart ?? this.wakingStart,
      wakingEnd: wakingEnd ?? this.wakingEnd,
      customTimes: customTimes ?? this.customTimes,
    );
  }
}

extension _TimeOfDayFormat on TimeOfDay {
  String format24() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

class WaterReminderScheduleNotifier extends Notifier<WaterReminderSchedule> {
  static const _keyMode = 'water_reminder_mode';
  static const _keyStart = 'water_reminder_wake_start';
  static const _keyEnd = 'water_reminder_wake_end';
  static const _keyCustom = 'water_reminder_custom_times';

  @override
  WaterReminderSchedule build() {
    Future.microtask(() => _load());
    return const WaterReminderSchedule(
      mode: WaterReminderMode.defaultSchedule,
      wakingStart: TimeOfDay(hour: 8, minute: 0),
      wakingEnd: TimeOfDay(hour: 22, minute: 0),
      customTimes: [],
    );
  }

  TimeOfDay _parse(String value, TimeOfDay fallback) {
    final parts = value.split(':');
    if (parts.length != 2) return fallback;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return fallback;
    return TimeOfDay(hour: h, minute: m);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeName = prefs.getString(_keyMode);
    final mode = WaterReminderMode.values.firstWhere(
      (m) => m.name == modeName,
      orElse: () => WaterReminderMode.defaultSchedule,
    );
    final start = _parse(
      prefs.getString(_keyStart) ?? '',
      const TimeOfDay(hour: 8, minute: 0),
    );
    final end = _parse(
      prefs.getString(_keyEnd) ?? '',
      const TimeOfDay(hour: 22, minute: 0),
    );
    final customStrings = prefs.getStringList(_keyCustom) ?? [];
    final custom = customStrings
        .map((s) => _parse(s, const TimeOfDay(hour: 9, minute: 0)))
        .toList();

    state = WaterReminderSchedule(
      mode: mode,
      wakingStart: start,
      wakingEnd: end,
      customTimes: custom,
    );
  }

  Future<void> _persistAndReschedule() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMode, state.mode.name);
    await prefs.setString(_keyStart, state.wakingStart.format24());
    await prefs.setString(_keyEnd, state.wakingEnd.format24());
    await prefs.setStringList(
      _keyCustom,
      state.customTimes.map((t) => t.format24()).toList(),
    );

    // Only push a reschedule if the toggle is actually on — otherwise this
    // just saves the preference for next time it's enabled.
    if (ref.read(notificationSettingsProvider).waterReminders) {
      await NotificationService.instance.scheduleWaterReminders(state.resolveTimes());
    }
  }

  Future<void> setMode(WaterReminderMode mode) async {
    state = state.copyWith(mode: mode);
    await _persistAndReschedule();
  }

  Future<void> setWakingWindow(TimeOfDay start, TimeOfDay end) async {
    state = state.copyWith(wakingStart: start, wakingEnd: end);
    await _persistAndReschedule();
  }

  Future<void> addCustomTime(TimeOfDay time) async {
    final updated = [...state.customTimes, time]
      ..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    state = state.copyWith(customTimes: updated);
    await _persistAndReschedule();
  }

  Future<void> removeCustomTime(TimeOfDay time) async {
    final updated = state.customTimes
        .where((t) => !(t.hour == time.hour && t.minute == time.minute))
        .toList();
    state = state.copyWith(customTimes: updated);
    await _persistAndReschedule();
  }
}

final waterReminderScheduleProvider =
    NotifierProvider<WaterReminderScheduleNotifier, WaterReminderSchedule>(() {
  return WaterReminderScheduleNotifier();
});

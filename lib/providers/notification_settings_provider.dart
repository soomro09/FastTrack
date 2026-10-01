import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/notifications/notification_service.dart';
import 'water_reminder_schedule_provider.dart';

class NotificationSettings {
  final bool fastStartEndAlerts;
  final bool stageMilestones;
  final bool waterReminders;

  const NotificationSettings({
    required this.fastStartEndAlerts,
    required this.stageMilestones,
    required this.waterReminders,
  });

  NotificationSettings copyWith({
    bool? fastStartEndAlerts,
    bool? stageMilestones,
    bool? waterReminders,
  }) {
    return NotificationSettings(
      fastStartEndAlerts: fastStartEndAlerts ?? this.fastStartEndAlerts,
      stageMilestones: stageMilestones ?? this.stageMilestones,
      waterReminders: waterReminders ?? this.waterReminders,
    );
  }
}

class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  static const _keyStartEnd = 'notif_fast_start_end';
  static const _keyStages = 'notif_stage_milestones';
  static const _keyWater = 'notif_water_reminders';

  @override
  NotificationSettings build() {
    Future.microtask(() => _load());
    return const NotificationSettings(
      fastStartEndAlerts: false,
      stageMilestones: false,
      waterReminders: false,
    );
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotificationSettings(
      fastStartEndAlerts: prefs.getBool(_keyStartEnd) ?? false,
      stageMilestones: prefs.getBool(_keyStages) ?? false,
      waterReminders: prefs.getBool(_keyWater) ?? false,
    );
    if (state.waterReminders) {
      final times = ref.read(waterReminderScheduleProvider).resolveTimes();
      await NotificationService.instance.scheduleWaterReminders(times);
    }
  }

  Future<bool> setFastStartEndAlerts(bool value) async {
    if (value && !await NotificationService.instance.requestPermission()) {
      return false;
    }
    state = state.copyWith(fastStartEndAlerts: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyStartEnd, value);
    return true;
  }

  Future<bool> setStageMilestones(bool value) async {
    if (value && !await NotificationService.instance.requestPermission()) {
      return false;
    }
    state = state.copyWith(stageMilestones: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyStages, value);
    return true;
  }

  Future<bool> setWaterReminders(bool value) async {
    if (value) {
      if (!await NotificationService.instance.requestPermission()) return false;
      final times = ref.read(waterReminderScheduleProvider).resolveTimes();
      await NotificationService.instance.scheduleWaterReminders(times);
    } else {
      await NotificationService.instance.cancelWaterReminders();
    }
    state = state.copyWith(waterReminders: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWater, value);
    return true;
  }
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(() {
  return NotificationSettingsNotifier();
});

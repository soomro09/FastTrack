import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

import '../../providers/fasting_provider.dart';

/// Wraps flutter_local_notifications behind the app's own scheduling rules —
/// fasting stage milestones, start/end alerts, and recurring water
/// reminders. Uses inexact alarms throughout so it never needs the Android
/// 12+ SCHEDULE_EXACT_ALARM permission; a notification may land a few
/// minutes late, which is an acceptable trade for reminders like these.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _fastingChannel = AndroidNotificationDetails(
    'fasting_alerts',
    'Fasting Alerts',
    channelDescription: 'Fast start/end alerts and metabolic stage milestones',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const _waterChannel = AndroidNotificationDetails(
    'water_reminders',
    'Water Reminders',
    channelDescription: 'Periodic reminders to log water intake',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  // Notification ids: 100s block for stage milestones (one per stage index),
  // 1 for goal-reached, 2000+i for water reminder slots (capped at
  // _maxWaterSlots so cancellation can always clear a previous schedule
  // without tracking how many slots it used).
  static const _goalReachedId = 1;
  static const _maxWaterSlots = 24;

  // Every native platform-channel call in this service goes through this
  // timeout so a hanging/misbehaving plugin (seen on some OEM Android
  // builds) can never block a caller — onboarding, Settings toggles, and
  // app startup all await these methods directly, with no timeout of
  // their own.
  static const _channelTimeout = Duration(seconds: 5);

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    // A plain white silhouette, not the full-color launcher icon — Android
    // flattens status bar icons to white anyway, so a dedicated monochrome
    // asset avoids the launcher logo rendering as a blobby shape there.
    const androidInit = AndroidInitializationSettings('ic_stat_notification');
    const iosInit = DarwinInitializationSettings();
    try {
      await _plugin
          .initialize(
            settings: const InitializationSettings(android: androidInit, iOS: iosInit),
          )
          .timeout(_channelTimeout);
    } catch (_) {
      // Best-effort — if this hangs or fails, notifications just won't
      // fire on this device, but we still mark it "done" below so nothing
      // ever retries the same slow call and hangs again.
    }
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await init();
    try {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin
            .requestNotificationsPermission()
            .timeout(_channelTimeout);
        return granted ?? true;
      }
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin
            .requestPermissions(alert: true, badge: true, sound: true)
            .timeout(_channelTimeout);
        return granted ?? true;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Runs a single native platform-channel call with the shared timeout,
  /// swallowing any failure — see the class doc comment on
  /// [_channelTimeout] for why every call in this service goes through
  /// this instead of a bare await.
  Future<void> _guarded(Future<void> Function() action) async {
    try {
      await action().timeout(_channelTimeout);
    } catch (_) {
      // Best-effort.
    }
  }

  /// Fires immediately — lets a user confirm permission/channel setup works
  /// without waiting for a real scheduled alert (which can be hours away).
  Future<void> showTestNotification() async {
    await init();
    await _guarded(() => _plugin.show(
          id: 9999,
          title: 'Test Notification',
          body: 'If you can see this, fasting_tracker notifications are working.',
          notificationDetails: const NotificationDetails(
            android: _fastingChannel,
            iOS: DarwinNotificationDetails(),
          ),
        ));
  }

  Future<void> _scheduleIn(
    int id,
    String title,
    String body,
    Duration delay,
    AndroidNotificationDetails channel,
  ) async {
    if (delay.isNegative) return;
    await init();
    // DateTime.now() is device-local; TZDateTime.from() re-expresses that
    // same real-world instant in tz.local, so this stays correct even
    // though tz.local itself is left at the package's UTC default.
    final when = tz.TZDateTime.from(DateTime.now().add(delay), tz.local);
    await _guarded(() => _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: when,
          notificationDetails: NotificationDetails(
              android: channel, iOS: const DarwinNotificationDetails()),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        ));
  }

  /// Schedules one notification per remaining metabolic stage boundary and
  /// a goal-reached alert, anchored to [startTime]. Call on fast start;
  /// [cancelFastingAlerts] clears these on early end.
  Future<void> scheduleFastingAlerts({
    required DateTime startTime,
    required int targetHours,
    required bool stageMilestones,
    required bool startEndAlerts,
  }) async {
    if (!stageMilestones && !startEndAlerts) return;
    final elapsed = DateTime.now().difference(startTime);

    if (stageMilestones) {
      for (var i = 0; i < MetabolicStage.stages.length; i++) {
        final stage = MetabolicStage.stages[i];
        if (stage.startHour <= 0) continue; // stage already active at hour 0
        final delay = Duration(minutes: (stage.startHour * 60).round()) - elapsed;
        await _scheduleIn(
          100 + i,
          'Entering ${stage.title}',
          stage.description,
          delay,
          _fastingChannel,
        );
      }
    }

    if (startEndAlerts) {
      final goalDelay = Duration(hours: targetHours) - elapsed;
      await _scheduleIn(
        _goalReachedId,
        'Fasting Goal Reached',
        'You\'ve hit your $targetHours-hour target. Great work — end your fast whenever you\'re ready.',
        goalDelay,
        _fastingChannel,
      );
    }
  }

  Future<void> cancelFastingAlerts() async {
    for (var i = 0; i < MetabolicStage.stages.length; i++) {
      await _guarded(() => _plugin.cancel(id: 100 + i));
    }
    await _guarded(() => _plugin.cancel(id: _goalReachedId));
  }

  /// Schedules one repeating-daily notification per time of day in [times].
  /// Always cancels the full slot range first so switching schedules (fewer
  /// or more times) never leaves a stale entry behind.
  Future<void> scheduleWaterReminders(List<TimeOfDay> times) async {
    await init();
    await cancelWaterReminders();
    final now = DateTime.now();
    final slots = times.take(_maxWaterSlots).toList();
    for (var i = 0; i < slots.length; i++) {
      final time = slots[i];
      var localWhen = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      if (localWhen.isBefore(now)) {
        localWhen = localWhen.add(const Duration(days: 1));
      }
      final when = tz.TZDateTime.from(localWhen, tz.local);
      await _guarded(() => _plugin.zonedSchedule(
            id: 2000 + i,
            title: 'Stay Hydrated',
            body: 'Time for a glass of water.',
            scheduledDate: when,
            notificationDetails: const NotificationDetails(
              android: _waterChannel,
              iOS: DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
          ));
    }
  }

  Future<void> cancelWaterReminders() async {
    for (var i = 0; i < _maxWaterSlots; i++) {
      await _guarded(() => _plugin.cancel(id: 2000 + i));
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/water_reminder_schedule_provider.dart';
import '../widgets/card_container.dart';

class WaterReminderScheduleScreen extends ConsumerWidget {
  const WaterReminderScheduleScreen({super.key});

  String _formatTime(TimeOfDay t) {
    final hour12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour12:$minute $period';
  }

  Future<void> _pickWakingWindow(
    BuildContext context,
    WidgetRef ref,
    WaterReminderSchedule schedule,
  ) async {
    final start = await showTimePicker(
      context: context,
      initialTime: schedule.wakingStart,
      helpText: 'START TIME',
    );
    if (start == null || !context.mounted) return;
    final end = await showTimePicker(
      context: context,
      initialTime: schedule.wakingEnd,
      helpText: 'END TIME',
    );
    if (end == null) return;
    await ref.read(waterReminderScheduleProvider.notifier).setWakingWindow(start, end);
  }

  Future<void> _addCustomTime(BuildContext context, WidgetRef ref) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null) return;
    await ref.read(waterReminderScheduleProvider.notifier).addCustomTime(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final schedule = ref.watch(waterReminderScheduleProvider);
    final isIntervalMode = schedule.mode == WaterReminderMode.every1h ||
        schedule.mode == WaterReminderMode.every2h ||
        schedule.mode == WaterReminderMode.every3h;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Water Reminder Schedule'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CardContainer(
                isDark: isDark,
                child: Column(
                  children: [
                    for (final mode in WaterReminderMode.values) ...[
                      InkWell(
                        onTap: () =>
                            ref.read(waterReminderScheduleProvider.notifier).setMode(mode),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Icon(
                                mode == schedule.mode
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 20,
                                color: mode == schedule.mode
                                    ? AppTheme.primary
                                    : AppTheme.textTertiary(isDark),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                mode.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary(isDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (mode != WaterReminderMode.values.last)
                        Divider(height: 1, color: AppTheme.border(isDark), indent: 16),
                    ],
                  ],
                ),
              ),
              if (isIntervalMode) ...[
                const SizedBox(height: 20),
                Text(
                  'WAKING WINDOW',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppTheme.textSecondary(isDark),
                  ),
                ),
                const SizedBox(height: 10),
                CardContainer(
                  isDark: isDark,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    onTap: () => _pickWakingWindow(context, ref, schedule),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Between ${_formatTime(schedule.wakingStart)} and ${_formatTime(schedule.wakingEnd)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary(isDark),
                            ),
                          ),
                          Icon(Icons.edit_calendar_outlined,
                              size: 18, color: AppTheme.textTertiary(isDark)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              if (schedule.mode == WaterReminderMode.custom) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CUSTOM TIMES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppTheme.textSecondary(isDark),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _addCustomTime(context, ref),
                      child: const Text('+ Add Time'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (schedule.customTimes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No custom times yet — add one above.',
                      style: TextStyle(color: AppTheme.textSecondary(isDark)),
                    ),
                  )
                else
                  CardContainer(
                    isDark: isDark,
                    child: Column(
                      children: [
                        for (final time in schedule.customTimes) ...[
                          ListTile(
                            title: Text(
                              _formatTime(time),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary(isDark),
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline_rounded,
                                  color: AppTheme.danger, size: 20),
                              onPressed: () => ref
                                  .read(waterReminderScheduleProvider.notifier)
                                  .removeCustomTime(time),
                            ),
                          ),
                          if (time != schedule.customTimes.last)
                            Divider(height: 1, color: AppTheme.border(isDark), indent: 16),
                        ],
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

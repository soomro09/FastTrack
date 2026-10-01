import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/db_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/fasting_provider.dart';
import '../../providers/notification_settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/units_provider.dart';
import '../../providers/water_reminder_schedule_provider.dart';
import '../widgets/card_container.dart';
import '../widgets/fade_slide_in.dart';
import 'onboarding_screen.dart';
import 'profile_screen.dart' show goalWeightProvider, weightLogsProvider;
import 'water_reminder_schedule_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showSetGoalDialog(
    BuildContext context,
    WidgetRef ref,
    double? currentGoalKg,
    WeightUnit unit,
  ) {
    final currentInUnit = currentGoalKg != null
        ? unit.fromKg(currentGoalKg)
        : null;
    final txtCtrl = TextEditingController(
      text: currentInUnit?.toStringAsFixed(1) ?? '',
    );
    final maxInUnit = unit.fromKg(500);
    String? errorText;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          title: const Text('Target Goal'),
          content: TextField(
            controller: txtCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            onChanged: (_) {
              if (errorText != null) setState(() => errorText = null);
            },
            decoration: InputDecoration(
              labelText: 'Weight (${unit.label})',
              errorText: errorText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final val = double.tryParse(txtCtrl.text);
                if (val == null || val <= 0 || val > maxInUnit) {
                  setState(
                    () => errorText =
                        'Enter a weight between 1 and ${maxInUnit.toStringAsFixed(0)} ${unit.label}',
                  );
                  return;
                }
                await ref
                    .read(goalWeightProvider.notifier)
                    .setGoal(unit.toKg(val));
                if (context.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: const Text('Reset All Data?'),
        content: const Text(
          'This will delete all logs permanently. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              await DatabaseHelper.instance.clearAllFastingLogs();
              await DatabaseHelper.instance.clearAllWeightLogs();
              ref.invalidate(fastingHistoryProvider);
              ref.invalidate(weightLogsProvider);
              if (context.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Enable notifications for this app in system settings to use reminders.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final goalWeight = ref.watch(goalWeightProvider);
    final currentTheme = ref.watch(themeModeProvider);
    final unit = ref.watch(weightUnitProvider);
    final notifSettings = ref.watch(notificationSettingsProvider);
    final waterSchedule = ref.watch(waterReminderScheduleProvider);

    final selectedSegmentStyle = AppTheme.primarySegmentedButtonStyle(isDark);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeSlideIn(
                child: Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppTheme.textPrimary(isDark),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FadeSlideIn(
                delay: const Duration(milliseconds: 40),
                child: CardContainer(
                  isDark: isDark,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Row(
                          children: [
                            Text(
                              'Theme',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary(isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<ThemeMode>(
                            showSelectedIcon: false,
                            style: selectedSegmentStyle,
                            segments: const [
                              ButtonSegment(
                                value: ThemeMode.system,
                                icon: Icon(
                                  Icons.brightness_auto_rounded,
                                  size: 16,
                                ),
                                label: Text('Auto'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.light,
                                icon: Icon(Icons.light_mode_rounded, size: 16),
                                label: Text('Light'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                icon: Icon(Icons.dark_mode_rounded, size: 16),
                                label: Text('Dark'),
                              ),
                            ],
                            selected: {currentTheme},
                            onSelectionChanged: (newSelection) {
                              ref
                                  .read(themeModeProvider.notifier)
                                  .setTheme(newSelection.first);
                            },
                          ),
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: AppTheme.border(isDark),
                        indent: 16,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Text(
                          'Weight Unit',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary(isDark),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<WeightUnit>(
                            showSelectedIcon: false,
                            style: selectedSegmentStyle,
                            segments: const [
                              ButtonSegment(
                                value: WeightUnit.kg,
                                label: Text('kg'),
                              ),
                              ButtonSegment(
                                value: WeightUnit.lb,
                                label: Text('lb'),
                              ),
                            ],
                            selected: {unit},
                            onSelectionChanged: (newSelection) {
                              ref
                                  .read(weightUnitProvider.notifier)
                                  .setUnit(newSelection.first);
                            },
                          ),
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: AppTheme.border(isDark),
                        indent: 16,
                      ),
                      _SettingsRow(
                        label: 'Target Weight',
                        value: goalWeight != null
                            ? '${unit.fromKg(goalWeight).toStringAsFixed(1)} ${unit.label}'
                            : 'Set goal',
                        isDark: isDark,
                        onTap: () =>
                            _showSetGoalDialog(context, ref, goalWeight, unit),
                      ),
                      Divider(
                        height: 1,
                        color: AppTheme.border(isDark),
                        indent: 16,
                      ),
                      _SettingsRow(
                        label: 'Retake Onboarding',
                        value: 'Update',
                        isDark: isDark,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const OnboardingScreen(isRetake: true),
                          ),
                        ),
                      ),
                      Divider(height: 1, color: AppTheme.border(isDark), indent: 16),
                      _SettingsRow(
                        label: 'Reset App Data',
                        value: 'Clear',
                        valueColor: AppTheme.danger,
                        showChevron: false,
                        isDark: isDark,
                        onTap: () => _confirmClearData(context, ref),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FadeSlideIn(
                delay: const Duration(milliseconds: 70),
                child: CardContainer(
                  isDark: isDark,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Row(
                          children: [
                            Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary(isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _NotificationToggleRow(
                        label: 'Fast Start/End Alerts',
                        subtitle: 'Notify when your fasting goal is reached',
                        value: notifSettings.fastStartEndAlerts,
                        isDark: isDark,
                        onChanged: (value) async {
                          final ok = await ref
                              .read(notificationSettingsProvider.notifier)
                              .setFastStartEndAlerts(value);
                          if (!ok && context.mounted) {
                            _showPermissionDeniedSnack(context);
                          }
                        },
                      ),
                      Divider(
                        height: 1,
                        color: AppTheme.border(isDark),
                        indent: 16,
                      ),
                      _NotificationToggleRow(
                        label: 'Metabolic Stage Milestones',
                        subtitle: 'Notify when you enter a new fasting stage',
                        value: notifSettings.stageMilestones,
                        isDark: isDark,
                        onChanged: (value) async {
                          final ok = await ref
                              .read(notificationSettingsProvider.notifier)
                              .setStageMilestones(value);
                          if (!ok && context.mounted) {
                            _showPermissionDeniedSnack(context);
                          }
                        },
                      ),
                      Divider(
                        height: 1,
                        color: AppTheme.border(isDark),
                        indent: 16,
                      ),
                      _NotificationToggleRow(
                        label: 'Water Reminders',
                        subtitle:
                            'Periodic reminders through the day to hydrate',
                        value: notifSettings.waterReminders,
                        isDark: isDark,
                        onChanged: (value) async {
                          final ok = await ref
                              .read(notificationSettingsProvider.notifier)
                              .setWaterReminders(value);
                          if (!ok && context.mounted) {
                            _showPermissionDeniedSnack(context);
                          }
                        },
                      ),
                      Divider(
                        height: 1,
                        color: AppTheme.border(isDark),
                        indent: 16,
                      ),
                      _SettingsRow(
                        label: 'Water Reminder Schedule',
                        value: waterSchedule.summary,
                        isDark: isDark,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const WaterReminderScheduleScreen(),
                          ),
                        ),
                      ),
                      // _SettingsRow(
                      //   label: 'Send Test Notification',
                      //   value: 'Send',
                      //   isDark: isDark,
                      //   onTap: () async {
                      //     final granted = await NotificationService.instance
                      //         .requestPermission();
                      //     if (!granted) {
                      //       if (context.mounted)
                      //         _showPermissionDeniedSnack(context);
                      //       return;
                      //     }
                      //     await NotificationService.instance
                      //         .showTestNotification();
                      //     if (context.mounted) {
                      //       ScaffoldMessenger.of(context).showSnackBar(
                      //         const SnackBar(
                      //           content: Text(
                      //             'Test notification sent — check your notification shade.',
                      //           ),
                      //         ),
                      //       );
                      //     }
                      //   },
                      // ),
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

class _SettingsRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;
  final bool showChevron;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.label,
    required this.value,
    this.valueColor,
    required this.isDark,
    this.showChevron = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary(isDark),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              value,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: valueColor ?? AppTheme.textSecondary(isDark),
              ),
            ),
            if (showChevron) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppTheme.textTertiary(isDark),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _NotificationToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary(isDark),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppTheme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}


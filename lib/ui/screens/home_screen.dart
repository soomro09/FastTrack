import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../providers/fasting_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_svgs.dart';
import '../widgets/animated_timer_ring.dart';
import '../widgets/animated_flame_icon.dart';
import '../widgets/water_tracker_widget.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/metabolic_stages_widget.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _adjustStartTime(
      BuildContext context, WidgetRef ref, DateTime currentStart) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentStart),
    );

    if (pickedTime == null || !context.mounted) return;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: currentStart,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null || !context.mounted) return;

    final newStart = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (newStart.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start time cannot be in the future')),
      );
      return;
    }

    await ref.read(fastingProvider.notifier).updateStartTime(newStart);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fast start time updated')),
      );
    }
  }

  Future<void> _confirmEndFast(
      BuildContext context, WidgetRef ref, FastingState state) async {
    final isGoalReached = state.isGoalReached;

    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isGoalReached ? Icons.emoji_events_rounded : Icons.info_outline_rounded,
                color: isGoalReached ? AppTheme.success : AppTheme.textSecondary(isDark),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isGoalReached ? 'End Fast & Celebrate' : 'End Fast Early?',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ],
          ),
          content: Text(
            isGoalReached
                ? 'Great job — you reached your ${state.targetHours}h goal. Ready to log your fast and begin eating?'
                : 'You have fasted for ${state.elapsedTime.inHours}h ${state.elapsedTime.inMinutes.remainder(60)}m. Are you sure you want to end before reaching your goal?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep Fasting'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: isGoalReached ? AppTheme.success : AppTheme.danger,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('End Fast'),
            ),
          ],
        );
      },
    );

    if (shouldEnd == true) {
      final log = await ref.read(fastingProvider.notifier).endFast();
      if (context.mounted && log != null) {
        _showCelebrationDialog(context, log.isCompleted, log.targetDurationHours);
      }
    }
  }

  void _showCelebrationDialog(
      BuildContext context, bool completed, int targetHours) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                child: completed
                    ? SvgPicture.string(AppSvgs.trophyAchievement, width: 84, height: 84)
                    : Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary.withAlpha(30),
                        ),
                        child: const Icon(Icons.check_rounded, color: AppTheme.primary, size: 40),
                      ),
              ),
              const SizedBox(height: 18),
              Text(
                completed ? 'Goal Achieved' : 'Fast Logged',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                completed
                    ? 'Congratulations on hitting your $targetHours-hour milestone. Your body thanks you.'
                    : 'Consistency is key — every fast makes your body more metabolically flexible.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary(isDark),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: const Text('Great'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fastingState = ref.watch(fastingProvider);
    final stats = ref.watch(fastingStatsProvider);
    final userProfile = ref.watch(userProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeFormat = DateFormat('h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fasting Timer'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: userProfile.photoPath == null
                      ? AppTheme.primaryGradient
                      : null,
                  image: userProfile.photoPath != null
                      ? DecorationImage(
                          image: FileImage(File(userProfile.photoPath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                  border: Border.all(color: AppTheme.border(isDark)),
                ),
                alignment: Alignment.center,
                child: userProfile.photoPath == null
                    ? Text(
                        userProfile.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 110),
        child: Column(
          children: [
            // Slim inline status row — replaces a boxed banner with plain text.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: fastingState.isFasting ? AppTheme.primary : AppTheme.success,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        fastingState.isFasting ? 'Fast in progress' : 'Eating window open',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary(isDark),
                        ),
                      ),
                    ],
                  ),
                  if (stats.currentStreak > 0)
                    Row(
                      children: [
                        const AnimatedFlameIcon(size: 16),
                        const SizedBox(width: 5),
                        Text(
                          '${stats.currentStreak} day streak',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary(isDark),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Animated Timer Ring
            FadeSlideIn(
              child: AnimatedTimerRing(
                progress: fastingState.progress,
                isFasting: fastingState.isFasting,
                elapsedTime: fastingState.elapsedTime,
                remainingTime: fastingState.remainingTime,
                targetHours: fastingState.targetHours,
                onAdjustStartTime: fastingState.isFasting
                    ? () => _adjustStartTime(context, ref, fastingState.startTime!)
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            // Fast Timing Details — directly below Timer Ring
            if (fastingState.isFasting && fastingState.startTime != null) ...[
              FadeSlideIn(
                delay: const Duration(milliseconds: 50),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.subtleSurface(isDark),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _TimingLabel(
                        label: 'Started',
                        value: timeFormat.format(fastingState.startTime!),
                        isDark: isDark,
                      ),
                      IconButton(
                        onPressed: () => _adjustStartTime(context, ref, fastingState.startTime!),
                        icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                        tooltip: 'Adjust start time',
                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        color: isDark ? AppTheme.primaryGradientStart : AppTheme.primary,
                      ),
                      _TimingLabel(
                        label: 'Target End',
                        value: timeFormat.format(fastingState.targetEndTime!),
                        isDark: isDark,
                        alignEnd: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Primary Fast Action Button
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (fastingState.isFasting) {
                      _confirmEndFast(context, ref, fastingState);
                    } else {
                      ref.read(fastingProvider.notifier).startFast();
                    }
                  },
                  icon: Icon(
                    fastingState.isFasting
                        ? Icons.stop_circle_rounded
                        : Icons.play_arrow_rounded,
                    size: 24,
                  ),
                  label: Text(
                    fastingState.isFasting
                        ? (fastingState.isGoalReached
                            ? 'End Fast · Goal Reached'
                            : 'End Fast Early')
                        : 'Start ${fastingState.targetHours}h Fast',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: fastingState.isFasting
                        ? (fastingState.isGoalReached ? AppTheme.success : AppTheme.danger)
                        : AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: (fastingState.isFasting
                            ? (fastingState.isGoalReached ? AppTheme.success : AppTheme.danger)
                            : AppTheme.primary)
                        .withAlpha(90),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Fasting Stages
            FadeSlideIn(
              delay: const Duration(milliseconds: 110),
              child: MetabolicStagesWidget(fastingState: fastingState),
            ),
            const SizedBox(height: 16),

            // Water Tracker
            FadeSlideIn(
              delay: const Duration(milliseconds: 150),
              child: const WaterTrackerWidget(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimingLabel extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool alignEnd;

  const _TimingLabel({
    required this.label,
    required this.value,
    required this.isDark,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(isDark)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary(isDark),
          ),
        ),
      ],
    );
  }
}

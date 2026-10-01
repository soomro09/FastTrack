import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/weight_log.dart';
import '../../core/database/db_helper.dart';
import '../../core/constants/app_svgs.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/fasting_provider.dart';
import '../../providers/units_provider.dart';
import '../../providers/user_preferences_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../widgets/animated_flame_icon.dart';
import '../widgets/card_container.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/stepped_weight_chart.dart';

final weightLogsProvider = FutureProvider<List<WeightLog>>((ref) async {
  return await DatabaseHelper.instance.getWeightLogs();
});

class GoalWeightNotifier extends Notifier<double?> {
  static const _key = 'goal_weight_key';

  @override
  double? build() {
    Future.microtask(() => _load());
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getDouble(_key);
  }

  Future<void> setGoal(double goal) async {
    state = goal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, goal);
  }
}

final goalWeightProvider = NotifierProvider<GoalWeightNotifier, double?>(() {
  return GoalWeightNotifier();
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _deleteWeightLog(WeightLog log) async {
    if (log.id == null) return;
    await DatabaseHelper.instance.deleteWeightLog(log.id!);
    ref.invalidate(weightLogsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Weight record deleted'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await DatabaseHelper.instance.insertWeightLog(
                WeightLog(weight: log.weight, date: log.date),
              );
              ref.invalidate(weightLogsProvider);
            },
          ),
        ),
      );
    }
  }

  void _showEditNameDialog(String currentName) {
    final txtCtrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: const Text('Edit Profile Name'),
        content: TextField(
          controller: txtCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Display Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (txtCtrl.text.trim().isNotEmpty) {
                ref
                    .read(userProfileProvider.notifier)
                    .updateName(txtCtrl.text.trim());
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndSavePhoto(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;

    final docsDir = await getApplicationDocumentsDirectory();
    final savedPath = '${docsDir.path}/profile_photo.jpg';
    // Overwrite any previous photo under the same fixed name — avoids
    // piling up orphaned image files every time the user changes it.
    await File(picked.path).copy(savedPath);

    if (mounted) {
      ref.read(userProfileProvider.notifier).updatePhoto(savedPath);
    }
  }

  void _showPhotoOptions(bool hasPhoto) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_rounded),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickAndSavePhoto(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickAndSavePhoto(ImageSource.gallery);
                  },
                ),
                if (hasPhoto)
                  ListTile(
                    leading: Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
                    title: Text('Remove Photo', style: TextStyle(color: AppTheme.danger)),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      ref.read(userProfileProvider.notifier).removePhoto();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddWeightDialog() {
    final unit = ref.read(weightUnitProvider);
    final maxInUnit = unit.fromKg(500);
    final txtCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusXl),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Log Weight',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: txtCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        autofocus: true,
                        onChanged: (_) {
                          if (errorText != null) setState(() => errorText = null);
                        },
                        decoration: InputDecoration(
                          labelText: 'Weight (${unit.label})',
                          errorText: errorText,
                          prefixIcon: const Icon(Icons.monitor_weight_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today_rounded),
                        title: Text(
                          DateFormat('EEE, MMM d').format(selectedDate),
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => selectedDate = picked);
                            }
                          },
                          child: const Text('Change'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                        ),
                        onPressed: () async {
                          final val = double.tryParse(txtCtrl.text);
                          if (val == null || val <= 0 || val > maxInUnit) {
                            setState(() => errorText =
                                'Enter a weight between 1 and ${maxInUnit.toStringAsFixed(0)} ${unit.label}');
                            return;
                          }
                          final weightKg = unit.toKg(val);
                          final priorLogs = ref.read(weightLogsProvider).value ?? [];
                          final goal = ref.read(goalWeightProvider);
                          final log = WeightLog(
                            weight: weightKg,
                            date: selectedDate,
                          );
                          await DatabaseHelper.instance.insertWeightLog(log);
                          ref.invalidate(weightLogsProvider);
                          if (context.mounted) Navigator.of(ctx).pop();
                          if (goal != null &&
                              _goalJustAchieved(priorLogs, goal, weightKg) &&
                              mounted) {
                            _showGoalAchievedDialog(goal, weightKg, unit);
                          }
                        },
                        child: const Text(
                          'Save Entry',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
      },
    );
  }

  /// True only the moment the goal transitions from not-met to met — so
  /// logging weight after you've already reached your goal doesn't pop the
  /// celebration dialog again every single day.
  bool _goalJustAchieved(
    List<WeightLog> priorLogs,
    double goal,
    double newWeight,
  ) {
    if (priorLogs.isEmpty) {
      return (newWeight - goal).abs() < 0.05;
    }
    final previous = priorLogs.last.weight;
    final losingWeight = goal <= previous;
    final nowMet = losingWeight ? newWeight <= goal : newWeight >= goal;
    final previouslyMet = losingWeight ? previous <= goal : previous >= goal;
    return nowMet && !previouslyMet;
  }

  void _showGoalAchievedDialog(double goal, double newWeight, WeightUnit unit) {
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
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: SvgPicture.string(
                  AppSvgs.trophyAchievement,
                  width: 84,
                  height: 84,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Goal Weight Reached!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                'You hit your target of ${unit.fromKg(goal).toStringAsFixed(1)} ${unit.label}. That takes real consistency — nice work.',
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBg : AppTheme.lightBg;

    final userProfile = ref.watch(userProfileProvider);
    final stats = ref.watch(fastingStatsProvider);
    final weightLogsAsync = ref.watch(weightLogsProvider);
    final unit = ref.watch(weightUnitProvider);
    final primaryGoal = ref.watch(primaryGoalProvider);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: bgColor,
            surfaceTintColor: Colors.transparent,
            title: const Text(
              'Profile',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            centerTitle: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileHeader(isDark, userProfile, stats, primaryGoal),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Progress', isDark),
                      TextButton(
                        onPressed: _showAddWeightDialog,
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                        ),
                        child: const Text(
                          'Log Weight',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildChartCard(isDark, weightLogsAsync, unit),
                  const SizedBox(height: 20),
                  Text(
                    'RECENT ENTRIES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppTheme.textSecondary(isDark),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildHistoryList(isDark, weightLogsAsync, unit),
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark, userProfile, stats, PrimaryGoal primaryGoal) {
    return FadeSlideIn(
      child: CardContainer(
        isDark: isDark,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _showPhotoOptions(userProfile.photoPath != null),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 84,
                    height: 84,
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
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withAlpha(isDark ? 60 : 40),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: userProfile.photoPath == null
                        ? Text(
                            userProfile.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 28,
                            ),
                          )
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.photo_camera_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  userProfile.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: AppTheme.textPrimary(isDark),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _showEditNameDialog(userProfile.name),
                  child: Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: AppTheme.textTertiary(isDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildBadge(
                  icon: Icons.calendar_today_rounded,
                  text: userProfile.memberSince,
                  color: AppTheme.textSecondary(isDark),
                  isDark: isDark,
                ),
                _buildBadge(
                  icon: primaryGoal.icon,
                  text: primaryGoal.label,
                  color: primaryGoal.color,
                  isDark: isDark,
                ),
                if (stats.currentStreak > 0)
                  _buildBadge(
                    customIcon: const AnimatedFlameIcon(size: 14),
                    text: '${stats.currentStreak} Days',
                    color: AppTheme.warning,
                    isDark: isDark,
                  ),
                if (stats.completedFasts > 0)
                  _buildBadge(
                    icon: Icons.check_circle_rounded,
                    text: '${stats.completedFasts} Fasts',
                    color: AppTheme.success,
                    isDark: isDark,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({
    IconData? icon,
    Widget? customIcon,
    required String text,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 25 : 15),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (customIcon != null)
            customIcon
          else
            Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppTheme.textPrimary(isDark),
      ),
    );
  }

  Widget _buildChartCard(
    bool isDark,
    AsyncValue<List<WeightLog>> weightLogsAsync,
    WeightUnit unit,
  ) {
    return FadeSlideIn(
      delay: const Duration(milliseconds: 100),
      child: CardContainer(
        isDark: isDark,
        padding: const EdgeInsets.all(20),
        child: weightLogsAsync.when(
          data: (logs) {
            if (logs.isEmpty) {
              return SizedBox(
                height: 180,
                child: Center(
                  child: Text(
                    'No weight data logged yet.',
                    style: TextStyle(color: AppTheme.textSecondary(isDark)),
                  ),
                ),
              );
            }
            final displayLogs = unit == WeightUnit.kg
                ? logs
                : logs
                    .map((l) => WeightLog(
                          id: l.id,
                          weight: unit.fromKg(l.weight),
                          date: l.date,
                        ))
                    .toList();
            return SteppedWeightChart(
              logs: displayLogs,
              unitLabel: unit.label,
              onViewAll: () {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                }
              },
              onAddWeight: _showAddWeightDialog,
            );
          },
          loading: () => const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  static const _historyPreviewCount = 2;

  Widget _buildHistoryList(
    bool isDark,
    AsyncValue<List<WeightLog>> weightLogsAsync,
    WeightUnit unit,
  ) {
    return FadeSlideIn(
      delay: const Duration(milliseconds: 200),
      child: weightLogsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'No entries found.',
                  style: TextStyle(color: AppTheme.textSecondary(isDark)),
                ),
              ),
            );
          }
          final reversedLogs = logs.reversed.toList();
          final preview = reversedLogs.take(_historyPreviewCount).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: preview.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _WeightLogTile(
                  item: preview[index],
                  unit: unit,
                  isDark: isDark,
                  onDelete: () => _deleteWeightLog(preview[index]),
                ),
              ),
              if (reversedLogs.length > _historyPreviewCount) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => _showFullHistorySheet(isDark),
                    child: Text('View all ${reversedLogs.length} entries'),
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }

  void _showFullHistorySheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.75,
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
                      color: AppTheme.border(isDark),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      'All Entries',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary(isDark),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, _) {
                        final weightLogsAsync = ref.watch(weightLogsProvider);
                        final unit = ref.watch(weightUnitProvider);
                        return weightLogsAsync.when(
                          data: (logs) {
                            final reversedLogs = logs.reversed.toList();
                            if (reversedLogs.isEmpty) {
                              Navigator.of(ctx).pop();
                              return const SizedBox.shrink();
                            }
                            return ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                              itemCount: reversedLogs.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, index) => _WeightLogTile(
                                item: reversedLogs[index],
                                unit: unit,
                                isDark: isDark,
                                onDelete: () => _deleteWeightLog(reversedLogs[index]),
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
}

// --- Local UI Components --- //

class _WeightLogTile extends StatelessWidget {
  final WeightLog item;
  final WeightUnit unit;
  final bool isDark;
  final VoidCallback onDelete;

  const _WeightLogTile({
    required this.item,
    required this.unit,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id ?? item.date.toIso8601String()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.danger,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: CardContainer(
        isDark: isDark,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(isDark ? 30 : 15),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(
                Icons.monitor_weight_rounded,
                size: 20,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${unit.fromKg(item.weight).toStringAsFixed(1)} ${unit.label}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary(isDark),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, yyyy').format(item.date),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/fasting_provider.dart';
import '../../providers/user_preferences_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/fasting_rhythm_ring.dart';

class FastingPlanInfo {
  final String title;
  final String nickname;
  final int fastHours;
  final int eatHours;
  final String description;
  final String difficulty;
  final Color badgeColor;

  const FastingPlanInfo({
    required this.title,
    required this.nickname,
    required this.fastHours,
    required this.eatHours,
    required this.description,
    required this.difficulty,
    required this.badgeColor,
  });
}

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  static const List<FastingPlanInfo> _predefinedPlans = [
    FastingPlanInfo(
      title: '14:10',
      nickname: 'Gentle Start',
      fastHours: 14,
      eatHours: 10,
      description: 'Ideal for beginners. Easily fits within your sleeping hours plus a light delay in breakfast.',
      difficulty: 'Beginner',
      badgeColor: AppTheme.success,
    ),
    FastingPlanInfo(
      title: '16:8',
      nickname: 'The Golden Standard',
      fastHours: 16,
      eatHours: 8,
      description: 'The most popular intermittent fasting schedule worldwide. Optimal for daily sustainable fat burn.',
      difficulty: 'Intermediate',
      badgeColor: AppTheme.primary,
    ),
    FastingPlanInfo(
      title: '18:6',
      nickname: 'Fat Burn Focus',
      fastHours: 18,
      eatHours: 6,
      description: 'Deepens ketosis and triggers cellular repair. Fast from dinner until afternoon the next day.',
      difficulty: 'Advanced',
      badgeColor: AppTheme.accent,
    ),
    FastingPlanInfo(
      title: '20:4',
      nickname: 'The Warrior Fast',
      fastHours: 20,
      eatHours: 4,
      description: 'A 4-hour evening eating window with a rigorous 20-hour fast inspired by ancient warrior routines.',
      difficulty: 'Expert',
      badgeColor: AppTheme.warning,
    ),
    FastingPlanInfo(
      title: '23:1',
      nickname: 'OMAD (One Meal A Day)',
      fastHours: 23,
      eatHours: 1,
      description: 'Eat one satisfying, nutrient-dense feast per day within a single 1-hour window.',
      difficulty: 'Master',
      badgeColor: AppTheme.danger,
    ),
    FastingPlanInfo(
      title: '36h',
      nickname: 'Monk Fast',
      fastHours: 36,
      eatHours: 12,
      description: 'An extended fast through a full day and two nights. Powerful metabolic reset and autophagy boost.',
      difficulty: 'Extended',
      badgeColor: AppTheme.violet,
    ),
  ];

  void _showCustomPlanDialog(
    BuildContext context,
    WidgetRef ref,
    int currentTarget,
  ) {
    int selectedHours = currentTarget;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.border(isDark),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Custom Fasting Plan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary(isDark),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set your own target fasting duration, from 1 to 72 hours.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary(isDark),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '$selectedHours Hours',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppTheme.primaryGradientStart
                                : AppTheme.primary,
                          ),
                        ),
                        Text(
                          24 - selectedHours > 0
                              ? '${24 - selectedHours}h eating window'
                              : 'Extended multi-day fast',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary(isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.primary,
                      inactiveTrackColor: isDark
                          ? AppTheme.darkCard
                          : AppTheme.lightBorder,
                      thumbColor: AppTheme.primary,
                      overlayColor: AppTheme.primary.withAlpha(30),
                    ),
                    child: Slider(
                      value: selectedHours.toDouble(),
                      min: 1,
                      max: 72,
                      divisions: 71,
                      label: '$selectedHours hrs',
                      onChanged: (val) {
                        setModalState(() {
                          selectedHours = val.round();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () {
                        ref
                            .read(fastingProvider.notifier)
                            .updateTargetHours(selectedHours);
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Target set to $selectedHours hours'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: const Text(
                        'Save Custom Plan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fastingState = ref.watch(fastingProvider);
    final experienceLevel = ref.watch(experienceLevelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeMatches = _predefinedPlans.where(
      (p) => p.fastHours == fastingState.targetHours,
    );
    final selectedPlan = activeMatches.isEmpty ? null : activeMatches.first;
    final recommendedDifficulty = experienceLevel.recommendedPlanDifficulty;

    // Chunk the presets into pairs for a compact 2-column picker grid.
    final rows = <List<FastingPlanInfo>>[];
    for (var i = 0; i < _predefinedPlans.length; i += 2) {
      rows.add(
        _predefinedPlans.sublist(i, (i + 2).clamp(0, _predefinedPlans.length)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fasting Protocols'),
        // actions: [
        //   IconButton(
        //     tooltip: 'Custom Plan',
        //     icon: const Icon(Icons.tune_rounded),
        //     onPressed: () =>
        //         _showCustomPlanDialog(context, ref, fastingState.targetHours),
        //   ),
        // ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
        children: [
          FadeSlideIn(child: _heroCard(fastingState, selectedPlan, isDark)),
          const SizedBox(height: 24),

          Text(
            'ALL PROTOCOLS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppTheme.textSecondary(isDark),
            ),
          ),
          const SizedBox(height: 12),

          for (var r = 0; r < rows.length; r++) ...[
            FadeSlideIn(
              delay: Duration(milliseconds: 30 * r),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _planTile(
                      ref,
                      rows[r][0],
                      fastingState,
                      isDark,
                      rows[r][0].difficulty == recommendedDifficulty,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: rows[r].length > 1
                        ? _planTile(
                            ref,
                            rows[r][1],
                            fastingState,
                            isDark,
                            rows[r][1].difficulty == recommendedDifficulty,
                          )
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 6),
          FadeSlideIn(
            delay: Duration(milliseconds: 30 * rows.length),
            child: _customPlanTile(context, ref, fastingState, isDark),
          ),
        ],
      ),
    );
  }

  // Prominent summary of whichever protocol is currently active — replaces
  // the old thin header row, and doubles as the one place the full
  // description now lives (each grid tile below stays compact).
  Widget _heroCard(FastingState state, FastingPlanInfo? plan, bool isDark) {
    final title = plan?.title ?? '${state.targetHours}h';
    final nickname = plan?.nickname ?? 'Custom Protocol';
    final description =
        plan?.description ??
        'A fully personalized fast duration, tailored by you. Switch to a preset anytime below, or fine-tune further from the icon above.';
    final difficulty = plan?.difficulty ?? 'Custom';
    final badgeColor = plan?.badgeColor ?? AppTheme.primary;
    final eatHours = plan?.eatHours ?? (24 - state.targetHours);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Color.alphaBlend(
                    AppTheme.primary.withAlpha(20),
                    AppTheme.darkSurface,
                  ),
                  AppTheme.darkBg,
                ]
              : [
                  Color.alphaBlend(
                    AppTheme.primary.withAlpha(22),
                    AppTheme.lightBg,
                  ),
                  AppTheme.lightSurface,
                ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.primary.withAlpha(isDark ? 60 : 35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FastingRhythmRing(targetHours: state.targetHours, size: 60),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVE PROTOCOL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark
                            ? AppTheme.primaryGradientStart
                            : AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: AppTheme.textPrimary(isDark),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            nickname,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary(isDark),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Spells out what the "16:8"-style title means in plain
                    // language — the notation alone isn't self-evident.
                    Text(
                      eatHours > 0
                          ? '${state.targetHours}h fast · ${eatHours}h eat window'
                          : '${state.targetHours}h extended fast',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary(isDark),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withAlpha(isDark ? 40 : 22),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        difficulty,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppTheme.textSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  // Compact picker tile — just enough to identify and select a protocol.
  // The full description lives once in the hero card above, not repeated
  // six times down the page.
  Widget _planTile(
    WidgetRef ref,
    FastingPlanInfo plan,
    FastingState state,
    bool isDark,
    bool isRecommended,
  ) {
    final isSelected = state.targetHours == plan.fastHours;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(
          color: isSelected ? AppTheme.primary : AppTheme.border(isDark),
          width: isSelected ? 1.6 : 1,
        ),
      ),
      color: isSelected ? AppTheme.primary.withAlpha(isDark ? 26 : 14) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: () => ref
            .read(fastingProvider.notifier)
            .updateTargetHours(plan.fastHours),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: plan.badgeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      plan.difficulty,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: plan.badgeColor,
                      ),
                    ),
                  ),
                  if (isRecommended)
                    Tooltip(
                      message: 'Recommended for your experience level',
                      child: Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: AppTheme.gold,
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 17,
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.border(isDark),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                plan.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppTheme.textPrimary(isDark),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                plan.nickname,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary(isDark),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: plan.fastHours,
                    child: Container(
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: plan.eatHours > 0 ? plan.eatHours : 1,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.success.withAlpha(150),
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Spells out what "16:8" etc. actually means — the notation
              // alone isn't self-evident to a first-time user.
              Text(
                '${plan.fastHours}h fast · ${plan.eatHours}h eat',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textTertiary(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Full-width row that opens the custom-hours sheet — replaces the old
  // plain OutlinedButton, and doubles as the "custom plan active" indicator.
  Widget _customPlanTile(
    BuildContext context,
    WidgetRef ref,
    FastingState state,
    bool isDark,
  ) {
    final isCustomActive = !_predefinedPlans.any(
      (p) => p.fastHours == state.targetHours,
    );

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(
          color: isCustomActive ? AppTheme.primary : AppTheme.border(isDark),
          width: isCustomActive ? 1.6 : 1,
        ),
      ),
      color: isCustomActive
          ? AppTheme.primary.withAlpha(isDark ? 26 : 14)
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: () => _showCustomPlanDialog(context, ref, state.targetHours),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(isDark ? 45 : 26),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppTheme.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Build Your Own',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCustomActive
                          ? '${state.targetHours}h fast · currently active'
                          : 'Fine-tune a fully custom duration, 1–72 hours',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isCustomActive
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isCustomActive
                            ? AppTheme.primary
                            : AppTheme.textSecondary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondary(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

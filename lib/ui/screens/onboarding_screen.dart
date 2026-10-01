import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_svgs.dart';
import '../../core/database/db_helper.dart';
import '../../models/weight_log.dart';
import '../../providers/fasting_provider.dart';
import '../../providers/water_provider.dart';
import '../../providers/notification_settings_provider.dart';
import '../../providers/user_preferences_provider.dart';
import '../widgets/fasting_rhythm_ring.dart';
import 'profile_screen.dart';
import 'main_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final bool isRetake;

  const OnboardingScreen({
    super.key,
    this.isRetake = false,
  });

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Question 1: Goal
  PrimaryGoal _selectedGoal = PrimaryGoal.loseWeight;

  // Question 2: Experience
  ExperienceLevel _selectedExperience = ExperienceLevel.beginner;

  // Question 3: Recommended Protocol & Optional Weight Baseline
  int _selectedTargetHours = 14;
  // True once the user taps a protocol chip directly — after that, changing
  // goal/experience no longer overwrites their explicit choice.
  bool _hoursManuallySet = false;
  final TextEditingController _startWeightController = TextEditingController();
  final TextEditingController _goalWeightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.isRetake) {
      _preloadExistingAnswers();
    }
  }

  void _preloadExistingAnswers() {
    final goal = ref.read(primaryGoalProvider);
    final experience = ref.read(experienceLevelProvider);
    final targetHours = ref.read(fastingProvider).targetHours;
    final goalWeightKg = ref.read(goalWeightProvider);
    setState(() {
      _selectedGoal = goal;
      _selectedExperience = experience;
      _selectedTargetHours = targetHours;
      _hoursManuallySet = true;
    });
    if (goalWeightKg != null) {
      _goalWeightController.text = goalWeightKg.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _startWeightController.dispose();
    _goalWeightController.dispose();
    super.dispose();
  }

  void _onGoalSelected(PrimaryGoal goal) {
    setState(() {
      _selectedGoal = goal;
      if (!_hoursManuallySet) {
        _selectedTargetHours = recommendedTargetHours(_selectedGoal, _selectedExperience);
      }
    });
  }

  void _onExperienceSelected(ExperienceLevel exp) {
    setState(() {
      _selectedExperience = exp;
      if (!_hoursManuallySet) {
        _selectedTargetHours = recommendedTargetHours(_selectedGoal, _selectedExperience);
      }
    });
  }

  void _nextPage() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);
    await ref.read(primaryGoalProvider.notifier).setGoal(_selectedGoal);
    await ref.read(experienceLevelProvider.notifier).setExperience(_selectedExperience);

    // Apply target fasting protocol
    await ref.read(fastingProvider.notifier).updateTargetHours(_selectedTargetHours);

    // First-time-only defaults — a retake shouldn't silently override
    // notification/water-goal preferences the user may have since changed
    // themselves in Settings.
    if (!widget.isRetake) {
      await ref.read(waterProvider.notifier).setGoal(_selectedGoal.suggestedWaterGoalMl);

      final notifNotifier = ref.read(notificationSettingsProvider.notifier);
      if (_selectedExperience != ExperienceLevel.experienced) {
        await notifNotifier.setFastStartEndAlerts(true);
        await notifNotifier.setStageMilestones(true);
      }
      if (_selectedExperience == ExperienceLevel.beginner) {
        await notifNotifier.setWaterReminders(true);
      }
    }

    // Log starting weight if provided
    bool skippedInvalidWeight = false;
    final startWeightText = _startWeightController.text.trim();
    if (startWeightText.isNotEmpty) {
      final w = double.tryParse(startWeightText);
      if (w != null && w > 20 && w < 300) {
        await DatabaseHelper.instance.insertWeightLog(
          WeightLog(weight: w, date: DateTime.now()),
        );
        ref.invalidate(weightLogsProvider);
      } else {
        skippedInvalidWeight = true;
      }
    }

    // Save goal weight if provided
    final goalWeightText = _goalWeightController.text.trim();
    if (goalWeightText.isNotEmpty) {
      final gw = double.tryParse(goalWeightText);
      if (gw != null && gw > 20 && gw < 300) {
        await ref.read(goalWeightProvider.notifier).setGoal(gw);
      } else {
        skippedInvalidWeight = true;
      }
    }

    if (!mounted) return;

    if (skippedInvalidWeight) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Weight must be between 20 and 300 kg — that entry was skipped'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      // Let the warning above be seen before we navigate away from this screen.
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;
    }

    if (widget.isRetake) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences updated successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black54,
        builder: (ctx) => const _WelcomeCelebrationDialog(),
      );
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation & Step Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                      onPressed: _prevPage,
                      tooltip: 'Back',
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final isActive = index == _currentStep;
                        final isCompleted = index < _currentStep;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppTheme.primary
                                : (isCompleted
                                    ? AppTheme.primary.withAlpha(120)
                                    : (AppTheme.border(isDark))),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),
                  if (_currentStep < 2)
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            // Page View with the 3 steps
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  _buildStep1Goal(isDark),
                  _buildStep2Experience(isDark),
                  _buildStep3PlanAndWeight(isDark),
                ],
              ),
            ),

            // Bottom Continue / Finish button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _nextPage,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentStep == 2
                            ? (widget.isRetake ? 'Save Changes' : 'Start Your Journey')
                            : 'Continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _currentStep == 2 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 1: Main Goal
  Widget _buildStep1Goal(bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      children: [
        const SizedBox(height: 10),
        Text(
          'Step 1 of 3',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'What is your primary goal?',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We customize your fasting metrics and milestones around what matters most to you.',
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 24),

        _optionCard(
          id: PrimaryGoal.loseWeight,
          selectedId: _selectedGoal,
          icon: Icons.local_fire_department_rounded,
          iconColor: const Color(0xFFF97316),
          title: 'Lose Weight',
          subtitle: 'Burn stubborn fat, lower insulin levels, and achieve sustainable weight loss.',
          isDark: isDark,
          onTap: () => _onGoalSelected(PrimaryGoal.loseWeight),
        ),
        const SizedBox(height: 14),

        _optionCard(
          id: PrimaryGoal.maintainWeight,
          selectedId: _selectedGoal,
          icon: Icons.balance_rounded,
          iconColor: const Color(0xFF65A30D),
          title: 'Maintain Weight',
          subtitle: 'Build healthy eating discipline, stop mindless snacking, and balance metabolism.',
          isDark: isDark,
          onTap: () => _onGoalSelected(PrimaryGoal.maintainWeight),
        ),
        const SizedBox(height: 14),

        _optionCard(
          id: PrimaryGoal.boostEnergy,
          selectedId: _selectedGoal,
          icon: Icons.bolt_rounded,
          iconColor: const Color(0xFF14B8A6),
          title: 'Boost Energy & Detox',
          subtitle: 'Trigger cellular autophagy, clear brain fog, and enhance mental focus & longevity.',
          isDark: isDark,
          onTap: () => _onGoalSelected(PrimaryGoal.boostEnergy),
        ),
      ],
    );
  }

  // STEP 2: Fasting Experience
  Widget _buildStep2Experience(bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      children: [
        const SizedBox(height: 10),
        Text(
          'Step 2 of 3',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'What is your fasting experience?',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the pace that fits your routine so fasting feels comfortable and sustainable.',
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 24),

        _optionCard(
          id: ExperienceLevel.beginner,
          selectedId: _selectedExperience,
          icon: Icons.spa_rounded,
          iconColor: const Color(0xFF65A30D),
          title: 'Beginner',
          subtitle: 'New to intermittent fasting or tried it occasionally. Recommends 14:10 protocol.',
          badge: 'Recommended for starters',
          isDark: isDark,
          onTap: () => _onExperienceSelected(ExperienceLevel.beginner),
        ),
        const SizedBox(height: 14),

        _optionCard(
          id: ExperienceLevel.intermediate,
          selectedId: _selectedExperience,
          icon: Icons.trending_up_rounded,
          iconColor: AppTheme.primary,
          title: 'Intermediate',
          subtitle: 'Comfortable skipping breakfast or familiar with 16:8. Ready for consistent fat burn.',
          isDark: isDark,
          onTap: () => _onExperienceSelected(ExperienceLevel.intermediate),
        ),
        const SizedBox(height: 14),

        _optionCard(
          id: ExperienceLevel.experienced,
          selectedId: _selectedExperience,
          icon: Icons.emoji_events_rounded,
          iconColor: const Color(0xFFD97706),
          title: 'Experienced Fasting Pro',
          subtitle: 'Regularly complete 18:6, 20:4, or 24-hour fasts. Looking for advanced ketosis & autophagy.',
          isDark: isDark,
          onTap: () => _onExperienceSelected(ExperienceLevel.experienced),
        ),
      ],
    );
  }

  // STEP 3: Recommended Protocol & Baseline Weight Input
  Widget _buildStep3PlanAndWeight(bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      children: [
        const SizedBox(height: 10),
        Text(
          'Step 3 of 3',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Recommended Setup',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Because you chose ${_selectedGoal.label.toLowerCase()} and '
                    '${_selectedExperience.label.toLowerCase()} experience, we suggest '
                    'a $_selectedTargetHours-hour fast. Switch protocols anytime below.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Live preview of the fast/eat split — updates as the chips below are tapped.
            FastingRhythmRing(targetHours: _selectedTargetHours, size: 56),
          ],
        ),
        const SizedBox(height: 20),

        // Protocol Selector Cards
        Text(
          'Starting Fasting Protocol',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            _protocolChip(
              hours: 14,
              label: '14:10',
              sublabel: 'Gentle',
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _protocolChip(
              hours: 16,
              label: '16:8',
              sublabel: 'Standard',
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _protocolChip(
              hours: 18,
              label: '18:6',
              sublabel: 'Intense',
              isDark: isDark,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Optional Baseline & Goal Weight inputs
        Text(
          'Baseline Weight Tracking (Optional)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter your current weight to instantly activate your stepped weight curve and track progress.',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _startWeightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Current Weight',
                  hintText: 'e.g. 72.0',
                  suffixText: 'kg',
                  prefixIcon: const Icon(Icons.monitor_weight_outlined, size: 20),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _goalWeightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Goal Weight',
                  hintText: 'e.g. 68.0',
                  suffixText: 'kg',
                  prefixIcon: const Icon(Icons.track_changes_rounded, size: 20),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Motivational reassurance card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primary.withAlpha(isDark ? 30 : 18),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: AppTheme.primary.withAlpha(isDark ? 60 : 40),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_rounded, color: AppTheme.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Fasting gets easier each day. You can pause or adjust your timer and goals anytime in the app.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _protocolChip({
    required int hours,
    required String label,
    required String sublabel,
    required bool isDark,
  }) {
    final isSelected = _selectedTargetHours == hours;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTargetHours = hours;
            _hoursManuallySet = true;
          });
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primary.withAlpha(isDark ? 45 : 25)
                : (isDark ? AppTheme.darkSurface : AppTheme.lightSurface),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primary
                  : (AppTheme.border(isDark)),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isSelected
                      ? AppTheme.primary
                      : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppTheme.primary
                      : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionCard({
    required Object id,
    required Object selectedId,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badge,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final isSelected = id == selectedId;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withAlpha(isDark ? 35 : 20)
              : (isDark ? AppTheme.darkSurface : AppTheme.lightSurface),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : (AppTheme.border(isDark)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(isDark ? 40 : 25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withAlpha(isDark ? 50 : 30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.textTertiary(isDark),
                  width: 2,
                ),
                color: isSelected ? AppTheme.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Brief, non-dismissible success beat shown once, right before onboarding
/// hands off to the main app — closes itself after a fixed delay.
class _WelcomeCelebrationDialog extends StatefulWidget {
  const _WelcomeCelebrationDialog();

  @override
  State<_WelcomeCelebrationDialog> createState() => _WelcomeCelebrationDialogState();
}

class _WelcomeCelebrationDialogState extends State<_WelcomeCelebrationDialog> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 550),
              curve: Curves.elasticOut,
              builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
              child: SvgPicture.string(AppSvgs.trophyAchievement, width: 80, height: 80),
            ),
            const SizedBox(height: 18),
            Text(
              "You're All Set!",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your personalized fasting plan is ready. Let's begin.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.4, color: AppTheme.textSecondary(isDark)),
            ),
          ],
        ),
      ),
    );
  }
}

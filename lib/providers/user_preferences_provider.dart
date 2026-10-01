import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PrimaryGoal { loseWeight, maintainWeight, boostEnergy }

extension PrimaryGoalX on PrimaryGoal {
  static const _keys = {
    PrimaryGoal.loseWeight: 'lose_weight',
    PrimaryGoal.maintainWeight: 'maintain_weight',
    PrimaryGoal.boostEnergy: 'boost_energy',
  };

  String get storageKey => _keys[this]!;

  static PrimaryGoal fromStorageKey(String? key) {
    return _keys.entries.firstWhere(
      (e) => e.value == key,
      orElse: () => const MapEntry(PrimaryGoal.loseWeight, ''),
    ).key;
  }

  String get label {
    switch (this) {
      case PrimaryGoal.loseWeight:
        return 'Lose Weight';
      case PrimaryGoal.maintainWeight:
        return 'Maintain Weight';
      case PrimaryGoal.boostEnergy:
        return 'Boost Energy';
    }
  }

  IconData get icon {
    switch (this) {
      case PrimaryGoal.loseWeight:
        return Icons.local_fire_department_rounded;
      case PrimaryGoal.maintainWeight:
        return Icons.balance_rounded;
      case PrimaryGoal.boostEnergy:
        return Icons.bolt_rounded;
    }
  }

  Color get color {
    switch (this) {
      case PrimaryGoal.loseWeight:
        return const Color(0xFFF97316);
      case PrimaryGoal.maintainWeight:
        return const Color(0xFF65A30D);
      case PrimaryGoal.boostEnergy:
        return const Color(0xFF14B8A6);
    }
  }

  /// Suggested daily water goal (mL) for this goal — higher for goals where
  /// hydration is commonly emphasized.
  int get suggestedWaterGoalMl {
    switch (this) {
      case PrimaryGoal.loseWeight:
        return 2500;
      case PrimaryGoal.maintainWeight:
        return 2000;
      case PrimaryGoal.boostEnergy:
        return 3000;
    }
  }
}

enum ExperienceLevel { beginner, intermediate, experienced }

extension ExperienceLevelX on ExperienceLevel {
  static const _keys = {
    ExperienceLevel.beginner: 'beginner',
    ExperienceLevel.intermediate: 'intermediate',
    ExperienceLevel.experienced: 'experienced',
  };

  String get storageKey => _keys[this]!;

  static ExperienceLevel fromStorageKey(String? key) {
    return _keys.entries.firstWhere(
      (e) => e.value == key,
      orElse: () => const MapEntry(ExperienceLevel.beginner, ''),
    ).key;
  }

  String get label {
    switch (this) {
      case ExperienceLevel.beginner:
        return 'Beginner';
      case ExperienceLevel.intermediate:
        return 'Intermediate';
      case ExperienceLevel.experienced:
        return 'Experienced';
    }
  }

  /// The predefined plan difficulty (see PlansScreen) this experience level
  /// maps to, for the "Recommended for you" tag.
  String get recommendedPlanDifficulty {
    switch (this) {
      case ExperienceLevel.beginner:
        return 'Beginner';
      case ExperienceLevel.intermediate:
        return 'Intermediate';
      case ExperienceLevel.experienced:
        return 'Advanced';
    }
  }
}

/// Combined (goal, experience) -> suggested starting fast duration. Beginners
/// always start gentle regardless of goal; more experienced users get a
/// duration nudged toward their stated goal.
int recommendedTargetHours(PrimaryGoal goal, ExperienceLevel experience) {
  switch (experience) {
    case ExperienceLevel.beginner:
      return 14;
    case ExperienceLevel.intermediate:
      return goal == PrimaryGoal.boostEnergy ? 18 : 16;
    case ExperienceLevel.experienced:
      switch (goal) {
        case PrimaryGoal.loseWeight:
          return 18;
        case PrimaryGoal.maintainWeight:
          return 16;
        case PrimaryGoal.boostEnergy:
          return 20;
      }
  }
}

class PrimaryGoalNotifier extends Notifier<PrimaryGoal> {
  static const _key = 'user_primary_goal';

  @override
  PrimaryGoal build() {
    Future.microtask(_load);
    return PrimaryGoal.loseWeight;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = PrimaryGoalX.fromStorageKey(prefs.getString(_key));
  }

  Future<void> setGoal(PrimaryGoal goal) async {
    state = goal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, goal.storageKey);
  }
}

final primaryGoalProvider = NotifierProvider<PrimaryGoalNotifier, PrimaryGoal>(() {
  return PrimaryGoalNotifier();
});

class ExperienceLevelNotifier extends Notifier<ExperienceLevel> {
  static const _key = 'user_experience_level';

  @override
  ExperienceLevel build() {
    Future.microtask(_load);
    return ExperienceLevel.beginner;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = ExperienceLevelX.fromStorageKey(prefs.getString(_key));
  }

  Future<void> setExperience(ExperienceLevel level) async {
    state = level;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, level.storageKey);
  }
}

final experienceLevelProvider =
    NotifierProvider<ExperienceLevelNotifier, ExperienceLevel>(() {
  return ExperienceLevelNotifier();
});

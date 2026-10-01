import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaterState {
  final int currentMl;
  final int goalMl;
  final String date;

  WaterState({
    required this.currentMl,
    required this.goalMl,
    required this.date,
  });

  double get progress => (currentMl / goalMl).clamp(0.0, 1.0);

  /// Unclamped percent of goal — unlike [progress] (used to fill the droplet
  /// shape, which can't visually exceed 100%), this can go past 100 so the
  /// "% completed" text stays honest once the user logs more than their goal.
  int get percentOfGoal => goalMl > 0 ? ((currentMl / goalMl) * 100).round() : 0;

  WaterState copyWith({
    int? currentMl,
    int? goalMl,
    String? date,
  }) {
    return WaterState(
      currentMl: currentMl ?? this.currentMl,
      goalMl: goalMl ?? this.goalMl,
      date: date ?? this.date,
    );
  }
}

class WaterNotifier extends Notifier<WaterState> {
  static const _keyCurrent = 'water_current_ml';
  static const _keyGoal = 'water_goal_ml';
  static const _keyDate = 'water_date';

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  WaterState build() {
    Future.microtask(() => _load());
    return WaterState(
      currentMl: 0,
      goalMl: 2000,
      date: _todayString(),
    );
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_keyDate);
    final today = _todayString();
    final goal = prefs.getInt(_keyGoal) ?? 2000;

    if (savedDate == today) {
      final current = prefs.getInt(_keyCurrent) ?? 0;
      state = WaterState(currentMl: current, goalMl: goal, date: today);
    } else {
      // New day, reset
      await prefs.setString(_keyDate, today);
      await prefs.setInt(_keyCurrent, 0);
      state = WaterState(currentMl: 0, goalMl: goal, date: today);
    }
  }

  Future<void> addWater([int ml = 250]) async {
    final newAmount = state.currentMl + ml;
    state = state.copyWith(currentMl: newAmount);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCurrent, newAmount);
    await prefs.setString(_keyDate, state.date);
  }

  Future<void> removeWater([int ml = 250]) async {
    final newAmount = (state.currentMl - ml).clamp(0, 99999);
    state = state.copyWith(currentMl: newAmount);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCurrent, newAmount);
  }

  Future<void> setGoal(int goal) async {
    state = state.copyWith(goalMl: goal);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyGoal, goal);
  }
}

final waterProvider = NotifierProvider<WaterNotifier, WaterState>(() {
  return WaterNotifier();
});

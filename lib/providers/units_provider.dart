import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WeightUnit { kg, lb }

extension WeightUnitConversion on WeightUnit {
  String get label => this == WeightUnit.kg ? 'kg' : 'lb';

  /// Converts a value stored internally in kg to this unit for display.
  double fromKg(double kg) => this == WeightUnit.kg ? kg : kg * 2.20462;

  /// Converts a value entered in this unit back to kg for storage.
  double toKg(double value) => this == WeightUnit.kg ? value : value / 2.20462;
}

class UnitsNotifier extends Notifier<WeightUnit> {
  static const _key = 'weight_unit';

  @override
  WeightUnit build() {
    Future.microtask(() => _load());
    return WeightUnit.kg;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    state = value == 'lb' ? WeightUnit.lb : WeightUnit.kg;
  }

  Future<void> setUnit(WeightUnit unit) async {
    state = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, unit.name);
  }
}

final weightUnitProvider = NotifierProvider<UnitsNotifier, WeightUnit>(() {
  return UnitsNotifier();
});

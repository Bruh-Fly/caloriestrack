import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/food_result.dart';
import '../models/meal_entry.dart';
import '../services/storage_service.dart';

class AppProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final _uuid = const Uuid();

  List<MealEntry> _meals       = [];
  int    _calorieGoal = 2000;
  double _proteinGoal = 50.0;
  double _carbsGoal   = 250.0;
  double _fatGoal     = 65.0;

  // ── Getters ────────────────────────────────────────────────────
  List<MealEntry> get allMeals     => _meals;
  int    get calorieGoal => _calorieGoal;
  double get proteinGoal => _proteinGoal;
  double get carbsGoal   => _carbsGoal;
  double get fatGoal     => _fatGoal;

  List<MealEntry> get todayMeals {
    final now = DateTime.now();
    return _meals
        .where((m) =>
            m.timestamp.year  == now.year  &&
            m.timestamp.month == now.month &&
            m.timestamp.day   == now.day)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  int    get todayCalories => todayMeals.fold(0,   (s, m) => s + m.calories);
  double get todayProtein  => todayMeals.fold(0.0, (s, m) => s + m.protein);
  double get todayCarbs    => todayMeals.fold(0.0, (s, m) => s + m.carbs);
  double get todayFat      => todayMeals.fold(0.0, (s, m) => s + m.fat);

  double get calorieProgress => (todayCalories / _calorieGoal).clamp(0.0, 1.0);
  double get proteinProgress => (todayProtein  / _proteinGoal).clamp(0.0, 1.0);
  double get carbsProgress   => (todayCarbs    / _carbsGoal).clamp(0.0, 1.0);
  double get fatProgress     => (todayFat      / _fatGoal).clamp(0.0, 1.0);

  int get remainingCalories => (_calorieGoal - todayCalories).clamp(0, 9999);

  // ── Init ───────────────────────────────────────────────────────
  Future<void> init() async {
    _meals        = await _storage.loadMeals();
    _calorieGoal  = await _storage.getCalorieGoal();
    _proteinGoal  = await _storage.getProteinGoal();
    _carbsGoal    = await _storage.getCarbsGoal();
    _fatGoal      = await _storage.getFatGoal();
    notifyListeners();
  }

  // ── Meal actions ───────────────────────────────────────────────
  Future<void> logMeal(FoodResult result, {String? imagePath}) async {
    final entry = MealEntry.fromFoodResult(
      result,
      id:        _uuid.v4(),
      timestamp: DateTime.now(),
      imagePath: imagePath,
    );
    _meals.add(entry);
    await _storage.saveMeal(entry);
    notifyListeners();
  }

  Future<void> deleteMeal(String id) async {
    _meals.removeWhere((m) => m.id == id);
    await _storage.deleteMeal(id);
    notifyListeners();
  }

  // ── Goals ──────────────────────────────────────────────────────
  Future<void> updateCalorieGoal(int v) async {
    _calorieGoal = v;
    await _storage.saveCalorieGoal(v);
    notifyListeners();
  }

  Future<void> updateMacroGoals({
    required double protein,
    required double carbs,
    required double fat,
  }) async {
    _proteinGoal = protein;
    _carbsGoal   = carbs;
    _fatGoal     = fat;
    await _storage.saveProteinGoal(protein);
    await _storage.saveCarbsGoal(carbs);
    await _storage.saveFatGoal(fat);
    notifyListeners();
  }

  // ── History helpers ────────────────────────────────────────────
  List<MealEntry> mealsForDate(DateTime date) {
    return _meals
        .where((m) =>
            m.timestamp.year  == date.year  &&
            m.timestamp.month == date.month &&
            m.timestamp.day   == date.day)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Returns a map {dateStr: [meals]} sorted newest first
  Map<DateTime, List<MealEntry>> get mealsGroupedByDate {
    final grouped = <DateTime, List<MealEntry>>{};
    for (final meal in _meals) {
      final key = DateTime(
        meal.timestamp.year,
        meal.timestamp.month,
        meal.timestamp.day,
      );
      grouped.putIfAbsent(key, () => []).add(meal);
    }
    final sorted = Map.fromEntries(
      grouped.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key)),
    );
    for (final list in sorted.values) {
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    return sorted;
  }
}

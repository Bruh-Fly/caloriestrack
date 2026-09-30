import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/food_result.dart';
import '../models/meal_entry.dart';
import '../services/storage_service.dart';
import '../services/api_client.dart';

class AppProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final ApiClient _api = ApiClient();
  final _uuid = const Uuid();

  List<MealEntry> _meals = [];
  int _calorieGoal = 2000;
  double _proteinGoal = 50.0;
  double _carbsGoal = 250.0;
  double _fatGoal = 65.0;

  // ── Getters ────────────────────────────────────────────────────
  List<MealEntry> get allMeals => _meals;
  int get calorieGoal => _calorieGoal;
  double get proteinGoal => _proteinGoal;
  double get carbsGoal => _carbsGoal;
  double get fatGoal => _fatGoal;

  List<MealEntry> get todayMeals {
    final now = DateTime.now();
    return _meals
        .where((m) =>
            m.timestamp.year == now.year &&
            m.timestamp.month == now.month &&
            m.timestamp.day == now.day)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  int get todayCalories => todayMeals.fold(0, (s, m) => s + m.calories);
  double get todayProtein => todayMeals.fold(0.0, (s, m) => s + m.protein);
  double get todayCarbs => todayMeals.fold(0.0, (s, m) => s + m.carbs);
  double get todayFat => todayMeals.fold(0.0, (s, m) => s + m.fat);

  double get calorieProgress => (todayCalories / _calorieGoal).clamp(0.0, 1.0);
  double get proteinProgress => (todayProtein / _proteinGoal).clamp(0.0, 1.0);
  double get carbsProgress => (todayCarbs / _carbsGoal).clamp(0.0, 1.0);
  double get fatProgress => (todayFat / _fatGoal).clamp(0.0, 1.0);

  int get remainingCalories => (_calorieGoal - todayCalories).clamp(0, 9999);

  // ── Init ───────────────────────────────────────────────────────
  Future<void> init() async {
    _meals = await _storage.loadMeals();
    _calorieGoal = await _storage.getCalorieGoal();
    _proteinGoal = await _storage.getProteinGoal();
    _carbsGoal = await _storage.getCarbsGoal();
    _fatGoal = await _storage.getFatGoal();
    if (await _api.hasStoredSession()) unawaited(refreshMealsFromBackend());
  }

  Future<void> refreshMealsFromBackend() async {
    try {
      final remoteMeals = await _api.loadMeals();
      final remoteIds = remoteMeals.map((meal) => meal.id).toSet();
      final localOnly = _meals.where((meal) => !remoteIds.contains(meal.id));
      _meals = [...remoteMeals, ...localOnly]
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      await _storage.replaceMeals(_meals);
    } catch (_) {
      // Keep the existing local diary visible while the backend is unavailable.
    }
    notifyListeners();
  }

  /// Starts a clean local view for the authenticated account, preventing a
  /// previous Google account's offline entries from being merged into it.
  Future<void> loadAccountDataFromBackend() async {
    _meals = [];
    await _storage.replaceMeals(_meals);
    try {
      _meals = await _api.loadMeals();
      _meals.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      await _storage.replaceMeals(_meals);
    } catch (_) {
      // Keep the account's local cache empty rather than show another user's data.
    }
    notifyListeners();
  }

  Future<void> clearForSignOut() async {
    _meals = [];
    await _storage.replaceMeals(_meals);
    _calorieGoal = 2000;
    _proteinGoal = 50;
    _carbsGoal = 250;
    _fatGoal = 65;
    await _storage.saveCalorieGoal(_calorieGoal);
    await _storage.saveProteinGoal(_proteinGoal);
    await _storage.saveCarbsGoal(_carbsGoal);
    await _storage.saveFatGoal(_fatGoal);
    notifyListeners();
  }

  // ── Meal actions ───────────────────────────────────────────────
  Future<void> logMeal(FoodResult result,
      {String? imagePath, String mealType = 'other'}) async {
    final timestamp = DateTime.now();
    final remoteId = await _api.logMeal(result, timestamp, mealType: mealType);
    final entry = MealEntry.fromFoodResult(
      result,
      id: remoteId.isEmpty ? _uuid.v4() : remoteId,
      timestamp: timestamp,
      imagePath: imagePath,
      mealType: mealType,
    );
    _meals.add(entry);
    await _storage.saveMeal(entry);
    notifyListeners();
  }

  Future<void> logManualMeal({
    required String name,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    required String serving,
    String mealType = 'other',
  }) async {
    final timestamp = DateTime.now();
    var id = _uuid.v4();
    try {
      id = await _api.logManualMeal(
        name: name,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        serving: serving,
        consumedAt: timestamp,
        mealType: mealType,
      );
    } catch (_) {
      // Manual meal logging remains available offline; local entries merge on sync.
    }
    final entry = MealEntry(
      id: id,
      name: name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      serving: serving,
      timestamp: timestamp,
      mealType: mealType,
    );
    _meals.add(entry);
    await _storage.saveMeal(entry);
    notifyListeners();
  }

  Future<void> deleteMeal(String id) async {
    await _api.deleteMeal(id);
    _meals.removeWhere((m) => m.id == id);
    await _storage.deleteMeal(id);
    notifyListeners();
  }

  // ── Goals ──────────────────────────────────────────────────────
  Future<void> updateCalorieGoal(int v) async {
    _calorieGoal = v;
    await _storage.saveCalorieGoal(v);
    await _syncNutritionGoals();
    notifyListeners();
  }

  Future<void> updateMacroGoals({
    required double protein,
    required double carbs,
    required double fat,
  }) async {
    _proteinGoal = protein;
    _carbsGoal = carbs;
    _fatGoal = fat;
    await _storage.saveProteinGoal(protein);
    await _storage.saveCarbsGoal(carbs);
    await _storage.saveFatGoal(fat);
    await _syncNutritionGoals();
    notifyListeners();
  }

  Future<void> _syncNutritionGoals() async {
    try {
      await _api.updateNutritionGoals(
        calories: _calorieGoal,
        protein: _proteinGoal,
        carbs: _carbsGoal,
        fat: _fatGoal,
      );
    } catch (_) {
      // Local goal edits remain usable offline and sync after the next save.
    }
  }

  // ── History helpers ────────────────────────────────────────────
  List<MealEntry> mealsForDate(DateTime date) {
    return _meals
        .where((m) =>
            m.timestamp.year == date.year &&
            m.timestamp.month == date.month &&
            m.timestamp.day == date.day)
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
      grouped.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
    for (final list in sorted.values) {
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    return sorted;
  }
}

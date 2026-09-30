import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_entry.dart';

class StorageService {
  static const _mealsKey       = 'caloai_meals_v1';
  static const _calorieGoalKey = 'caloai_calorie_goal';
  static const _proteinGoalKey = 'caloai_protein_goal';
  static const _carbsGoalKey   = 'caloai_carbs_goal';
  static const _fatGoalKey     = 'caloai_fat_goal';

  // ── Meals ──────────────────────────────────────────────────────
  Future<List<MealEntry>> loadMeals() async {
    final prefs    = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_mealsKey) ?? [];
    return jsonList
        .map((s) => MealEntry.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveMeal(MealEntry meal) async {
    final prefs    = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_mealsKey) ?? [];
    jsonList.add(jsonEncode(meal.toJson()));
    await prefs.setStringList(_mealsKey, jsonList);
  }

  Future<void> replaceMeals(List<MealEntry> meals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _mealsKey,
      meals.map((meal) => jsonEncode(meal.toJson())).toList(),
    );
  }

  Future<void> deleteMeal(String id) async {
    final prefs    = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_mealsKey) ?? [];
    jsonList.removeWhere((s) {
      final map = jsonDecode(s) as Map<String, dynamic>;
      return map['id'] == id;
    });
    await prefs.setStringList(_mealsKey, jsonList);
  }

  // ── Goals ──────────────────────────────────────────────────────
  Future<int>    getCalorieGoal() async => (await SharedPreferences.getInstance()).getInt(_calorieGoalKey) ?? 2000;
  Future<double> getProteinGoal() async => (await SharedPreferences.getInstance()).getDouble(_proteinGoalKey) ?? 50.0;
  Future<double> getCarbsGoal()   async => (await SharedPreferences.getInstance()).getDouble(_carbsGoalKey)   ?? 250.0;
  Future<double> getFatGoal()     async => (await SharedPreferences.getInstance()).getDouble(_fatGoalKey)     ?? 65.0;

  Future<void> saveCalorieGoal(int v)    async => (await SharedPreferences.getInstance()).setInt(_calorieGoalKey, v);
  Future<void> saveProteinGoal(double v) async => (await SharedPreferences.getInstance()).setDouble(_proteinGoalKey, v);
  Future<void> saveCarbsGoal(double v)   async => (await SharedPreferences.getInstance()).setDouble(_carbsGoalKey, v);
  Future<void> saveFatGoal(double v)     async => (await SharedPreferences.getInstance()).setDouble(_fatGoalKey, v);
}

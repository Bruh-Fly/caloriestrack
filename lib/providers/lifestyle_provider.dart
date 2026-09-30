import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ActivityEntry {
  const ActivityEntry({
    required this.id,
    required this.name,
    required this.minutes,
    required this.calories,
    required this.createdAt,
    this.distanceKm,
    this.note = '',
  });

  final String id;
  final String name;
  final int minutes;
  final int calories;
  final DateTime createdAt;
  final double? distanceKm;
  final String note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'minutes': minutes,
        'calories': calories,
        'createdAt': createdAt.toIso8601String(),
        'distanceKm': distanceKm,
        'note': note,
      };

  factory ActivityEntry.fromJson(Map<String, dynamic> json) => ActivityEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        minutes: (json['minutes'] as num).toInt(),
        calories: (json['calories'] as num).toInt(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        distanceKm: (json['distanceKm'] as num?)?.toDouble(),
        note: json['note'] as String? ?? '',
      );
}

class FastEntry {
  const FastEntry({required this.startedAt, required this.endedAt});
  final DateTime startedAt;
  final DateTime endedAt;
  Duration get duration => endedAt.difference(startedAt);

  Map<String, dynamic> toJson() => {
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
      };

  factory FastEntry.fromJson(Map<String, dynamic> json) => FastEntry(
        startedAt: DateTime.parse(json['startedAt'] as String),
        endedAt: DateTime.parse(json['endedAt'] as String),
      );
}

class LifestyleProvider extends ChangeNotifier {
  static const _waterGoalKey = 'caloai_life_water_goal';
  static const _waterDateKey = 'caloai_life_water_date';
  static const _waterAmountKey = 'caloai_life_water_amount';
  static const _stepsDateKey = 'caloai_life_steps_date';
  static const _stepsAmountKey = 'caloai_life_steps_amount';
  static const _stepGoalKey = 'caloai_life_steps_goal';
  static const _fastStartKey = 'caloai_life_fast_start';
  static const _fastGoalKey = 'caloai_life_fast_goal';
  static const _fastHistoryKey = 'caloai_life_fast_history';
  static const _favoritesKey = 'caloai_life_favorites';
  static const _shoppingKey = 'caloai_life_shopping';
  static const _activitiesKey = 'caloai_life_activities';
  static const _weightsKey = 'caloai_life_weights';
  static const _weightNowKey = 'caloai_life_weight_now';
  static const _weightGoalKey = 'caloai_life_weight_goal';
  static const _customActivitiesKey = 'caloai_life_custom_activities';
  static const _recipeWelcomeKey = 'caloai_life_recipe_welcome';
  static const _recipeLevelKey = 'caloai_life_recipe_level';
  static const _recipeDietKey = 'caloai_life_recipe_diet';
  static const _recipeTimeKey = 'caloai_life_recipe_time';
  static const _uuid = Uuid();

  int waterGoalMl = 2000;
  int waterMl = 0;
  int stepGoal = 10000;
  int steps = 0;
  int fastGoalHours = 16;
  DateTime? fastStartedAt;
  int mood = 0;
  String note = '';
  List<ActivityEntry> activities = [];
  List<FastEntry> fastHistory = [];
  Set<String> favoriteRecipes = {};
  List<String> shoppingList = [];
  List<double> weightHistory = [];
  double currentWeightKg = 70;
  double goalWeightKg = 65;
  double heightCm = 170;
  int ageYears = 30;
  String sex = 'female';
  String activityLevel = 'light';
  String weightGoal = 'lose_weight';
  String goalRate = 'moderate';
  List<String> customActivities = [];
  bool recipesOnboarded = false;
  String cookingLevel = 'beginner';
  String recipeDiet = 'No preference';
  String recipeCookingTime = 'Any time';

  String get todayKey => _dateKey(DateTime.now());
  int get waterCups => (waterMl / 250).floor();
  int get waterCupsGoal => (waterGoalMl / 250).ceil();
  double get waterProgress =>
      waterGoalMl <= 0 ? 0 : (waterMl / waterGoalMl).clamp(0.0, 1.0);
  double get stepProgress =>
      stepGoal <= 0 ? 0 : (steps / stepGoal).clamp(0.0, 1.0);
  int get activityCaloriesToday => activities
      .where((entry) => _dateKey(entry.createdAt) == todayKey)
      .fold(0, (sum, entry) => sum + entry.calories);
  List<ActivityEntry> get todayActivities => activities
      .where((entry) => _dateKey(entry.createdAt) == todayKey)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  Duration get currentFastDuration => fastStartedAt == null
      ? Duration.zero
      : DateTime.now().difference(fastStartedAt!);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    waterGoalMl = prefs.getInt(_waterGoalKey) ?? 2000;
    stepGoal = prefs.getInt(_stepGoalKey) ?? 10000;
    fastGoalHours = prefs.getInt(_fastGoalKey) ?? 16;
    currentWeightKg = prefs.getDouble(_weightNowKey) ?? currentWeightKg;
    goalWeightKg = prefs.getDouble(_weightGoalKey) ?? goalWeightKg;
    customActivities = prefs.getStringList(_customActivitiesKey) ?? [];
    recipesOnboarded = prefs.getBool(_recipeWelcomeKey) ?? false;
    cookingLevel = prefs.getString(_recipeLevelKey) ?? 'beginner';
    recipeDiet = prefs.getString(_recipeDietKey) ?? 'No preference';
    recipeCookingTime = prefs.getString(_recipeTimeKey) ?? 'Any time';

    final today = todayKey;
    waterMl = prefs.getString(_waterDateKey) == today
        ? (prefs.getInt(_waterAmountKey) ?? 0)
        : 0;
    steps = prefs.getString(_stepsDateKey) == today
        ? (prefs.getInt(_stepsAmountKey) ?? 0)
        : 0;

    final noteJson = prefs.getString('caloai_life_note_$today');
    if (noteJson != null) {
      final decoded = jsonDecode(noteJson) as Map<String, dynamic>;
      mood = (decoded['mood'] as num?)?.toInt() ?? 0;
      note = decoded['note'] as String? ?? '';
    }
    final fastStart = prefs.getString(_fastStartKey);
    fastStartedAt = fastStart == null ? null : DateTime.tryParse(fastStart);
    favoriteRecipes = (prefs.getStringList(_favoritesKey) ?? []).toSet();
    shoppingList = prefs.getStringList(_shoppingKey) ?? [];
    activities = _readJsonList(
        prefs.getStringList(_activitiesKey), ActivityEntry.fromJson);
    fastHistory =
        _readJsonList(prefs.getStringList(_fastHistoryKey), FastEntry.fromJson);
    final weights = prefs.getStringList(_weightsKey) ?? [];
    weightHistory = weights.map(double.tryParse).whereType<double>().toList();
  }

  Future<void> clearForSignOut() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().where((key) =>
        key.startsWith('caloai_life_') ||
        key.startsWith('caloai_life_note_'))) {
      await prefs.remove(key);
    }
    waterGoalMl = 2000;
    waterMl = 0;
    stepGoal = 10000;
    steps = 0;
    fastGoalHours = 16;
    fastStartedAt = null;
    mood = 0;
    note = '';
    activities = [];
    fastHistory = [];
    favoriteRecipes = {};
    shoppingList = [];
    weightHistory = [];
    currentWeightKg = 70;
    goalWeightKg = 65;
    customActivities = [];
    recipesOnboarded = false;
    cookingLevel = 'beginner';
    recipeDiet = 'No preference';
    recipeCookingTime = 'Any time';
    notifyListeners();
  }

  Future<void> addWater([int amountMl = 250]) async {
    waterMl = (waterMl + amountMl.clamp(50, 1000)).clamp(0, 10000);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_waterDateKey, todayKey);
    await prefs.setInt(_waterAmountKey, waterMl);
    notifyListeners();
  }

  Future<void> undoWater([int amountMl = 250]) async {
    waterMl = (waterMl - amountMl).clamp(0, 10000);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_waterDateKey, todayKey);
    await prefs.setInt(_waterAmountKey, waterMl);
    notifyListeners();
  }

  Future<void> setWaterGoal(int amountMl) async {
    waterGoalMl = amountMl.clamp(500, 6000);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_waterGoalKey, waterGoalMl);
    notifyListeners();
  }

  Future<void> addSteps(int amount) async {
    steps = (steps + amount).clamp(0, 100000);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stepsDateKey, todayKey);
    await prefs.setInt(_stepsAmountKey, steps);
    notifyListeners();
  }

  Future<void> setSteps(int amount) async {
    steps = amount.clamp(0, 100000);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stepsDateKey, todayKey);
    await prefs.setInt(_stepsAmountKey, steps);
    notifyListeners();
  }

  Future<void> setStepGoal(int amount) async {
    stepGoal = amount.clamp(1000, 50000);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_stepGoalKey, stepGoal);
    notifyListeners();
  }

  Future<void> addActivity({
    required String name,
    required int minutes,
    required int calories,
    int stepsToAdd = 0,
    double? distanceKm,
    String note = '',
  }) async {
    activities.insert(
      0,
      ActivityEntry(
        id: _uuid.v4(),
        name: name,
        minutes: minutes,
        calories: calories,
        createdAt: DateTime.now(),
        distanceKm: distanceKm,
        note: note.trim(),
      ),
    );
    if (stepsToAdd > 0) steps += stepsToAdd;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _activitiesKey,
      activities.take(100).map((entry) => jsonEncode(entry.toJson())).toList(),
    );
    await prefs.setString(_stepsDateKey, todayKey);
    await prefs.setInt(_stepsAmountKey, steps);
    notifyListeners();
  }

  Future<void> saveNote({required int mood, required String note}) async {
    this.mood = mood;
    this.note = note.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'caloai_life_note_$todayKey',
      jsonEncode({'mood': mood, 'note': this.note}),
    );
    notifyListeners();
  }

  Future<void> startFast({int? hours}) async {
    if (hours != null) fastGoalHours = hours.clamp(8, 20);
    fastStartedAt = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_fastGoalKey, fastGoalHours);
    await prefs.setString(_fastStartKey, fastStartedAt!.toIso8601String());
    notifyListeners();
  }

  Future<FastEntry?> endFast() async {
    final started = fastStartedAt;
    if (started == null) return null;
    final entry = FastEntry(startedAt: started, endedAt: DateTime.now());
    fastHistory.insert(0, entry);
    fastHistory = fastHistory.take(30).toList();
    fastStartedAt = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_fastStartKey);
    await prefs.setStringList(
      _fastHistoryKey,
      fastHistory.map((value) => jsonEncode(value.toJson())).toList(),
    );
    notifyListeners();
    return entry;
  }

  Future<void> toggleFavorite(String recipeId) async {
    if (!favoriteRecipes.add(recipeId)) favoriteRecipes.remove(recipeId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, favoriteRecipes.toList());
    notifyListeners();
  }

  Future<void> addShoppingItems(Iterable<String> items) async {
    for (final item in items) {
      if (!shoppingList.contains(item)) shoppingList.add(item);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_shoppingKey, shoppingList);
    notifyListeners();
  }

  Future<void> removeShoppingItem(String item) async {
    shoppingList.remove(item);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_shoppingKey, shoppingList);
    notifyListeners();
  }

  Future<void> clearShoppingList() async {
    shoppingList.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_shoppingKey);
    notifyListeners();
  }

  Future<void> addWeight(double value) async {
    weightHistory.insert(0, value);
    weightHistory = weightHistory.take(60).toList();
    currentWeightKg = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _weightsKey, weightHistory.map((v) => '$v').toList());
    await prefs.setDouble(_weightNowKey, currentWeightKg);
    notifyListeners();
  }

  Future<void> adjustWeight(double delta) =>
      addWeight((currentWeightKg + delta).clamp(25.0, 350.0));

  Future<void> setWeightGoal(double value) async {
    goalWeightKg = value.clamp(25.0, 350.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_weightGoalKey, goalWeightKg);
    notifyListeners();
  }

  Future<void> configureMeasurements(
      {required double weight,
      required double targetWeight,
      required double height,
      required int age,
      required String sex,
      required String activity,
      required String goal,
      required String rate}) async {
    final prefs = await SharedPreferences.getInstance();
    currentWeightKg = prefs.getDouble(_weightNowKey) ?? weight;
    goalWeightKg = prefs.getDouble(_weightGoalKey) ?? targetWeight;
    heightCm = height;
    ageYears = age;
    this.sex = sex;
    activityLevel = activity;
    weightGoal = goal;
    goalRate = rate;
    await prefs.setDouble(_weightNowKey, currentWeightKg);
    await prefs.setDouble(_weightGoalKey, goalWeightKg);
    notifyListeners();
  }

  int get recalculatedCalorieTarget {
    final bmr = sex == 'male'
        ? 10 * currentWeightKg + 6.25 * heightCm - 5 * ageYears + 5
        : 10 * currentWeightKg + 6.25 * heightCm - 5 * ageYears - 161;
    const factors = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
      'very_active': 1.9
    };
    final maintenance = bmr * (factors[activityLevel] ?? 1.375);
    const deficits = {'slow': 250, 'moderate': 500, 'fast': 750};
    const surpluses = {'slow': 150, 'moderate': 300, 'fast': 500};
    final target = switch (weightGoal) {
      'lose_weight' => maintenance - (deficits[goalRate] ?? 500),
      'gain_weight' ||
      'build_muscle' =>
        maintenance + (surpluses[goalRate] ?? 300),
      _ => maintenance,
    };
    return target.round().clamp(1200, 6000);
  }

  Future<void> addCustomActivity(String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty ||
        customActivities
            .any((v) => v.toLowerCase() == normalized.toLowerCase())) {
      return;
    }
    customActivities = [...customActivities, normalized]
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_customActivitiesKey, customActivities);
    notifyListeners();
  }

  Future<void> finishRecipeOnboarding(String level,
      {String diet = 'No preference', String time = 'Any time'}) async {
    cookingLevel = level;
    recipeDiet = diet;
    recipeCookingTime = time;
    recipesOnboarded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_recipeWelcomeKey, true);
    await prefs.setString(_recipeLevelKey, level);
    await prefs.setString(_recipeDietKey, diet);
    await prefs.setString(_recipeTimeKey, time);
    notifyListeners();
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static List<T> _readJsonList<T>(
    List<String>? values,
    T Function(Map<String, dynamic>) parse,
  ) {
    if (values == null) return [];
    return values
        .map((value) {
          try {
            return parse(jsonDecode(value) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<T>()
        .toList();
  }
}

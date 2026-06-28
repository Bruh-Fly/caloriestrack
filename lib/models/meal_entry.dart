import 'food_result.dart';

class MealEntry {
  final String id;
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String serving;
  final DateTime timestamp;
  final String? imagePath;

  const MealEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.serving,
    required this.timestamp,
    this.imagePath,
  });

  factory MealEntry.fromFoodResult(
    FoodResult result, {
    required String id,
    required DateTime timestamp,
    String? imagePath,
  }) {
    return MealEntry(
      id:        id,
      name:      result.name,
      calories:  result.calories,
      protein:   result.protein,
      carbs:     result.carbs,
      fat:       result.fat,
      serving:   result.serving,
      timestamp: timestamp,
      imagePath: imagePath,
    );
  }

  factory MealEntry.fromJson(Map<String, dynamic> json) {
    return MealEntry(
      id:        json['id']        as String,
      name:      json['name']      as String,
      calories:  (json['calories'] as num).toInt(),
      protein:   (json['protein']  as num).toDouble(),
      carbs:     (json['carbs']    as num).toDouble(),
      fat:       (json['fat']      as num).toDouble(),
      serving:   json['serving']   as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      imagePath: json['imagePath'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':        id,
    'name':      name,
    'calories':  calories,
    'protein':   protein,
    'carbs':     carbs,
    'fat':       fat,
    'serving':   serving,
    'timestamp': timestamp.toIso8601String(),
    'imagePath': imagePath,
  };
}

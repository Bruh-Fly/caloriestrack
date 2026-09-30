class FoodResult {
  final String? analysisId;
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String serving;
  final String? description;

  const FoodResult({
    this.analysisId,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.serving,
    this.description,
  });

  FoodResult copyWith({
    String? name,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    String? serving,
    String? description,
  }) =>
      FoodResult(
        analysisId: analysisId,
        name: name ?? this.name,
        calories: calories ?? this.calories,
        protein: protein ?? this.protein,
        carbs: carbs ?? this.carbs,
        fat: fat ?? this.fat,
        serving: serving ?? this.serving,
        description: description ?? this.description,
      );

  factory FoodResult.fromJson(Map<String, dynamic> json) {
    return FoodResult(
      analysisId:  json['analysis_id'] as String?,
      name:        json['name']        as String? ?? 'Món ăn không xác định',
      calories:    (json['calories']   as num?)?.toInt()    ?? 0,
      protein:     (json['protein']    as num?)?.toDouble() ?? 0.0,
      carbs:       (json['carbs']      as num?)?.toDouble() ?? 0.0,
      fat:         (json['fat']        as num?)?.toDouble() ?? 0.0,
      serving:     json['serving']     as String? ?? '1 khẩu phần',
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'analysis_id': analysisId,
    'name':        name,
    'calories':    calories,
    'protein':     protein,
    'carbs':       carbs,
    'fat':         fat,
    'serving':     serving,
    'description': description,
  };

  // Calories from each macro (for percentage display)
  double get caloriesFromProtein => protein * 4;
  double get caloriesFromCarbs   => carbs * 4;
  double get caloriesFromFat     => fat * 9;

  double get proteinPercent => calories > 0 ? (caloriesFromProtein / calories).clamp(0.0, 1.0) : 0;
  double get carbsPercent   => calories > 0 ? (caloriesFromCarbs   / calories).clamp(0.0, 1.0) : 0;
  double get fatPercent     => calories > 0 ? (caloriesFromFat     / calories).clamp(0.0, 1.0) : 0;
}

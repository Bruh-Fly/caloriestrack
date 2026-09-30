class UserProfile {
  final String uid;
  final String name;
  final String goal;       // lose_weight | eat_healthier | gain_weight | build_muscle | other
  final String rate;       // slow | moderate | fast
  final String sex;        // male | female
  final int age;
  final double height;     // cm
  final double weight;     // kg
  final double targetWeight;
  final String activity;   // sedentary | light | moderate | active | very_active
  final String diet;       // none | vegetarian | vegan | gluten_free | dairy_free
  final int mealsPerDay;
  final String exercise;   // never | 1_2 | 3_4 | 5_plus
  final String sleep;      // less_6 | 6_7 | 7_8 | 8_plus
  final int dailyCalories;
  final double proteinGoal;
  final double carbsGoal;
  final double fatGoal;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.goal,
    this.rate = 'moderate',
    required this.sex,
    required this.age,
    required this.height,
    required this.weight,
    required this.targetWeight,
    required this.activity,
    required this.diet,
    required this.mealsPerDay,
    required this.exercise,
    required this.sleep,
    required this.dailyCalories,
    required this.proteinGoal,
    required this.carbsGoal,
    required this.fatGoal,
    required this.email,
    this.photoUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'uid':           uid,
    'name':          name,
    'goal':          goal,
    'rate':          rate,
    'sex':           sex,
    'age':           age,
    'height':        height,
    'weight':        weight,
    'targetWeight':  targetWeight,
    'activity':      activity,
    'diet':          diet,
    'mealsPerDay':   mealsPerDay,
    'exercise':      exercise,
    'sleep':         sleep,
    'dailyCalories': dailyCalories,
    'proteinGoal':   proteinGoal,
    'carbsGoal':     carbsGoal,
    'fatGoal':       fatGoal,
    'email':         email,
    'photoUrl':      photoUrl,
    'createdAt':     createdAt.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    uid:           j['uid']           as String,
    name:          j['name']          as String,
    goal:          j['goal']          as String,
    rate:          j['rate']          as String? ?? 'moderate',
    sex:           j['sex']           as String,
    age:           (j['age']          as num).toInt(),
    height:        (j['height']       as num).toDouble(),
    weight:        (j['weight']       as num).toDouble(),
    targetWeight:  (j['targetWeight'] as num).toDouble(),
    activity:      j['activity']      as String,
    diet:          j['diet']          as String,
    mealsPerDay:   (j['mealsPerDay']  as num).toInt(),
    exercise:      j['exercise']      as String,
    sleep:         j['sleep']         as String,
    dailyCalories: (j['dailyCalories']as num).toInt(),
    proteinGoal:   (j['proteinGoal']  as num).toDouble(),
    carbsGoal:     (j['carbsGoal']    as num).toDouble(),
    fatGoal:       (j['fatGoal']      as num).toDouble(),
    email:         j['email']         as String,
    photoUrl:      j['photoUrl']      as String?,
    createdAt:     DateTime.parse(j['createdAt'] as String),
  );

  // ── TDEE Calculation (Mifflin-St Jeor) ────────────────────────
  /// Calculates a daily calorie target from the Mifflin–St Jeor BMR equation,
  /// an activity multiplier, and a goal adjustment.
  static int calculateTDEE({
    required String sex,
    required double weight,
    required double height,
    required int age,
    required String activity,
    required String goal,
    String rate = 'moderate',
  }) {
    // BMR
    double bmr = sex == 'male'
        ? 10 * weight + 6.25 * height - 5 * age + 5
        : 10 * weight + 6.25 * height - 5 * age - 161;

    // Activity multiplier
    const factors = {
      'sedentary': 1.2,
      'light':     1.375,
      'moderate':  1.55,
      'active':    1.725,
      'very_active': 1.9,
    };
    final tdee = bmr * (factors[activity] ?? 1.375);

    // Goal adjustment
    const deficits = {'slow': 250, 'moderate': 500, 'fast': 750};
    const surpluses = {'slow': 150, 'moderate': 300, 'fast': 500};
    switch (goal) {
      case 'lose_weight':   return (tdee - (deficits[rate] ?? 500)).round();
      case 'gain_weight':
      case 'build_muscle': return (tdee + (surpluses[rate] ?? 300)).round();
      default:              return tdee.round();
    }
  }

  /// Converts goal-specific calorie shares into grams using 4/4/9 kcal per gram.
  static Map<String, double> calculateMacros(int calories, String goal) {
    // Protein: 30%, Carbs: 40%, Fat: 30% (adjust by goal)
    double proteinPct, carbsPct, fatPct;
    switch (goal) {
      case 'lose_weight':
        proteinPct = 0.35; carbsPct = 0.35; fatPct = 0.30;
        break;
      case 'build_muscle':
        proteinPct = 0.35; carbsPct = 0.45; fatPct = 0.20;
        break;
      case 'gain_weight':
        proteinPct = 0.25; carbsPct = 0.50; fatPct = 0.25;
        break;
      default:
        proteinPct = 0.30; carbsPct = 0.40; fatPct = 0.30;
    }
    return {
      'protein': (calories * proteinPct / 4),  // 4 kcal/g
      'carbs':   (calories * carbsPct  / 4),
      'fat':     (calories * fatPct    / 9),   // 9 kcal/g
    };
  }
}

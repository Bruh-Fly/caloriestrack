import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/meal_entry.dart';
import '../providers/app_provider.dart';
import '../services/app_text.dart';
import '../theme/app_theme.dart';

class NutritionItemsScreen extends StatelessWidget {
  const NutritionItemsScreen({super.key, required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: Text(context.tr('Nutrition', 'Dinh dưỡng'))),
      body: Consumer<AppProvider>(
        builder: (context, app, _) {
          final entries = app.mealsForDate(date);
          final groups = <(String, String, String)>[
            ('breakfast', '☕', 'Breakfast'),
            ('lunch', '🍜', 'Lunch'),
            ('dinner', '🥗', 'Dinner'),
            ('snack', '🍎', 'Snacks'),
          ];
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                children: [
                  for (final group in groups)
                    _NutritionMealGroup(
                      date: date,
                      type: group.$1,
                      emoji: group.$2,
                      label: context.tr(group.$3, _mealVietnamese(group.$1)),
                      meals: entries
                          .where(
                            (meal) => group.$1 == 'snack'
                                ? meal.mealType == 'snack' ||
                                      !const [
                                        'breakfast',
                                        'lunch',
                                        'dinner',
                                        'snack',
                                      ].contains(meal.mealType)
                                : meal.mealType == group.$1,
                          )
                          .toList(),
                    ),
                  if (entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 64),
                      child: Text(
                        context.tr(
                          'No meals recorded for this day.',
                          'Chưa có món ăn nào trong ngày này.',
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: palette.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NutritionMealGroup extends StatelessWidget {
  const _NutritionMealGroup({
    required this.date,
    required this.type,
    required this.emoji,
    required this.label,
    required this.meals,
  });
  final DateTime date;
  final String type;
  final String emoji;
  final String label;
  final List<MealEntry> meals;

  @override
  Widget build(BuildContext context) {
    if (meals.isEmpty) return const SizedBox.shrink();
    final palette = context.palette;
    final calories = meals.fold<int>(0, (sum, meal) => sum + meal.calories);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '$calories kcal',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final meal in meals)
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => MealServingEditorScreen(meal: meal),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meal.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            meal.serving,
                            style: TextStyle(color: palette.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${meal.calories} kcal',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 5),
                    Icon(Icons.chevron_right, color: palette.textSecondary),
                  ],
                ),
              ),
            ),
          Divider(height: 1, color: palette.outline),
        ],
      ),
    );
  }
}

class MealServingEditorScreen extends StatefulWidget {
  const MealServingEditorScreen({super.key, required this.meal});
  final MealEntry meal;

  @override
  State<MealServingEditorScreen> createState() =>
      _MealServingEditorScreenState();
}

class _MealServingEditorScreenState extends State<MealServingEditorScreen> {
  late final _ServingInfo _original = _ServingInfo.parse(widget.meal);
  late final TextEditingController _quantity = TextEditingController(
    text: _formatQuantity(_original.quantity),
  );
  late String _unit = _original.unit;
  bool _saving = false;

  List<String> get _units {
    final name = widget.meal.name.toLowerCase();
    final originalUnit = _original.unit.toLowerCase();
    final isEgg =
        RegExp(r'\b(egg|eggs)\b').hasMatch(name) || originalUnit == 'egg';
    final isDrink =
        RegExp(
          r'\b(coffee|tea|water|milk|juice|smoothie|drink|latte|soda)\b',
        ).hasMatch(name) ||
        originalUnit == 'cup' ||
        originalUnit == 'ml';
    final isFruit = RegExp(
      r'\b(apple|banana|orange|pear|peach|avocado)\b',
    ).hasMatch(name);
    final preferred = isEgg
        ? ['egg', 'g']
        : isDrink
        ? ['mL', 'cup']
        : isFruit
        ? ['piece', 'g']
        : ['g', 'serving'];
    return [
      if (!preferred.contains(_original.unit)) _original.unit,
      ...preferred,
    ];
  }

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final quantity = _readQuantity();
    final currentGrams = _original.baseGrams;
    final nextGrams = _isMassUnit(_unit) ? quantity : null;
    final previewRatio = _ratio(quantity);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: Text(context.tr('Edit serving', 'Sửa định lượng'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Text(
                widget.meal.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                context.tr(
                  'Adjust the amount. Calories and macros scale with it.',
                  'Chỉnh lượng ăn; calo và dinh dưỡng sẽ được tính lại tương ứng.',
                ),
                style: TextStyle(color: palette.textSecondary),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _quantity,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: context.tr('Amount', 'Số lượng'),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _unit,
                      decoration: InputDecoration(
                        labelText: context.tr('Unit', 'Đơn vị'),
                        border: const OutlineInputBorder(),
                      ),
                      items: _units
                          .map(
                            (unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(_translatedUnit(context, unit)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        final amount = _readQuantity();
                        final base = amount * _factor(_unit);
                        setState(() {
                          _unit = value;
                          _quantity.text = _formatQuantity(
                            base / _factor(value),
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),
              if (currentGrams != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    '${context.tr('Approximate weight', 'Khối lượng ước tính')}: '
                    '${(nextGrams ?? quantity * _factor(_unit)).round()} ${_isVolumeUnit(_unit) ? 'mL' : 'g'}',
                    style: TextStyle(color: palette.textSecondary),
                  ),
                ),
              const SizedBox(height: 22),
              _nutrientLine(
                context.tr('Calories', 'Calo'),
                '${(widget.meal.calories * previewRatio).round()} kcal',
              ),
              _nutrientLine(
                context.tr('Protein', 'Đạm'),
                '${(widget.meal.protein * previewRatio).toStringAsFixed(1)} g',
              ),
              _nutrientLine(
                context.tr('Carbs', 'Tinh bột'),
                '${(widget.meal.carbs * previewRatio).toStringAsFixed(1)} g',
              ),
              _nutrientLine(
                context.tr('Fat', 'Chất béo'),
                '${(widget.meal.fat * previewRatio).toStringAsFixed(1)} g',
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving || quantity <= 0 ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.tr('Save changes', 'Lưu thay đổi')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nutrientLine(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );

  double _readQuantity() =>
      double.tryParse(_quantity.text.trim().replaceAll(',', '.')) ?? 0;

  double _ratio(double quantity) {
    final amount = quantity * _factor(_unit);
    final originalBase =
        _original.baseGrams ?? _original.quantity * _factor(_original.unit);
    return originalBase <= 0 ? 1 : amount / originalBase;
  }

  double _factor(String unit) {
    final normalized = unit.toLowerCase();
    if (normalized == 'g' || normalized == 'ml') return 1;
    if (normalized == 'cup') return 237;
    if (normalized == 'tbsp' || normalized == 'tablespoon') return 15;
    if (normalized == 'tsp' || normalized == 'teaspoon') return 5;
    if (normalized == 'oz') return 28.35;
    if (normalized == 'egg') return _original.massPerUnit ?? 47;
    if (normalized == 'piece')
      return _original.massPerUnit ?? _fruitWeight(widget.meal.name);
    if (normalized == 'serving') return _original.massPerUnit ?? 100;
    return _original.massPerUnit ?? 100;
  }

  bool _isMassUnit(String unit) => unit.toLowerCase() == 'g';
  bool _isVolumeUnit(String unit) =>
      const ['ml', 'cup', 'tbsp', 'tsp'].contains(unit.toLowerCase());

  Future<void> _save() async {
    final quantity = _readQuantity();
    if (quantity <= 0) return;
    final ratio = _ratio(quantity);
    final base = quantity * _factor(_unit);
    final volume = _isVolumeUnit(_unit);
    final unitLabel = _unit == 'egg'
        ? quantity == 1
              ? 'egg'
              : 'eggs'
        : _unit == 'piece'
        ? quantity == 1
              ? 'piece'
              : 'pieces'
        : _unit;
    final serving = _isMassUnit(_unit) || volume
        ? '${_formatQuantity(quantity)} $unitLabel'
        : '${_formatQuantity(quantity)} $unitLabel (${base.round()} ${volume ? 'mL' : 'g'})';
    final updated = MealEntry(
      id: widget.meal.id,
      itemId: widget.meal.itemId,
      mealId: widget.meal.mealId,
      name: widget.meal.name,
      calories: (widget.meal.calories * ratio).round(),
      protein: widget.meal.protein * ratio,
      carbs: widget.meal.carbs * ratio,
      fat: widget.meal.fat * ratio,
      serving: serving,
      servingGrams: volume ? null : base,
      timestamp: widget.meal.timestamp,
      imagePath: widget.meal.imagePath,
      mealType: widget.meal.mealType,
    );
    setState(() => _saving = true);
    try {
      await context.read<AppProvider>().updateMealEntry(updated);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Could not save the serving change.',
              'Không thể lưu thay đổi định lượng. Hãy kiểm tra kết nối rồi thử lại.',
            ),
          ),
        ),
      );
    }
  }
}

class _ServingInfo {
  const _ServingInfo(
    this.quantity,
    this.unit,
    this.baseGrams,
    this.massPerUnit,
  );
  final double quantity;
  final String unit;
  final double? baseGrams;
  final double? massPerUnit;

  factory _ServingInfo.parse(MealEntry meal) {
    final value = meal.serving.trim();
    final quantityMatch = RegExp(
      r'^(\d+(?:[.,]\d+)?)\s*([^,(]*)',
    ).firstMatch(value);
    final quantity = quantityMatch == null
        ? 1.0
        : double.tryParse(quantityMatch.group(1)!.replaceAll(',', '.')) ?? 1;
    var unit = quantityMatch?.group(2)?.trim() ?? '';
    if (unit.isEmpty) unit = 'serving';
    final parenthetical = RegExp(
      r'\((\d+(?:[.,]\d+)?)\s*(g|ml)\)',
      caseSensitive: false,
    ).firstMatch(value);
    final base =
        meal.servingGrams ??
        (parenthetical == null
            ? null
            : double.tryParse(parenthetical.group(1)!.replaceAll(',', '.')));
    final massPerUnit = base == null || quantity <= 0 ? null : base / quantity;
    final lower = unit.toLowerCase();
    if (lower == 'grams' || lower == 'gram') unit = 'g';
    if (lower == 'milliliters' || lower == 'milliliter' || lower == 'ml') {
      unit = 'mL';
    }
    if (lower == 'eggs') unit = 'egg';
    if (lower == 'pieces') unit = 'piece';
    if (lower == 'cups') unit = 'cup';
    if (lower == 'tablespoons' || lower == 'tablespoon') unit = 'tbsp';
    if (lower == 'teaspoons' || lower == 'teaspoon') unit = 'tsp';
    if (lower == 'ounce' || lower == 'ounces') unit = 'oz';
    if (lower == 'whole' || lower == 'wholes') {
      final name = meal.name.toLowerCase();
      if (RegExp(r'\b(egg|eggs)\b').hasMatch(name)) {
        unit = 'egg';
      } else if (RegExp(
        r'\b(apple|banana|orange|pear|peach|avocado)\b',
      ).hasMatch(name)) {
        unit = 'piece';
      }
    }
    return _ServingInfo(quantity, unit, base, massPerUnit);
  }
}

class NutritionDetailsScreen extends StatelessWidget {
  const NutritionDetailsScreen({super.key, required this.date});
  final DateTime date;

  static const _shares = <String, double>{
    'breakfast': .30,
    'lunch': .40,
    'dinner': .25,
    'snack': .05,
  };

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: Text(_dateTitle(context, date))),
      body: Consumer<AppProvider>(
        builder: (context, app, _) {
          final meals = app.mealsForDate(date);
          final calories = meals.fold<int>(
            0,
            (sum, meal) => sum + meal.calories,
          );
          final protein = meals.fold<double>(
            0,
            (sum, meal) => sum + meal.protein,
          );
          final carbs = meals.fold<double>(0, (sum, meal) => sum + meal.carbs);
          final fat = meals.fold<double>(0, (sum, meal) => sum + meal.fat);
          final daily = [
            (
              'Calories',
              context.tr('Calories', 'Calo'),
              calories.toDouble(),
              app.calorieGoal.toDouble(),
              'kcal',
            ),
            (
              'Carbs',
              context.tr('Carbs', 'Tinh bột'),
              carbs,
              app.carbsGoal,
              'g',
            ),
            (
              'Protein',
              context.tr('Protein', 'Đạm'),
              protein,
              app.proteinGoal,
              'g',
            ),
            ('Fat', context.tr('Fat', 'Chất béo'), fat, app.fatGoal, 'g'),
          ];
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    context.tr('Goal', 'Mục tiêu'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  _surface(
                    context,
                    Column(
                      children: [
                        for (final row in daily)
                          _progressRow(context, row.$2, row.$3, row.$4, row.$5),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.tr('Meals', 'Các bữa ăn'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  for (final type in _shares.keys)
                    _mealProgress(context, app, meals, type, _shares[type]!),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _mealProgress(
    BuildContext context,
    AppProvider app,
    List<MealEntry> all,
    String type,
    double share,
  ) {
    final palette = context.palette;
    final meals = all
        .where(
          (meal) => type == 'snack'
              ? meal.mealType == 'snack' ||
                    !const [
                      'breakfast',
                      'lunch',
                      'dinner',
                      'snack',
                    ].contains(meal.mealType)
              : meal.mealType == type,
        )
        .toList();
    final goalKcal = (app.calorieGoal * share).round();
    final eaten = meals.fold<int>(0, (sum, meal) => sum + meal.calories);
    final macros = [
      (
        context.tr('Calories', 'Calo'),
        eaten.toDouble(),
        goalKcal.toDouble(),
        'kcal',
      ),
      (
        context.tr('Carbs', 'Tinh bột'),
        meals.fold<double>(0, (s, m) => s + m.carbs),
        app.carbsGoal * share,
        'g',
      ),
      (
        context.tr('Protein', 'Đạm'),
        meals.fold<double>(0, (s, m) => s + m.protein),
        app.proteinGoal * share,
        'g',
      ),
      (
        context.tr('Fat', 'Chất béo'),
        meals.fold<double>(0, (s, m) => s + m.fat),
        app.fatGoal * share,
        'g',
      ),
    ];
    final title = switch (type) {
      'breakfast' => context.tr('Breakfast', 'Bữa sáng'),
      'lunch' => context.tr('Lunch', 'Bữa trưa'),
      'dinner' => context.tr('Dinner', 'Bữa tối'),
      _ => context.tr('Snacks', 'Bữa phụ'),
    };
    final emoji = switch (type) {
      'breakfast' => '☕',
      'lunch' => '🍜',
      'dinner' => '🥗',
      _ => '🍎',
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.outline),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 25)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              Text(
                '$eaten / $goalKcal kcal',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final row in macros)
            _progressRow(context, row.$1, row.$2, row.$3, row.$4),
          if (meals.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  context.tr('No food logged yet.', 'Chưa ghi món ăn.'),
                  style: TextStyle(color: palette.textSecondary, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _surface(BuildContext context, Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.palette.surface,
      border: Border.all(color: context.palette.outline),
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );

  Widget _progressRow(
    BuildContext context,
    String label,
    double value,
    double goal,
    String unit,
  ) {
    final palette = context.palette;
    final formatter = (double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 1);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: palette.textSecondary),
                ),
              ),
              Text('${formatter(value)} / ${formatter(goal)} $unit'),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: goal <= 0 ? 0 : (value / goal).clamp(0.0, 1.0),
            minHeight: 7,
            borderRadius: BorderRadius.circular(6),
            color: palette.brand,
            backgroundColor: palette.surfaceRaised,
          ),
        ],
      ),
    );
  }
}

String _mealVietnamese(String meal) => switch (meal) {
  'breakfast' => 'Bữa sáng',
  'lunch' => 'Bữa trưa',
  'dinner' => 'Bữa tối',
  _ => 'Bữa phụ',
};

String _translatedUnit(BuildContext context, String unit) => switch (unit) {
  'egg' => context.tr('Eggs', 'Quả trứng'),
  'piece' => context.tr('Pieces', 'Quả/miếng'),
  'serving' => context.tr('Serving', 'Khẩu phần'),
  'cup' => context.tr('Cup', 'Cốc'),
  'tbsp' => context.tr('Tablespoons', 'Muỗng canh'),
  'tsp' => context.tr('Teaspoons', 'Muỗng cà phê'),
  _ => unit,
};

double _fruitWeight(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('banana')) return 118;
  if (lower.contains('apple')) return 182;
  if (lower.contains('orange')) return 130;
  if (lower.contains('pear')) return 178;
  if (lower.contains('peach')) return 150;
  if (lower.contains('avocado')) return 150;
  return 100;
}

String _formatQuantity(double value) => value == value.roundToDouble()
    ? value.round().toString()
    : value.toStringAsFixed(1);

String _dateTitle(BuildContext context, DateTime date) =>
    '${context.tr('Today', 'Hôm nay')} · ${date.day}/${date.month}/${date.year}';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/lifestyle_provider.dart';
import '../theme/app_theme.dart';
import 'track_food_screen.dart';
import 'camera_screen.dart';
import '../services/share_card_service.dart';
import '../services/app_text.dart';

class DaySummaryScreen extends StatefulWidget {
  const DaySummaryScreen(
      {super.key, required this.date, this.initialMealType = 'breakfast'});
  final DateTime date;
  final String initialMealType;
  @override
  State<DaySummaryScreen> createState() => _DaySummaryScreenState();
}

class _DaySummaryScreenState extends State<DaySummaryScreen> {
  late String _meal = widget.initialMealType;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Consumer2<AppProvider, LifestyleProvider>(
        builder: (context, app, life, _) {
      final meals = app.mealsForDate(widget.date);
      final kcal = meals.fold<int>(0, (s, m) => s + m.calories);
      final protein = meals.fold<double>(0, (s, m) => s + m.protein);
      final carbs = meals.fold<double>(0, (s, m) => s + m.carbs);
      final fat = meals.fold<double>(0, (s, m) => s + m.fat);
      final burned = widget.date.year == DateTime.now().year &&
              widget.date.month == DateTime.now().month &&
              widget.date.day == DateTime.now().day
          ? life.activityCaloriesToday
          : 0;
      final daily = meals;
      final selectedMeals = daily.where((m) => m.mealType == _meal).toList();
      final mealCalories = selectedMeals.fold<int>(0, (s, m) => s + m.calories);
      final mealProtein =
          selectedMeals.fold<double>(0, (s, m) => s + m.protein);
      final mealCarbs = selectedMeals.fold<double>(0, (s, m) => s + m.carbs);
      final mealFat = selectedMeals.fold<double>(0, (s, m) => s + m.fat);
      final photoPaths =
          selectedMeals.map((m) => m.imagePath).whereType<String>().toList();
      final photoPath = photoPaths.isEmpty ? null : photoPaths.first;
      final date =
          '${widget.date.day.toString().padLeft(2, '0')}/${widget.date.month.toString().padLeft(2, '0')}/${widget.date.year}';
      return Scaffold(
          backgroundColor: p.background,
          appBar: AppBar(title: Text(date)),
          body: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Text(_localizedMeal(context, _meal),
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CameraScreen(mealType: _meal))),
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    height: 190,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                        color: p.brandSoft,
                        border: Border.all(color: p.outline),
                        borderRadius: BorderRadius.circular(22)),
                    child: Stack(fit: StackFit.expand, children: [
                      if (photoPath != null && File(photoPath).existsSync())
                        Image.file(File(photoPath), fit: BoxFit.cover)
                      else
                        Center(
                            child: Text(
                                _meal == 'breakfast'
                                    ? '☕'
                                    : _meal == 'lunch'
                                        ? '🍜'
                                        : _meal == 'dinner'
                                            ? '🥗'
                                            : '🍎',
                                style: const TextStyle(fontSize: 74))),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(Icons.camera_alt_outlined,
                                color: p.brand)),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                _panel(
                    p,
                    Row(children: [
                      Expanded(
                          child: _mealStat(context.tr('Calories', 'Calo'),
                              '$mealCalories kcal')),
                      Expanded(
                          child: _mealStat(context.tr('Carbs', 'Tinh bột'),
                              '${mealCarbs.toStringAsFixed(1)} g')),
                      Expanded(
                          child: _mealStat(context.tr('Protein', 'Đạm'),
                              '${mealProtein.toStringAsFixed(1)} g')),
                      Expanded(
                          child: _mealStat(context.tr('Fat', 'Chất béo'),
                              '${mealFat.toStringAsFixed(1)} g')),
                    ])),
                const SizedBox(height: 15),
                Text(context.tr('Goal', 'Mục tiêu'),
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                _panel(
                    p,
                    Column(children: [
                      _bar(p, 'Calories', kcal.toDouble(),
                          app.calorieGoal.toDouble(), 'kcal'),
                      _bar(p, 'Carbs', carbs, app.carbsGoal, 'g'),
                      _bar(p, 'Protein', protein, app.proteinGoal, 'g'),
                      _bar(p, 'Fat', fat, app.fatGoal, 'g')
                    ])),
                const SizedBox(height: 25),
                Text(context.tr('Meals', 'Các bữa ăn'),
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                _panel(
                    p,
                    Wrap(spacing: 7, runSpacing: 7, children: [
                      for (final x in [
                        ('breakfast', '☕'),
                        ('lunch', '🍜'),
                        ('dinner', '🥗'),
                        ('snack', '🍎')
                      ])
                        ChoiceChip(
                            selected: _meal == x.$1,
                            label: Text(
                                '${x.$2} ${_localizedMeal(context, x.$1)}'),
                            onSelected: (_) => setState(() => _meal = x.$1),
                            selectedColor: p.brandSoft,
                            side: BorderSide(
                                color: _meal == x.$1 ? p.brand : p.outline))
                    ])),
                const SizedBox(height: 12),
                ...selectedMeals.map((m) => _panel(
                    p,
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            if (m.imagePath != null &&
                                File(m.imagePath!).existsSync())
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(File(m.imagePath!),
                                      width: 76, height: 76, fit: BoxFit.cover))
                            else
                              Container(
                                  width: 76,
                                  height: 76,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      color: p.brandSoft,
                                      borderRadius: BorderRadius.circular(14)),
                                  child: Text(foodEmoji(m.name),
                                      style: const TextStyle(fontSize: 32))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(m.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 17)),
                                  Text(m.serving,
                                      style: TextStyle(color: p.textSecondary)),
                                  const SizedBox(height: 6),
                                  Text('${m.calories} kcal',
                                      style: TextStyle(
                                          color: p.brand,
                                          fontWeight: FontWeight.w700)),
                                ])),
                          ]),
                          const Divider(height: 24),
                          _fact(p, 'Protein',
                              '${m.protein.toStringAsFixed(1)} g'),
                          _fact(p, 'Carbs', '${m.carbs.toStringAsFixed(1)} g'),
                          _fact(
                              p, 'Total fat', '${m.fat.toStringAsFixed(1)} g'),
                        ]))),
                if (selectedMeals.isEmpty)
                  _panel(
                      p,
                      const Padding(
                          padding: EdgeInsets.all(14),
                          child: Text('Chưa ghi món ăn cho bữa này.'))),
                if (selectedMeals.isEmpty)
                  ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  TrackFoodScreen(mealType: _meal))),
                      icon: const Icon(Icons.add),
                      label: Text(context.tr('Track now', 'Ghi món ngay')))
                else ...[
                  OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  TrackFoodScreen(mealType: _meal))),
                      icon: const Icon(Icons.add),
                      label: Text(context.tr('Add more', 'Thêm món'))),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => ShareCardService.shareMeal(
                        title: '${mealLabel(_meal)} · $date',
                        meals: selectedMeals,
                        imagePath: photoPath),
                    icon: const Icon(Icons.ios_share),
                    label: Text(context.tr('Share to Locket / apps',
                        'Chia sẻ lên Locket / ứng dụng')),
                  ),
                ],
                const SizedBox(height: 24),
                Text(context.tr('Nutrition facts', 'Thông tin dinh dưỡng'),
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                _panel(
                    p,
                    Column(children: [
                      _fact(p, 'Calories', '$kcal kcal'),
                      _fact(p, 'Protein', '${protein.toStringAsFixed(1)} g'),
                      _fact(p, 'Carbs', '${carbs.toStringAsFixed(1)} g'),
                      _fact(p, 'Total fat', '${fat.toStringAsFixed(1)} g'),
                      _fact(p, 'Activity calories burned', '$burned kcal'),
                      _fact(p, 'Remaining calories',
                          '${(app.calorieGoal - kcal).clamp(0, 99999)} kcal')
                    ])),
                if (meals.isEmpty)
                  Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text('Chưa có dữ liệu dinh dưỡng cho ngày này.',
                          style: TextStyle(color: p.textSecondary))),
              ]));
    });
  }

  String _localizedMeal(BuildContext context, String type) => switch (type) {
        'breakfast' => context.tr('Breakfast', 'Bữa sáng'),
        'lunch' => context.tr('Lunch', 'Bữa trưa'),
        'dinner' => context.tr('Dinner', 'Bữa tối'),
        _ => context.tr('Snacks', 'Bữa phụ'),
      };

  Widget _mealStat(String label, String value) => Column(children: [
        Text(value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(label,
            style:
                TextStyle(color: context.palette.textSecondary, fontSize: 11)),
      ]);

  Widget _panel(dynamic p, Widget child) => Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: p.surface,
          border: Border.all(color: p.outline),
          borderRadius: BorderRadius.circular(20)),
      child: child);
  Widget _bar(dynamic p, String label, double value, double goal, String unit) {
    final progress = goal <= 0 ? 0.0 : (value / goal).clamp(0.0, 1.0);
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(children: [
          Row(children: [
            Expanded(
                child: Text(label, style: TextStyle(color: p.textSecondary))),
            Text(
                '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)} / ${goal.toStringAsFixed(goal % 1 == 0 ? 0 : 1)} $unit')
          ]),
          const SizedBox(height: 7),
          LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              borderRadius: BorderRadius.circular(8),
              color: p.brand,
              backgroundColor: p.surfaceRaised)
        ]));
  }

  Widget _fact(dynamic p, String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(color: p.textSecondary))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700))
      ]));
}

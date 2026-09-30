import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/lifestyle_provider.dart';
import '../models/user_profile.dart';
import '../services/health_connect_service.dart';
import '../theme/app_theme.dart';
import '../services/app_text.dart';
import 'fasting_screen.dart';
import 'history_screen.dart';
import 'track_food_screen.dart';
import 'day_summary_screen.dart';
import '../widgets/meal_card.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late DateTime _selectedDate = _day(DateTime.now());

  static DateTime _day(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final p = context.palette;
        final life = context.watch<LifestyleProvider>();
        final meals = provider.allMeals
            .where((meal) => _day(meal.timestamp) == _selectedDate)
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        final calories = meals.fold<int>(0, (sum, meal) => sum + meal.calories);
        final protein =
            meals.fold<double>(0, (sum, meal) => sum + meal.protein);
        final carbs = meals.fold<double>(0, (sum, meal) => sum + meal.carbs);
        final fat = meals.fold<double>(0, (sum, meal) => sum + meal.fat);
        final remaining = (provider.calorieGoal - calories).clamp(0, 99999);
        final burned = _selectedDate == _day(DateTime.now())
            ? life.activityCaloriesToday
            : 0;
        final dateLabel = _dateLabel(_selectedDate);

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.tr('Today', 'Hôm nay'),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontSize: 29)),
                          Text(dateLabel,
                              style: TextStyle(
                                  color: p.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const HistoryScreen())),
                        icon: Icon(Icons.calendar_month_outlined,
                            color: p.textPrimary)),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
                child: _WeekStrip(
                    selected: _selectedDate,
                    onSelect: (date) => setState(() => _selectedDate = date))),
            SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
              child: Row(children: [
                Expanded(
                    child: InkWell(
                        onTap: () => _openDaySummary(context),
                        child: Text(context.tr('Summary', 'Tổng quan'),
                            style: Theme.of(context).textTheme.titleLarge))),
                TextButton(
                    onPressed: () => _openDaySummary(context),
                    child: Text(context.tr('Details', 'Chi tiết')))
              ]),
            )),
            SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: InkWell(
                  onTap: () => _openDaySummary(context),
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                      padding: const EdgeInsets.all(17),
                      decoration: BoxDecoration(
                          color: p.surface,
                          border: Border.all(color: p.outline),
                          borderRadius: BorderRadius.circular(22)),
                      child: Column(children: [
                        Row(children: [
                          Expanded(
                              child: _CalorieStat(
                                  label: context.tr('Eaten', 'Đã nạp'),
                                  value: calories,
                                  color: p.textPrimary)),
                          SizedBox(
                              width: 125,
                              height: 125,
                              child:
                                  Stack(alignment: Alignment.center, children: [
                                SizedBox(
                                  width: 112,
                                  height: 112,
                                  child: CircularProgressIndicator(
                                    value: provider.calorieGoal <= 0
                                        ? 0
                                        : (calories / provider.calorieGoal)
                                            .clamp(0.0, 1.0),
                                    strokeWidth: 9,
                                    backgroundColor: p.surfaceRaised,
                                    color: p.brand,
                                  ),
                                ),
                                Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('$remaining',
                                          style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w800,
                                              color: p.textPrimary)),
                                      Text(context.tr('Remaining', 'Còn lại'),
                                          style: TextStyle(
                                              color: p.textSecondary,
                                              fontSize: 11)),
                                    ]),
                              ])),
                          Expanded(
                              child: _CalorieStat(
                                  label: context.tr('Burned', 'Đã đốt'),
                                  value: burned,
                                  color: p.textPrimary))
                        ]),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(
                              child: _SummaryMacro(
                                  label: 'Carbs',
                                  value: carbs,
                                  goal: provider.carbsGoal,
                                  color: p.carbs)),
                          Expanded(
                              child: _SummaryMacro(
                                  label: 'Protein',
                                  value: protein,
                                  goal: provider.proteinGoal,
                                  color: p.protein)),
                          Expanded(
                              child: _SummaryMacro(
                                  label: 'Fat',
                                  value: fat,
                                  goal: provider.fatGoal,
                                  color: p.fat))
                        ])
                      ]))),
            )),
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(children: [
                      Expanded(
                          child: Text(context.tr('Nutrition', 'Dinh dưỡng'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontSize: 17))),
                      TextButton(
                          onPressed: () => _openDaySummary(context),
                          child: Text(context.tr('More', 'Thêm')))
                    ]))),
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 5),
                        decoration: BoxDecoration(
                            color: p.surface,
                            borderRadius: BorderRadius.circular(22)),
                        child: Column(children: [
                          for (final item in [
                            (
                              'breakfast',
                              context.tr('Breakfast', 'Bữa sáng'),
                              '☕'
                            ),
                            ('lunch', context.tr('Lunch', 'Bữa trưa'), '🍜'),
                            ('dinner', context.tr('Dinner', 'Bữa tối'), '🥗'),
                            ('snack', context.tr('Snacks', 'Bữa phụ'), '🍎')
                          ])
                            Builder(builder: (context) {
                              final total = meals
                                  .where((m) => m.mealType == item.$1)
                                  .fold<int>(0, (s, m) => s + m.calories);
                              final foods = meals
                                  .where((m) => m.mealType == item.$1)
                                  .map((m) => m.name)
                                  .take(3)
                                  .join(', ');
                              final mealGoal = _mealCalorieGoal(
                                  provider.calorieGoal, item.$1);
                              return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Text(item.$3,
                                      style: const TextStyle(fontSize: 25)),
                                  title: Text(item.$2,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Text(
                                      '$total / $mealGoal kcal${foods.isEmpty ? '' : '\n$foods'}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: p.textSecondary,
                                          fontSize: 11)),
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => DaySummaryScreen(
                                              date: _selectedDate,
                                              initialMealType: item.$1))),
                                  trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                            tooltip: 'Open ${item.$2}',
                                            onPressed: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) =>
                                                        DaySummaryScreen(
                                                            date: _selectedDate,
                                                            initialMealType:
                                                                item.$1))),
                                            icon: const Icon(
                                                Icons.arrow_forward_ios,
                                                size: 16)),
                                        IconButton(
                                            onPressed: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) =>
                                                        TrackFoodScreen(
                                                            mealType:
                                                                item.$1))),
                                            icon: const Icon(Icons.add_circle,
                                                color: Colors.black, size: 34)),
                                      ]));
                            })
                        ])))),
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: _MeasurementsCard(
                        life: life,
                        onAdjust: (delta) =>
                            _adjustWeight(context, life, provider, delta),
                        onGoal: () => _editWeightGoal(context, life)))),
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Container(
                        padding: const EdgeInsets.all(19),
                        decoration: BoxDecoration(
                            color: p.surface,
                            borderRadius: BorderRadius.circular(22)),
                        child: Column(children: [
                          Text(context.tr('Fasting', 'Nhịn ăn'),
                              style: TextStyle(
                                  fontSize: 19, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(
                              'Manage your fasting routine · plan and track your fasts.',
                              style: TextStyle(color: p.textSecondary)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const FastingScreen())),
                              child: Text(
                                  context.tr('Go to Fasting', 'Mở nhịn ăn')))
                        ])))),
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 23, 20, 0),
                    child: Row(children: [
                      Expanded(
                          child: Text(context.tr('Water', 'Nước'),
                              style: Theme.of(context).textTheme.titleMedium)),
                      Text(
                          '${(life.waterMl / 1000).toStringAsFixed(1)} / ${(life.waterGoalMl / 1000).toStringAsFixed(1)} L',
                          style: TextStyle(color: p.textSecondary))
                    ]))),
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Container(
                        padding: const EdgeInsets.all(17),
                        decoration: BoxDecoration(
                            color: p.surface,
                            borderRadius: BorderRadius.circular(22)),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LinearProgressIndicator(
                                  value: life.waterProgress,
                                  minHeight: 7,
                                  borderRadius: BorderRadius.circular(8),
                                  backgroundColor: p.surfaceRaised,
                                  color: p.brand),
                              const SizedBox(height: 12),
                              Wrap(spacing: 8, runSpacing: 8, children: [
                                for (var i = 0; i < life.waterCupsGoal; i++)
                                  InkWell(
                                      onTap: () => i < life.waterCups
                                          ? life.undoWater()
                                          : life.addWater(),
                                      child: Container(
                                          width: 34,
                                          height: 38,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                              color: i < life.waterCups
                                                  ? p.brandSoft
                                                  : p.surfaceRaised,
                                              borderRadius:
                                                  BorderRadius.circular(11)),
                                          child: Icon(Icons.water_drop_outlined,
                                              size: 18,
                                              color: i < life.waterCups
                                                  ? p.brand
                                                  : p.textSecondary)))
                              ]),
                              Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                      onPressed: () => life.addWater(),
                                      icon: const Icon(Icons.add),
                                      label: const Text('250 ml')))
                            ])))),
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                    child: Row(children: [
                      Expanded(
                          child: Text(context.tr('Activities', 'Hoạt động'),
                              style: Theme.of(context).textTheme.titleMedium)),
                      TextButton(
                          onPressed: () => _addActivity(context, life),
                          child: const Text('More'))
                    ]))),
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                        padding: const EdgeInsets.all(17),
                        decoration: BoxDecoration(
                            color: p.surface,
                            borderRadius: BorderRadius.circular(22)),
                        child: Column(children: [
                          Row(children: [
                            Icon(Icons.directions_walk,
                                color: p.brand, size: 25),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text('${life.steps} Steps',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 17)),
                                  Text('Goal ${life.stepGoal}',
                                      style: TextStyle(
                                          color: p.textSecondary, fontSize: 12))
                                ])),
                            Text('${(life.stepProgress * 100).round()}%',
                                style: TextStyle(
                                    color: p.brand,
                                    fontWeight: FontWeight.w700))
                          ]),
                          const SizedBox(height: 11),
                          LinearProgressIndicator(
                              value: life.stepProgress,
                              minHeight: 7,
                              borderRadius: BorderRadius.circular(8),
                              backgroundColor: p.surfaceRaised,
                              color: p.brand),
                          const SizedBox(height: 7),
                          Row(children: [
                            Text('${life.activityCaloriesToday} kcal burned',
                                style: TextStyle(
                                    color: p.textSecondary, fontSize: 12)),
                            const Spacer(),
                            TextButton.icon(
                                onPressed: () => _connectHealth(context, life),
                                icon: const Icon(Icons.link, size: 17),
                                label: const Text('Connect'))
                          ]),
                          TextButton(
                              onPressed: () => _editSteps(context, life),
                              child: const Text('Track steps manually'))
                        ])))),
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Container(
                        padding: const EdgeInsets.all(17),
                        decoration: BoxDecoration(
                            color: p.surface,
                            borderRadius: BorderRadius.circular(22)),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Expanded(
                                    child: Text('How was your day?',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700))),
                                TextButton(
                                    onPressed: () => _editNote(context, life),
                                    child: Text(life.note.isEmpty
                                        ? 'Add Note'
                                        : 'Edit'))
                              ]),
                              Text(
                                  life.mood == 0
                                      ? 'Track your health & feelings'
                                      : [
                                          '',
                                          'Not great',
                                          'Okay',
                                          'Good',
                                          'Very good',
                                          'Excellent'
                                        ][life.mood.clamp(0, 5)],
                                  style: TextStyle(color: p.textSecondary)),
                              if (life.note.isNotEmpty)
                                Padding(
                                    padding: const EdgeInsets.only(top: 7),
                                    child: Text(life.note))
                            ])))),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 27, 22, 12),
                child: Row(
                  children: [
                    Expanded(
                        child: Text('Food diary',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontSize: 17))),
                    Text('${meals.length} món',
                        style: TextStyle(color: p.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ),
            if (meals.isEmpty)
              SliverToBoxAdapter(
                  child: _EmptyMeals(
                      isToday: _selectedDate == _day(DateTime.now())))
            else
              SliverList.builder(
                itemCount: meals.length,
                itemBuilder: (context, index) => MealCard(
                    meal: meals[index],
                    onDelete: () => provider.deleteMeal(meals[index].id)),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 112)),
          ],
        );
      },
    );
  }

  Future<void> _editSteps(BuildContext context, LifestyleProvider life) async {
    final controller = TextEditingController(text: '${life.steps}');
    final result = await showDialog<int>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Track steps manually'),
                content: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(suffixText: 'steps')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy')),
                  TextButton(
                      onPressed: () =>
                          Navigator.pop(context, int.tryParse(controller.text)),
                      child: const Text('Lưu'))
                ]));
    if (result != null) await life.setSteps(result);
  }

  void _openDaySummary(BuildContext context) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => DaySummaryScreen(date: _selectedDate)));

  Future<void> _connectHealth(
      BuildContext context, LifestyleProvider life) async {
    try {
      final steps = await HealthConnectService().connectAndReadTodaySteps();
      if (!context.mounted) return;
      if (steps == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Health Connect permission was not granted.')));
        return;
      }
      await life.setSteps(steps);
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Synced $steps steps from Health Connect.')));
    } catch (error) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Install and set up Health Connect, then connect apps such as Samsung Health inside it.')));
    }
  }

  Future<void> _adjustWeight(BuildContext context, LifestyleProvider life,
      AppProvider app, double delta) async {
    await life.adjustWeight(delta);
    final target = life.recalculatedCalorieTarget;
    await app.updateCalorieGoal(target);
    final macros = UserProfile.calculateMacros(target, life.weightGoal);
    await app.updateMacroGoals(
        protein: macros['protein']!,
        carbs: macros['carbs']!,
        fat: macros['fat']!);
  }

  Future<void> _editWeightGoal(
      BuildContext context, LifestyleProvider life) async {
    final controller =
        TextEditingController(text: life.goalWeightKg.toStringAsFixed(1));
    final result = await showDialog<double>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Weight goal'),
                content: TextField(
                    controller: controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(suffixText: 'kg')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(
                          context,
                          double.tryParse(
                              controller.text.replaceAll(',', '.'))),
                      child: const Text('Save'))
                ]));
    if (result != null && result > 0) await life.setWeightGoal(result);
  }

  Future<void> _addMeal(BuildContext context, AppProvider provider, String type,
      String label) async {
    final name = TextEditingController(),
        kcal = TextEditingController(),
        protein = TextEditingController(),
        carbs = TextEditingController(),
        fat = TextEditingController();
    final values = await showModalBottomSheet<List<String>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.palette.surface,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (sheet) => Padding(
            padding: EdgeInsets.fromLTRB(
                22, 20, 22, MediaQuery.viewInsetsOf(sheet).bottom + 20),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thêm $label',
                      style: Theme.of(sheet).textTheme.titleLarge),
                  const SizedBox(height: 14),
                  TextField(
                      controller: name,
                      decoration:
                          const InputDecoration(labelText: 'Food name')),
                  TextField(
                      controller: kcal,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Calories', suffixText: 'kcal')),
                  Row(children: [
                    Expanded(
                        child: TextField(
                            controller: protein,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'Protein g'))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: TextField(
                            controller: carbs,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'Carbs g'))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: TextField(
                            controller: fat,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'Fat g')))
                  ]),
                  const SizedBox(height: 15),
                  SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                          onPressed: () => Navigator.pop(sheet, [
                                name.text,
                                kcal.text,
                                protein.text,
                                carbs.text,
                                fat.text
                              ]),
                          child: const Text('Add to Diary')))
                ])));
    if (values == null || values[0].trim().isEmpty) return;
    await provider.logManualMeal(
        name: values[0].trim(),
        calories: int.tryParse(values[1]) ?? 0,
        protein: double.tryParse(values[2]) ?? 0,
        carbs: double.tryParse(values[3]) ?? 0,
        fat: double.tryParse(values[4]) ?? 0,
        serving: '1 phần',
        mealType: type);
  }

  Future<void> _addActivity(
      BuildContext context, LifestyleProvider life) async {
    var query = '';
    final activities = [
      ..._activityMet.entries.map((e) => (e.key, e.value)),
      ...life.customActivities.map((e) => (e, 3.5))
    ]..sort((a, b) => a.$1.toLowerCase().compareTo(b.$1.toLowerCase()));
    final chosen = await showModalBottomSheet<(String, double)>(
        context: context,
        isScrollControlled: true,
        builder: (sheet) => StatefulBuilder(
            builder: (context, setSheet) => SafeArea(
                child: SizedBox(
                    height: MediaQuery.sizeOf(context).height * .78,
                    child: Column(children: [
                      Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(children: [
                            Expanded(
                                child: Text('Add activity',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge)),
                            TextButton.icon(
                                onPressed: () =>
                                    _addCustomActivity(context, life),
                                icon: const Icon(Icons.add),
                                label: const Text('Custom'))
                          ])),
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: TextField(
                              decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.search),
                                  hintText: 'Search activities'),
                              onChanged: (v) => setSheet(() => query = v))),
                      Expanded(
                          child: ListView(children: [
                        for (final a in activities.where((e) =>
                            e.$1.toLowerCase().contains(query.toLowerCase())))
                          ListTile(
                              leading: Text(_activityCharacter(a.$1),
                                  style: const TextStyle(fontSize: 23)),
                              title: Text(a.$1),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.pop(sheet, a))
                      ]))
                    ])))));
    if (chosen != null && context.mounted)
      await _recordActivity(context, life, chosen.$1, chosen.$2);
  }

  Future<void> _addCustomActivity(
      BuildContext context, LifestyleProvider life) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Add personal activity'),
                content: TextField(
                    controller: controller,
                    decoration:
                        const InputDecoration(labelText: 'Activity name')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () =>
                          Navigator.pop(context, controller.text.trim()),
                      child: const Text('Add'))
                ]));
    if (name != null && name.isNotEmpty) {
      await life.addCustomActivity(name);
      if (context.mounted) Navigator.pop(context, (name, 3.5));
    }
  }

  Future<void> _recordActivity(BuildContext context, LifestyleProvider life,
      String name, double met) async {
    final minutes = TextEditingController(text: '30'),
        distance = TextEditingController(),
        note = TextEditingController();
    final usesDistance = [
      'walking',
      'running',
      'jogging',
      'cycling',
      'bicycling',
      'swimming'
    ].any((v) => name.toLowerCase().contains(v));
    final result = await showDialog<(int, double?, String)>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(name),
                content: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: minutes,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Duration', suffixText: 'min')),
                  if (usesDistance)
                    TextField(
                        controller: distance,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Distance', suffixText: 'km')),
                  TextField(
                      controller: note,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Note'))
                ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, (
                            int.tryParse(minutes.text) ?? 0,
                            double.tryParse(distance.text),
                            note.text
                          )),
                      child: const Text('Save'))
                ]));
    if (result == null || result.$1 <= 0) return;
    final burned = (met * 3.5 * life.currentWeightKg / 200 * result.$1).round();
    await life.addActivity(
        name: name,
        minutes: result.$1,
        calories: burned,
        distanceKm: result.$2,
        note: result.$3);
  }

  Future<void> _editNote(BuildContext context, LifestyleProvider life) async {
    var mood = life.mood;
    final note = TextEditingController(text: life.note);
    final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (context) => StatefulBuilder(
            builder: (context, setSheet) => Padding(
                padding: EdgeInsets.fromLTRB(
                    22, 20, 22, MediaQuery.viewInsetsOf(context).bottom + 22),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('How was your day?',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Wrap(spacing: 7, children: [
                        for (var i = 1; i <= 5; i++)
                          ChoiceChip(
                              label:
                                  Text(['', '😞', '😐', '🙂', '😊', '🤩'][i]),
                              selected: mood == i,
                              onSelected: (_) => setSheet(() => mood = i))
                      ]),
                      TextField(
                          controller: note,
                          maxLines: 3,
                          decoration:
                              const InputDecoration(labelText: 'Add a note')),
                      const SizedBox(height: 12),
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Save note')))
                    ]))));
    if (result == true) await life.saveNote(mood: mood, note: note.text);
  }

  String _dateLabel(DateTime date) {
    final today = _day(DateTime.now());
    if (date == today) return 'Today';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${date.month}/${date.day}';
  }
}

int _mealCalorieGoal(int dailyGoal, String mealType) {
  final share = switch (mealType) {
    'breakfast' => .25,
    'lunch' => .35,
    'dinner' => .30,
    _ => .10,
  };
  return (dailyGoal * share).round();
}

String _activityCharacter(String name) {
  final value = name.toLowerCase();
  if (value.contains('walk')) return '🚶';
  if (value.contains('run') || value.contains('jog')) return '🏃';
  if (value.contains('cycl') || value.contains('bike')) return '🚴';
  if (value.contains('swim')) return '🏊';
  if (value.contains('yoga')) return '🧘';
  if (value.contains('garden')) return '🧑‍🌾';
  if (value.contains('weight') || value.contains('strength')) return '🏋️';
  if (value.contains('dance')) return '💃';
  return '🤸';
}

class _ProBanner extends StatelessWidget {
  const _ProBanner({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
        color: p.brandSoft,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(19),
            child: Padding(
                padding: const EdgeInsets.all(15),
                child: Row(children: [
                  Icon(Icons.auto_awesome, color: p.brand),
                  const SizedBox(width: 12),
                  const Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Khám phá CaloAI Pro',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        Text('Kế hoạch và công thức phù hợp với bạn',
                            style: TextStyle(fontSize: 11))
                      ])),
                  Icon(Icons.chevron_right, color: p.brand)
                ]))));
  }
}

const Map<String, double> _activityMet = {
  'Aerobics': 6.5,
  'Badminton': 5.5,
  'Basketball': 6.5,
  'Bicycling': 7.5,
  'Boxing': 7.8,
  'Calisthenics': 5.0,
  'Canoeing': 3.5,
  'Cleaning': 3.3,
  'Climbing stairs': 8.0,
  'Cooking': 2.0,
  'Cricket': 4.8,
  'Cycling': 7.5,
  'Dancing': 5.5,
  'Elliptical trainer': 5.0,
  'Fishing': 3.5,
  'Football / Soccer': 7.0,
  'Gardening': 3.8,
  'Golf': 4.8,
  'Gym workout': 5.0,
  'Hiking': 6.0,
  'Horse riding': 4.0,
  'Ice skating': 7.0,
  'Jump rope': 10.0,
  'Kayaking': 5.0,
  'Martial arts': 10.0,
  'Pilates': 3.0,
  'Rowing': 7.0,
  'Running': 9.8,
  'Skiing': 7.0,
  'Skating': 7.0,
  'Sleeping': 0.95,
  'Snowboarding': 5.3,
  'Stair machine': 8.0,
  'Swimming': 6.0,
  'Table tennis': 4.0,
  'Tai chi': 3.0,
  'Tennis': 7.3,
  'Volleyball': 4.0,
  'Walking': 3.5,
  'Water aerobics': 5.5,
  'Weight training': 5.0,
  'Work in yard': 4.0,
  'Yoga': 2.5,
};

class _MeasurementsCard extends StatelessWidget {
  const _MeasurementsCard(
      {required this.life, required this.onAdjust, required this.onGoal});
  final LifestyleProvider life;
  final ValueChanged<double> onAdjust;
  final VoidCallback onGoal;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
            child: Text('Measurements',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800))),
        TextButton(onPressed: onGoal, child: const Text('More'))
      ]),
      Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          decoration: BoxDecoration(
              color: p.surface,
              border: Border.all(color: p.outline, width: 1.5),
              borderRadius: BorderRadius.circular(23)),
          child: Column(children: [
            const Text('Weight',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Goal: ${life.goalWeightKg.toStringAsFixed(1)} kg',
                style: TextStyle(color: p.textSecondary)),
            const SizedBox(height: 15),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              IconButton(
                  onPressed: () => onAdjust(-.1),
                  icon: const Icon(Icons.remove_circle_outline, size: 39)),
              Text('${life.currentWeightKg.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                      fontSize: 30, fontWeight: FontWeight.w800)),
              IconButton(
                  onPressed: () => onAdjust(.1),
                  icon: const Icon(Icons.add_circle_outline, size: 39))
            ]),
            Text('Daily target adjusts with weight',
                style: TextStyle(color: p.textSecondary, fontSize: 11))
          ]))
    ]);
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.selected, required this.onSelect});
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  static const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final today = DateTime.now();
    final monday = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - 1));
    return SizedBox(
      height: 81,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(15, 15, 15, 4),
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final date = monday.add(Duration(days: index));
          final active = date == selected;
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => onSelect(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 48,
              decoration: BoxDecoration(
                color: active ? p.brand : p.surface,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_weekdays[index],
                      style: TextStyle(
                          color: active
                              ? p.onBrand.withOpacity(.72)
                              : p.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('${date.day}',
                      style: TextStyle(
                          color: active ? p.onBrand : p.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CalorieStat extends StatelessWidget {
  const _CalorieStat(
      {required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text('$value',
                style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()])),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    color: context.palette.textSecondary, fontSize: 10)),
          ],
        ),
      );
}

class _MacroLine extends StatelessWidget {
  const _MacroLine(
      {required this.label,
      required this.value,
      required this.goal,
      required this.color});
  final String label;
  final double value;
  final double goal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final progress = goal <= 0 ? 0.0 : (value / goal).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          children: [
            Container(
                width: 9,
                height: 9,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 9),
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600))),
            Text('${value.round()} / ${goal.round()} g',
                style: TextStyle(
                    color: p.textSecondary,
                    fontSize: 12,
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 7,
                color: color,
                backgroundColor: p.surfaceRaised),
          ),
        ),
      ],
    );
  }
}

class _SummaryMacro extends StatelessWidget {
  const _SummaryMacro(
      {required this.label,
      required this.value,
      required this.goal,
      required this.color});
  final String label;
  final double value, goal;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final progress = goal <= 0 ? 0.0 : (value / goal).clamp(0.0, 1.0);
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: p.textSecondary, fontSize: 11)),
          const SizedBox(height: 7),
          ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  color: color,
                  backgroundColor: p.surfaceRaised)),
          const SizedBox(height: 5),
          Text('${value.round()} / ${goal.round()} g',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))
        ]));
  }
}

class _EmptyMeals extends StatelessWidget {
  const _EmptyMeals({required this.isToday});
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 15, 22, 25),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
        decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: Column(
          children: [
            Icon(Icons.restaurant_outlined, color: p.textSecondary, size: 26),
            const SizedBox(height: 10),
            Text(
                isToday
                    ? 'Chưa có món ăn hôm nay'
                    : 'Chưa có món ăn trong ngày này',
                style: TextStyle(
                    color: p.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Chạm dấu + trong Nutrition để ghi lại bữa ăn đầu tiên.',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/lifestyle_provider.dart';
import '../services/share_card_service.dart';
import '../services/app_text.dart';
import '../theme/app_theme.dart';
import 'day_summary_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selected =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Consumer2<AppProvider, LifestyleProvider>(
        builder: (context, app, life, _) {
      final entries = app.mealsForDate(_selected);
      final kcal = entries.fold<int>(0, (sum, entry) => sum + entry.calories);
      final loggedDates = app.mealsGroupedByDate.keys.toSet();
      final dayCount = app.mealsGroupedByDate.length;
      final greenStart = _selected.subtract(const Duration(days: 29));
      final greenCount = app.mealsGroupedByDate.entries
          .where((entry) =>
              !entry.key.isBefore(DateTime(
                  greenStart.year, greenStart.month, greenStart.day)) &&
              !entry.key.isAfter(
                  DateTime(_selected.year, _selected.month, _selected.day)) &&
              entry.value.fold<int>(0, (sum, meal) => sum + meal.calories) <=
                  app.calorieGoal)
          .length;
      final change = life.weightHistory.length > 1
          ? life.weightHistory.first - life.weightHistory.last
          : 0.0;
      final firstWeekday = DateTime(_month.year, _month.month, 1).weekday;
      final days = DateUtils.getDaysInMonth(_month.year, _month.month);
      final cellCount = ((firstWeekday - 1 + days + 6) ~/ 7) * 7;
      return Scaffold(
        backgroundColor: p.background,
        appBar: AppBar(
          title: Text(
              '${_selected.day} ${_monthName(_selected.month)} ${_selected.year}'),
          actions: [
            IconButton(
                tooltip: 'Choose date',
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month_outlined)),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
          children: [
            Row(children: [
              IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon:
                      const Icon(Icons.chevron_left, color: Colors.lightBlue)),
              Expanded(
                  child: Text('${_monthName(_month.month)} ${_month.year}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge)),
              IconButton(
                  onPressed: () => _changeMonth(1),
                  icon:
                      const Icon(Icons.chevron_right, color: Colors.lightBlue)),
            ]),
            const SizedBox(height: 9),
            Row(children: [
              for (final label in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(
                    child: Center(
                        child: Text(label,
                            style: TextStyle(
                                color: p.textSecondary,
                                fontWeight: FontWeight.w700))))
            ]),
            const SizedBox(height: 5),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cellCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, mainAxisExtent: 48),
              itemBuilder: (context, index) {
                final day = index - firstWeekday + 2;
                if (day < 1 || day > days) return const SizedBox.shrink();
                final date = DateTime(_month.year, _month.month, day);
                final selected = DateUtils.isSameDay(date, _selected);
                final hasMeals = loggedDates
                    .any((logged) => DateUtils.isSameDay(logged, date));
                final total = app
                    .mealsForDate(date)
                    .fold<int>(0, (sum, meal) => sum + meal.calories);
                final good = hasMeals && total <= app.calorieGoal;
                return InkWell(
                  onTap: () => setState(() => _selected = date),
                  borderRadius: BorderRadius.circular(18),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF19A9D7)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Text('$day',
                              style: TextStyle(
                                  color:
                                      selected ? Colors.white : p.textPrimary,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w500)),
                        ),
                        if (hasMeals)
                          Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                  color: good ? p.brand : p.error,
                                  shape: BoxShape.circle)),
                      ]),
                );
              },
            ),
            const SizedBox(height: 20),
            Row(children: [
              _stat('🏆', context.tr('Active', 'Ngày hoạt động'),
                  '$dayCount days'),
              _stat('✅', context.tr('Green Days', 'Ngày đạt mục tiêu'),
                  '$greenCount / 30'),
              _stat('⚖️', context.tr('Weight', 'Cân nặng'),
                  '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} kg'),
            ]),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              onPressed: () => ShareCardService.shareSuccess(
                date: _selected,
                calories: kcal,
                goal: app.calorieGoal,
                meals: entries.length,
                activeDays: dayCount,
                greenDays: greenCount,
                weightChange: change,
              ),
              icon: const Icon(Icons.share, color: Color(0xFF19A9D7)),
              label: Text(context.tr('Share Your Success', 'Chia sẻ thành tựu'),
                  style: TextStyle(color: Color(0xFF19A9D7))),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(60),
                  backgroundColor: p.surface),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                  child: Text('Meals · ${_selected.day}/${_selected.month}',
                      style: Theme.of(context).textTheme.titleLarge)),
              Text('$kcal kcal',
                  style: TextStyle(
                      color: p.textSecondary, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  child: Text('No meals recorded for this day.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.textSecondary)))
            else
              for (final meal in entries)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(_foodEmoji(meal.name),
                      style: const TextStyle(fontSize: 25)),
                  title: Text(meal.name),
                  subtitle: Text(
                      '${meal.serving} · P ${meal.protein.toStringAsFixed(1)} g · C ${meal.carbs.toStringAsFixed(1)} g · F ${meal.fat.toStringAsFixed(1)} g'),
                  trailing: Text('${meal.calories} kcal'),
                ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DaySummaryScreen(date: _selected))),
              icon: const Icon(Icons.list_alt),
              label: Text(context.tr('View day details', 'Xem chi tiết ngày')),
            ),
          ],
        ),
      );
    });
  }

  Widget _stat(String emoji, String name, String value) => Expanded(
          child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 25)),
        const SizedBox(height: 6),
        Text(name, style: TextStyle(color: context.palette.textSecondary)),
        const SizedBox(height: 4),
        Text(value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700))
      ]));

  String _monthName(int month) => const [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ][month - 1];
  String _foodEmoji(String name) {
    final n = name.toLowerCase();
    if (n.contains('rice')) return '🍚';
    if (n.contains('chicken')) return '🐥';
    if (n.contains('egg')) return '🥚';
    if (n.contains('coffee')) return '☕';
    if (n.contains('fish')) return '🐟';
    return '🍽️';
  }

  void _changeMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));
  Future<void> _pickDate() async {
    final selected = await showDatePicker(
        context: context,
        initialDate: _selected,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 365)));
    if (selected != null && mounted)
      setState(() {
        _selected = selected;
        _month = DateTime(selected.year, selected.month);
      });
  }
}

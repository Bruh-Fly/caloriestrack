import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/calorie_ring.dart';
import '../widgets/macro_bar.dart';
import '../widgets/meal_card.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, prov, _) => CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _Header(prov: prov),
          SliverToBoxAdapter(child: _RingSection(prov: prov)),
          SliverToBoxAdapter(child: _MacroSection(prov: prov)),
          SliverToBoxAdapter(child: _MealsHeader(prov: prov)),
          if (prov.todayMeals.isEmpty)
            const SliverToBoxAdapter(child: _EmptyMeals())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => MealCard(
                  meal: prov.todayMeals[i],
                  onDelete: () => prov.deleteMeal(prov.todayMeals[i].id),
                ),
                childCount: prov.todayMeals.length,
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 110)),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final AppProvider prov;
  const _Header({required this.prov});

  @override
  Widget build(BuildContext context) {
    final hour    = DateTime.now().hour;
    final greet   = hour < 12 ? '🌅 Chào buổi sáng' : hour < 18 ? '☀️ Chào buổi chiều' : '🌙 Chào buổi tối';
    final dateStr = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greet, style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500,
                )),
                const SizedBox(height: 3),
                Text(dateStr, style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                )),
              ],
            ),
            _AiChip(),
          ],
        ),
      ),
    );
  }
}

class _AiChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accent.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(color: AppTheme.accent.withOpacity(0.12), blurRadius: 12),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7, height: 7,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.green),
          ),
          const SizedBox(width: 7),
          const Text(
            'Gemini AI',
            style: TextStyle(
              color: AppTheme.green, fontSize: 12, fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ring Section ─────────────────────────────────────────────────
class _RingSection extends StatelessWidget {
  final AppProvider prov;
  const _RingSection({required this.prov});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          CalorieRing(
            consumed: prov.todayCalories,
            goal:     prov.calorieGoal,
            progress: prov.calorieProgress,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _stat('Đã ăn',   '${prov.todayCalories}',      'kcal', AppTheme.accent),
              _divider(),
              _stat('Còn lại', '${prov.remainingCalories}',  'kcal', AppTheme.green),
              _divider(),
              _stat('Mục tiêu','${prov.calorieGoal}',        'kcal', AppTheme.textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1, height: 38,
    margin: const EdgeInsets.symmetric(horizontal: 20),
    color: AppTheme.surface,
  );

  Widget _stat(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 1),
        Text(unit, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ── Macro Section ─────────────────────────────────────────────────
class _MacroSection extends StatelessWidget {
  final AppProvider prov;
  const _MacroSection({required this.prov});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dinh dưỡng hôm nay',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          MacroBar(label: 'Protein',   value: prov.todayProtein, goal: prov.proteinGoal, unit: 'g', color: AppTheme.proteinColor),
          const SizedBox(height: 14),
          MacroBar(label: 'Carbs',     value: prov.todayCarbs,   goal: prov.carbsGoal,   unit: 'g', color: AppTheme.carbsColor),
          const SizedBox(height: 14),
          MacroBar(label: 'Chất béo',  value: prov.todayFat,     goal: prov.fatGoal,     unit: 'g', color: AppTheme.fatColor),
        ],
      ),
    );
  }
}

// ── Meals Header ──────────────────────────────────────────────────
class _MealsHeader extends StatelessWidget {
  final AppProvider prov;
  const _MealsHeader({required this.prov});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Bữa ăn hôm nay',
            style: const TextStyle(
              color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700,
            ),
          ),
          if (prov.todayMeals.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${prov.todayMeals.length} bữa',
                style: const TextStyle(
                  color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────
class _EmptyMeals extends StatelessWidget {
  const _EmptyMeals();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
              ),
              child: Icon(
                Icons.restaurant_menu_rounded,
                size: 40,
                color: AppTheme.accent.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có bữa ăn nào',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nhấn nút 📷 để chụp ảnh thức ăn',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

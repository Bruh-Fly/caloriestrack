import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/meal_card.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Consumer<AppProvider>(
          builder: (context, prov, _) {
            final grouped = prov.mealsGroupedByDate;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeader(prov),
                if (grouped.isEmpty)
                  const SliverFillRemaining(child: _EmptyHistory())
                else
                  ..._buildGroups(context, prov, grouped),
                const SliverPadding(padding: EdgeInsets.only(bottom: 110)),
              ],
            );
          },
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildHeader(AppProvider prov) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Lịch sử',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.07)),
              ),
              child: Text(
                '${prov.allMeals.length} bữa',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroups(
    BuildContext context,
    AppProvider prov,
    Map<DateTime, List> grouped,
  ) {
    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      final date      = entry.key;
      final meals     = entry.value;
      final totalCals = meals.fold<int>(0, (s, m) => s + (m.calories as int));

      // Date header
      widgets.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(date),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${meals.length} bữa ăn',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.accent.withOpacity(0.25)),
                  ),
                  child: Text(
                    '$totalCals kcal',
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Meal cards
      widgets.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => MealCard(
              meal: meals[i],
              onDelete: () => prov.deleteMeal(meals[i].id),
            ),
            childCount: meals.length,
          ),
        ),
      );
    }
    return widgets;
  }

  String _formatDate(DateTime date) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff  = today.difference(DateTime(date.year, date.month, date.day)).inDays;
    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Hôm qua';
    return DateFormat('EEEE, d/M/yyyy').format(date);
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.accent.withOpacity(0.18)),
            ),
            child: Icon(
              Icons.history_rounded,
              size: 44,
              color: AppTheme.accent.withOpacity(0.45),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Chưa có lịch sử',
            style: TextStyle(
              color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bắt đầu chụp ảnh thức ăn để ghi lại',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

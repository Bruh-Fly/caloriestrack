import 'dart:io';
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meal_entry.dart';
import '../theme/app_theme.dart';

class MealCard extends StatelessWidget {
  const MealCard({super.key, required this.meal, required this.onDelete});

  final MealEntry meal;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Dismissible(
      key: ValueKey(meal.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: p.surface,
          title: Text('Xóa món ăn?', style: TextStyle(color: p.textPrimary)),
          content: Text('Xóa “${meal.name}” khỏi nhật ký?',
              style: TextStyle(color: p.textSecondary)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('Hủy', style: TextStyle(color: p.textSecondary))),
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text('Xóa', style: TextStyle(color: p.error))),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        decoration: BoxDecoration(
            color: p.error.withOpacity(.12),
            borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Icon(Icons.delete_outline, color: p.error),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child:
                  SizedBox(width: 58, height: 58, child: _thumbnail(context)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meal.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: p.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(
                      '${meal.serving} · ${DateFormat('HH:mm').format(meal.timestamp)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: p.textSecondary, fontSize: 11)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _MacroTag(
                          label: 'P', value: meal.protein, color: p.protein),
                      _MacroTag(label: 'C', value: meal.carbs, color: p.carbs),
                      _MacroTag(label: 'F', value: meal.fat, color: p.fat),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${meal.calories}',
                    style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()])),
                Text('kcal',
                    style: TextStyle(color: p.textSecondary, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail(BuildContext context) {
    final p = context.palette;
    if (meal.imagePath != null) {
      return Image.file(File(meal.imagePath!),
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder(p));
    }
    return Container(
      color: p.brandSoft,
      alignment: Alignment.center,
      child:
          Text(_foodCharacter(meal.name), style: const TextStyle(fontSize: 29)),
    );
  }

  Widget _placeholder(AppPalette p) => Container(
        color: p.brandSoft,
        child: Icon(Icons.restaurant_outlined, color: p.brand, size: 24),
      );
}

String _foodCharacter(String name) {
  final value = name.toLowerCase();
  if (value.contains('rice')) return '🍚';
  if (value.contains('chicken')) return '🐥';
  if (value.contains('banana')) return '🍌';
  if (value.contains('egg')) return '🥚';
  if (value.contains('broccoli')) return '🥦';
  if (value.contains('avocado')) return '🥑';
  if (value.contains('strawber')) return '🍓';
  if (value.contains('apple')) return '🍎';
  if (value.contains('fish') || value.contains('salmon')) return '🐟';
  if (value.contains('bread')) return '🍞';
  if (value.contains('coffee')) return '☕';
  if (value.contains('beef')) return '🐮';
  return '🍽️';
}

class _MacroTag extends StatelessWidget {
  const _MacroTag(
      {required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
        '$label ${value.round()}g',
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      );
}

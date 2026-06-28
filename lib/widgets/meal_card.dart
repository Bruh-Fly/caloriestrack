import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meal_entry.dart';
import '../theme/app_theme.dart';

class MealCard extends StatelessWidget {
  final MealEntry meal;
  final VoidCallback onDelete;

  const MealCard({super.key, required this.meal, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(meal.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.surfaceAlt,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Xóa bữa ăn?', style: TextStyle(color: AppTheme.textPrimary)),
          content: Text(
            'Xóa "${meal.name}" khỏi nhật ký?',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa', style: TextStyle(color: AppTheme.errorColor)),
            ),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.errorColor.withOpacity(0.4)),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor, size: 26),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            // Thumbnail
            _thumbnail(),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${meal.serving} · ${DateFormat('HH:mm').format(meal.timestamp)}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _chip('P ${meal.protein.toStringAsFixed(0)}g', AppTheme.proteinColor),
                      const SizedBox(width: 5),
                      _chip('C ${meal.carbs.toStringAsFixed(0)}g', AppTheme.carbsColor),
                      const SizedBox(width: 5),
                      _chip('F ${meal.fat.toStringAsFixed(0)}g', AppTheme.fatColor),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Calories
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${meal.calories}',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const Text(
                  'kcal',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail() {
    Widget child;
    if (meal.imagePath != null) {
      child = Image.file(
        File(meal.imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _icon(),
      );
    } else {
      child = _icon();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(width: 54, height: 54, child: child),
    );
  }

  Widget _icon() => Container(
        color: AppTheme.accent.withOpacity(0.12),
        child: const Icon(Icons.restaurant_rounded, color: AppTheme.accent, size: 26),
      );

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.13),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          text,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
        ),
      );
}



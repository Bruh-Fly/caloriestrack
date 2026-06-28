import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Consumer<AppProvider>(
          builder: (context, prov, _) => CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHeader(),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _DailyGoalCard(prov: prov),
                    const SizedBox(height: 14),
                    _MacroGoalsCard(prov: prov),
                    const SizedBox(height: 14),
                    _StatsCard(prov: prov),
                    const SizedBox(height: 14),
                    _InfoCard(),
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildHeader() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Text(
          'Cài đặt',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

// ── Daily Calorie Goal ─────────────────────────────────────────────
class _DailyGoalCard extends StatelessWidget {
  final AppProvider prov;
  const _DailyGoalCard({required this.prov});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: '🎯 Mục tiêu calo hàng ngày',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${prov.calorieGoal} kcal/ngày',
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              TextButton(
                onPressed: () => _editCalorieGoal(context, prov),
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.accent.withOpacity(0.15),
                  foregroundColor: AppTheme.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: const Text('Sửa', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _presetBtn(context, prov, 1500, 'Giảm cân'),
              _presetBtn(context, prov, 2000, 'Duy trì'),
              _presetBtn(context, prov, 2500, 'Tăng cân'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetBtn(BuildContext context, AppProvider prov, int cal, String label) {
    final selected = prov.calorieGoal == cal;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        prov.updateCalorieGoal(cal);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent.withOpacity(0.18) : AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.accent.withOpacity(0.5) : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$cal',
              style: TextStyle(
                color: selected ? AppTheme.accent : AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppTheme.accent.withOpacity(0.7) : AppTheme.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editCalorieGoal(BuildContext context, AppProvider prov) {
    final ctrl = TextEditingController(text: '${prov.calorieGoal}');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Mục tiêu calo', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18),
          decoration: InputDecoration(
            suffixText: 'kcal',
            suffixStyle: const TextStyle(color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.surfaceAlt,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final val = int.tryParse(ctrl.text);
              if (val != null && val > 0) prov.updateCalorieGoal(val);
              Navigator.pop(context);
            },
            child: const Text('Lưu', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Macro Goals ────────────────────────────────────────────────────
class _MacroGoalsCard extends StatelessWidget {
  final AppProvider prov;
  const _MacroGoalsCard({required this.prov});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: '⚖️ Mục tiêu dinh dưỡng',
      child: Column(
        children: [
          _macroRow(context, prov, 'Protein',   '${prov.proteinGoal.toInt()}g', AppTheme.proteinColor),
          const SizedBox(height: 10),
          _macroRow(context, prov, 'Carbs',     '${prov.carbsGoal.toInt()}g',   AppTheme.carbsColor),
          const SizedBox(height: 10),
          _macroRow(context, prov, 'Chất béo',  '${prov.fatGoal.toInt()}g',     AppTheme.fatColor),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _editMacros(context, prov),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                side: BorderSide(color: Colors.white.withOpacity(0.12)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Chỉnh sửa macro'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroRow(BuildContext ctx, AppProvider prov, String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          ],
        ),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }

  void _editMacros(BuildContext context, AppProvider prov) {
    final pCtrl = TextEditingController(text: '${prov.proteinGoal.toInt()}');
    final cCtrl = TextEditingController(text: '${prov.carbsGoal.toInt()}');
    final fCtrl = TextEditingController(text: '${prov.fatGoal.toInt()}');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Mục tiêu macro', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _macroField('Protein (g)', pCtrl, AppTheme.proteinColor),
            const SizedBox(height: 10),
            _macroField('Carbs (g)',   cCtrl, AppTheme.carbsColor),
            const SizedBox(height: 10),
            _macroField('Chất béo (g)', fCtrl, AppTheme.fatColor),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final p = double.tryParse(pCtrl.text) ?? prov.proteinGoal;
              final c = double.tryParse(cCtrl.text) ?? prov.carbsGoal;
              final f = double.tryParse(fCtrl.text) ?? prov.fatGoal;
              prov.updateMacroGoals(protein: p, carbs: c, fat: f);
              Navigator.pop(context);
            },
            child: const Text('Lưu', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _macroField(String label, TextEditingController ctrl, Color color) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: TextStyle(color: color, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        filled: true,
        fillColor: AppTheme.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color.withOpacity(0.5)),
        ),
      ),
    );
  }
}

// ── Stats Card ─────────────────────────────────────────────────────
class _StatsCard extends StatelessWidget {
  final AppProvider prov;
  const _StatsCard({required this.prov});

  @override
  Widget build(BuildContext context) {
    final total = prov.allMeals.length;
    final avgCal = total == 0
        ? 0
        : (prov.allMeals.fold<int>(0, (s, m) => s + m.calories) / total).round();

    return _Card(
      title: '📊 Thống kê',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('Tổng bữa ăn', '$total',     'bữa'),
          _vDivider(),
          _stat('Calo TB/bữa', '$avgCal',    'kcal'),
          _vDivider(),
          _stat('Hôm nay',    '${prov.todayCalories}', 'kcal'),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, String unit) => Column(
    children: [
      Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w900)),
      const SizedBox(height: 2),
      Text(unit,  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
    ],
  );

  Widget _vDivider() => Container(width: 1, height: 40, color: AppTheme.surfaceAlt);
}

// ── Info Card ──────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'ℹ️ Thông tin',
      child: Column(
        children: [
          _row(Icons.smart_toy_rounded, 'AI Model', 'Gemini 1.5 Flash (miễn phí)'),
          const SizedBox(height: 10),
          _row(Icons.cloud_off_rounded, 'Dữ liệu', 'Lưu trên thiết bị'),
          const SizedBox(height: 10),
          _row(Icons.info_rounded, 'Phiên bản', '1.0.0'),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.key_rounded, color: AppTheme.accent, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Lấy API Key miễn phí tại aistudio.google.com\nSau đó điền vào GeminiService._apiKey',
                    style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12, height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, color: AppTheme.textSecondary, size: 18),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      const Spacer(),
      Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
    ],
  );
}

// ── Reusable Card Shell ────────────────────────────────────────────
class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

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
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/food_result.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class ResultScreen extends StatefulWidget {
  final FoodResult result;
  final File imageFile;

  const ResultScreen({super.key, required this.result, required this.imageFile});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late AnimationController _countCtrl;
  late Animation<Offset>   _slide;
  late Animation<double>   _fade;
  late Animation<int>      _calCount;

  bool _logged = false;

  @override
  void initState() {
    super.initState();

    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _countCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

    _slide    = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fade     = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _calCount = IntTween(begin: 0, end: widget.result.calories)
        .animate(CurvedAnimation(parent: _countCtrl, curve: Curves.easeOut));

    _slideCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _countCtrl.forward();
    });
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _countCtrl.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Blurred food image behind top half
          _buildHeroImage(),
          // Content
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SlideTransition(
                    position: _slide,
                    child: FadeTransition(
                      opacity: _fade,
                      child: _buildScrollContent(),
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

  Widget _buildHeroImage() {
    return Positioned(
      top: 0, left: 0, right: 0,
      height: 280,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(widget.imageFile, fit: BoxFit.cover),
          // Gradient fade into background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.35),
                  AppTheme.background,
                ],
                stops: const [0.3, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 200, 16, 24),
      child: Column(
        children: [
          // ── Main result card ──
          _MainCard(result: widget.result, calCount: _calCount),
          const SizedBox(height: 14),
          // ── Macro detail card ──
          _MacroDetailCard(result: widget.result),
          const SizedBox(height: 24),
          // ── Log / logged button ──
          _buildLogButton(),
          const SizedBox(height: 10),
          // ── Retake button ──
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text('Chụp lại'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                side: BorderSide(color: Colors.white.withOpacity(0.15)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogButton() {
    if (_logged) {
      return Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.green.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.green.withOpacity(0.4)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.green, size: 22),
            SizedBox(width: 10),
            Text(
              'Đã lưu vào nhật ký!',
              style: TextStyle(color: AppTheme.green, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _logMeal,
        icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
        label: const Text('Thêm vào nhật ký'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accent,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          shadowColor: AppTheme.accent.withOpacity(0.5),
        ),
      ),
    );
  }

  Future<void> _logMeal() async {
    HapticFeedback.mediumImpact();
    await context.read<AppProvider>().logMeal(
          widget.result,
          imagePath: widget.imageFile.path,
        );
    setState(() => _logged = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppTheme.green, size: 18),
              const SizedBox(width: 10),
              Text('Đã thêm ${widget.result.name} · ${widget.result.calories} kcal'),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

// ── Main Card ─────────────────────────────────────────────────────
class _MainCard extends StatelessWidget {
  final FoodResult result;
  final Animation<int> calCount;
  const _MainCard({required this.result, required this.calCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Food name
          Text(
            result.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            result.serving,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),

          const SizedBox(height: 22),

          // Animated calorie number
          AnimatedBuilder(
            animation: calCount,
            builder: (_, __) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${calCount.value}',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 80,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: -3,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 14, left: 6),
                  child: Text(
                    'kcal',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Macro pills
          Row(
            children: [
              _pill('Protein', '${result.protein.toStringAsFixed(1)}g', AppTheme.proteinColor),
              const SizedBox(width: 8),
              _pill('Carbs', '${result.carbs.toStringAsFixed(1)}g', AppTheme.carbsColor),
              const SizedBox(width: 8),
              _pill('Béo', '${result.fat.toStringAsFixed(1)}g', AppTheme.fatColor),
            ],
          ),

          // Optional description
          if (result.description != null && result.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.description!,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pill(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color.withOpacity(0.65), fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    ),
  );
}

// ── Macro Detail Card ─────────────────────────────────────────────
class _MacroDetailCard extends StatelessWidget {
  final FoodResult result;
  const _MacroDetailCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiết dinh dưỡng',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          _bar('Protein',      result.protein, 50,  'g', AppTheme.proteinColor),
          const SizedBox(height: 14),
          _bar('Carbohydrate', result.carbs,   250, 'g', AppTheme.carbsColor),
          const SizedBox(height: 14),
          _bar('Chất béo',     result.fat,     65,  'g', AppTheme.fatColor),

          const SizedBox(height: 18),
          const Divider(color: Color(0xFF2A2A3A), height: 1),
          const SizedBox(height: 14),

          // Calorie breakdown
          const Text(
            'Phân bổ calo',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          _calorieBreakdownBar(result),
        ],
      ),
    );
  }

  Widget _bar(String label, double value, double max, String unit, Color color) {
    final pct = (value / max).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            Text(
              '${value.toStringAsFixed(1)} $unit',
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 7,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _calorieBreakdownBar(FoodResult r) {
    final total = r.caloriesFromProtein + r.caloriesFromCarbs + r.caloriesFromFat;
    if (total == 0) return const SizedBox.shrink();

    return Column(
      children: [
        // Stacked bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                _stackSegment(r.proteinPercent, AppTheme.proteinColor),
                _stackSegment(r.carbsPercent,   AppTheme.carbsColor),
                _stackSegment(r.fatPercent,      AppTheme.fatColor),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _legend('Protein', r.proteinPercent, AppTheme.proteinColor),
            _legend('Carbs',   r.carbsPercent,   AppTheme.carbsColor),
            _legend('Béo',     r.fatPercent,      AppTheme.fatColor),
          ],
        ),
      ],
    );
  }

  Widget _stackSegment(double flex, Color color) => Expanded(
    flex: (flex * 100).toInt().clamp(1, 100),
    child: Container(color: color),
  );

  Widget _legend(String label, double pct, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(
          '$label ${(pct * 100).toInt()}%',
          style: TextStyle(color: color.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

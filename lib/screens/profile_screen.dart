import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/lifestyle_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'welcome_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final life = context.watch<LifestyleProvider>();
    return SafeArea(
      child: Consumer<AppProvider>(
        builder: (context, provider, _) => ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 120),
          children: [
            Text('Tài khoản & mục tiêu',
                style: TextStyle(color: p.textSecondary, fontSize: 12)),
            const SizedBox(height: 3),
            Text('Hồ sơ',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontSize: 28)),
            const SizedBox(height: 21),
            _AccountCard(),
            const SizedBox(height: 16),
            _BuddyCard(),
            const SizedBox(height: 22),
            _SectionHeading(
                title: 'Tiến độ cân nặng',
                action: 'Cập nhật',
                onTap: () => _addWeight(context, life)),
            const SizedBox(height: 10),
            Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.monitor_weight_outlined, color: p.brand),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(
                                life.weightHistory.isEmpty
                                    ? 'Thêm cân nặng đầu tiên để theo dõi tiến độ'
                                    : '${life.weightHistory.first.toStringAsFixed(1)} kg',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700))),
                        if (life.weightHistory.length > 1)
                          Text('${life.weightHistory.length} lần ghi',
                              style: TextStyle(
                                  color: p.textSecondary, fontSize: 11))
                      ]),
                      const SizedBox(height: 8),
                      Text(
                          life.weightHistory.length > 1
                              ? 'Lần trước: ${life.weightHistory[1].toStringAsFixed(1)} kg'
                              : 'Cân nặng được lưu trên thiết bị này.',
                          style:
                              TextStyle(color: p.textSecondary, fontSize: 12))
                    ])),
            const SizedBox(height: 25),
            _SectionHeading(
                title: 'Mục tiêu hàng ngày',
                action: 'Sửa',
                onTap: () => _editCalories(context, provider)),
            const SizedBox(height: 10),
            _GoalCard(calories: provider.calorieGoal),
            const SizedBox(height: 22),
            _SectionHeading(
                title: 'Mục tiêu dinh dưỡng',
                action: 'Sửa',
                onTap: () => _editMacros(context, provider)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _MacroGoal(
                        label: 'Protein',
                        amount: provider.proteinGoal.round(),
                        unit: 'g',
                        color: p.protein)),
                const SizedBox(width: 9),
                Expanded(
                    child: _MacroGoal(
                        label: 'Carbs',
                        amount: provider.carbsGoal.round(),
                        unit: 'g',
                        color: p.carbs)),
                const SizedBox(width: 9),
                Expanded(
                    child: _MacroGoal(
                        label: 'Fat',
                        amount: provider.fatGoal.round(),
                        unit: 'g',
                        color: p.fat)),
              ],
            ),
            const SizedBox(height: 25),
            _SectionHeading(title: 'Tổng quan', action: null),
            const SizedBox(height: 10),
            _OverviewCard(
                mealCount: provider.allMeals.length,
                consumed: provider.todayCalories),
            const SizedBox(height: 24),
            _SettingsRow(
              icon: Icons.settings_outlined,
              title: 'Cài đặt',
              subtitle: 'Thông báo, đơn vị và quyền riêng tư',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
            const SizedBox(height: 8),
            _SettingsRow(
                icon: Icons.info_outline,
                title: 'Về CaloAI',
                subtitle: 'Theo dõi dinh dưỡng của bạn'),
            const SizedBox(height: 8),
            _SettingsRow(
              icon: Icons.logout_rounded,
              title: 'Đăng xuất',
              subtitle: 'Đăng xuất khỏi thiết bị này',
              destructive: true,
              onTap: () => _signOut(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addWeight(BuildContext context, LifestyleProvider life) async {
    final controller = TextEditingController(
        text: life.weightHistory.isEmpty
            ? ''
            : life.weightHistory.first.toString());
    final value = await showDialog<double>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Cập nhật cân nặng'),
                content: TextField(
                    controller: controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Cân nặng', suffixText: 'kg')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy')),
                  TextButton(
                      onPressed: () => Navigator.pop(
                          context,
                          double.tryParse(
                              controller.text.replaceAll(',', '.'))),
                      child: const Text('Lưu'))
                ]));
    if (value != null && value > 0 && value < 500) await life.addWeight(value);
  }

  Future<void> _editCalories(BuildContext context, AppProvider provider) async {
    final controller = TextEditingController(text: '${provider.calorieGoal}');
    final p = context.palette;
    final value = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) => _EditSheet(
        title: 'Mục tiêu calo',
        onSave: () {
          final parsed = int.tryParse(controller.text);
          if (parsed != null && parsed >= 500 && parsed <= 10000)
            Navigator.pop(sheetContext, parsed);
        },
        child: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
              labelText: 'Calo mỗi ngày', suffixText: 'kcal'),
        ),
      ),
    );
    controller.dispose();
    if (value != null) await provider.updateCalorieGoal(value);
  }

  Future<void> _editMacros(BuildContext context, AppProvider provider) async {
    final protein =
        TextEditingController(text: '${provider.proteinGoal.round()}');
    final carbs = TextEditingController(text: '${provider.carbsGoal.round()}');
    final fat = TextEditingController(text: '${provider.fatGoal.round()}');
    final p = context.palette;
    final values = await showModalBottomSheet<List<double>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) => _EditSheet(
        title: 'Mục tiêu dinh dưỡng',
        onSave: () {
          final pValue = double.tryParse(protein.text);
          final cValue = double.tryParse(carbs.text);
          final fValue = double.tryParse(fat.text);
          if (pValue != null &&
              cValue != null &&
              fValue != null &&
              pValue >= 0 &&
              cValue >= 0 &&
              fValue >= 0) {
            Navigator.pop(sheetContext, [pValue, cValue, fValue]);
          }
        },
        child: Column(
          children: [
            TextField(
                controller: protein,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                    labelText: 'Protein',
                    suffixText: 'g',
                    prefixIcon:
                        Icon(Icons.circle, color: p.protein, size: 12))),
            const SizedBox(height: 10),
            TextField(
                controller: carbs,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                    labelText: 'Carbs',
                    suffixText: 'g',
                    prefixIcon: Icon(Icons.circle, color: p.carbs, size: 12))),
            const SizedBox(height: 10),
            TextField(
                controller: fat,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                    labelText: 'Fat',
                    suffixText: 'g',
                    prefixIcon: Icon(Icons.circle, color: p.fat, size: 12))),
          ],
        ),
      ),
    );
    protein.dispose();
    carbs.dispose();
    fat.dispose();
    if (values != null)
      await provider.updateMacroGoals(
          protein: values[0], carbs: values[1], fat: values[2]);
  }

  Future<void> _signOut(BuildContext context) async {
    final p = context.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: p.surface,
        title: Text('Đăng xuất?', style: TextStyle(color: p.textPrimary)),
        content: Text('Bạn có thể đăng nhập lại bằng Google bất cứ lúc nào.',
            style: TextStyle(color: p.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('Ở lại', style: TextStyle(color: p.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('Đăng xuất', style: TextStyle(color: p.error))),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<AppProvider>().clearForSignOut();
    await context.read<LifestyleProvider>().clearForSignOut();
    await AuthService().signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
        (_) => false);
  }
}

class _BuddyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
            color: p.brandSoft, borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          Icon(Icons.group_add_outlined, color: p.brand, size: 25),
          const SizedBox(width: 12),
          const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Cùng bạn bè tạo động lực',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                Text('Mời bạn cùng theo dõi mục tiêu',
                    style: TextStyle(fontSize: 11))
              ])),
          TextButton(
              onPressed: () async {
                await Clipboard.setData(const ClipboardData(
                    text: 'Cùng mình theo dõi dinh dưỡng với CaloAI!'));
                if (context.mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã sao chép lời mời')));
              },
              child: const Text('Mời'))
        ]));
  }
}

class _AccountCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: p.surface, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: FutureBuilder(
        future: AuthService().currentUser,
        builder: (context, snapshot) {
          final user = snapshot.data;
          final name = user?.displayName?.trim().isNotEmpty == true
              ? user!.displayName!
              : 'Tài khoản CaloAI';
          final email = user?.email ?? 'Google đã kết nối';
          return Row(
            children: [
              Container(
                  width: 48,
                  height: 48,
                  decoration:
                      BoxDecoration(color: p.brandSoft, shape: BoxShape.circle),
                  child: Icon(Icons.person_outline, color: p.brand)),
              const SizedBox(width: 13),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: p.textSecondary, fontSize: 11)),
                  ])),
              Icon(Icons.verified_rounded, color: p.success, size: 18),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(
      {required this.title, required this.action, this.onTap});
  final String title;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
              child: Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 15))),
          if (action != null)
            TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    minimumSize: const Size(0, 34)),
                child: Text(action!,
                    style: TextStyle(
                        color: context.palette.brand,
                        fontWeight: FontWeight.w600))),
        ],
      );
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.calories});
  final int calories;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
          color: p.brand, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Năng lượng',
                    style: TextStyle(
                        color: p.onBrand.withOpacity(.72), fontSize: 12)),
                const SizedBox(height: 7),
                Text('$calories',
                    style: TextStyle(
                        color: p.onBrand,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        height: 1)),
              ])),
          Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text('kcal / ngày',
                  style: TextStyle(
                      color: p.onBrand.withOpacity(.78), fontSize: 12))),
        ],
      ),
    );
  }
}

class _MacroGoal extends StatelessWidget {
  const _MacroGoal(
      {required this.label,
      required this.amount,
      required this.unit,
      required this.color});
  final String label;
  final int amount;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      decoration: BoxDecoration(
          color: p.surface, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(height: 13),
        Text('$amount$unit',
            style: TextStyle(
                color: p.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: p.textSecondary, fontSize: 10)),
      ]),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.mealCount, required this.consumed});
  final int mealCount;
  final int consumed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: p.surface, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Row(children: [
        Expanded(
            child: _OverviewStat(
                value: '$mealCount', label: 'Món đã lưu', color: p.brand)),
        Container(width: 1, height: 34, color: p.outline),
        Expanded(
            child: _OverviewStat(
                value: '$consumed',
                label: 'Kcal hôm nay',
                color: p.textPrimary)),
      ]),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  const _OverviewStat(
      {required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label,
            style:
                TextStyle(color: context.palette.textSecondary, fontSize: 10))
      ]);
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow(
      {required this.icon,
      required this.title,
      required this.subtitle,
      this.destructive = false,
      this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final bool destructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = destructive ? p.error : p.textSecondary;
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: TextStyle(
                          color: destructive ? p.error : p.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(color: p.textSecondary, fontSize: 10))
                ])),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded,
                  color: p.textSecondary, size: 20),
          ]),
        ),
      ),
    );
  }
}

class _EditSheet extends StatelessWidget {
  const _EditSheet(
      {required this.title, required this.child, required this.onSave});
  final String title;
  final Widget child;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          22, 13, 22, MediaQuery.viewInsetsOf(context).bottom + 22),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 34,
                    height: 4,
                    decoration: BoxDecoration(
                        color: p.outline,
                        borderRadius: BorderRadius.circular(AppRadius.pill)))),
            const SizedBox(height: 20),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 18),
            child,
            const SizedBox(height: 18),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: onSave, child: const Text('Lưu thay đổi'))),
          ]),
    );
  }
}

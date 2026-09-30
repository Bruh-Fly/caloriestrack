import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/language_provider.dart';
import '../services/app_text.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _reminders = true;
  String _units = 'Metric (kg, cm)';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted)
      setState(() => _reminders = prefs.getBool('caloai_reminders') ?? true);
  }

  Future<void> _saveReminder(bool value) async {
    setState(() => _reminders = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('caloai_reminders', value);
  }

  Future<void> _chooseUnits() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final option in [
            context.tr('Metric (kg, cm)', 'Hệ mét (kg, cm)'),
            context.tr('Imperial (lb, ft)', 'Hệ Anh (lb, ft)')
          ])
            ListTile(
                title: Text(option), onTap: () => Navigator.pop(ctx, option)),
        ]),
      ),
    );
    if (value != null) setState(() => _units = value);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(title: Text(context.tr('Settings', 'Cài đặt'))),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text(context.tr('Preferences', 'Tùy chọn'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        _card(p, Consumer<LanguageProvider>(builder: (context, language, _) {
          final selected = LanguageProvider.options
              .firstWhere((option) => option.code == language.code);
          return ListTile(
            leading: const Icon(Icons.language),
            title: Text(context.tr('Language', 'Ngôn ngữ')),
            subtitle: Text(selected.nativeName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _chooseLanguage(language),
          );
        })),
        const SizedBox(height: 10),
        _card(
            p,
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              title: Text(context.tr('Daily reminders', 'Nhắc nhở hằng ngày')),
              subtitle: Text(context.tr('Meal and hydration reminders',
                  'Nhắc ghi bữa ăn và uống nước')),
              value: _reminders,
              activeColor: p.brand,
              onChanged: _saveReminder,
            )),
        const SizedBox(height: 10),
        _card(
            p,
            ListTile(
              title: Text(context.tr('Units', 'Đơn vị')),
              subtitle: Text(_units),
              trailing: const Icon(Icons.chevron_right),
              onTap: _chooseUnits,
            )),
        const SizedBox(height: 24),
        Text(context.tr('Account & privacy', 'Tài khoản & quyền riêng tư'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        _card(
            p,
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(context.tr('Privacy', 'Quyền riêng tư')),
              subtitle: Text(context.tr(
                  'Your health and meal data is linked to your account.',
                  'Dữ liệu sức khỏe và bữa ăn được liên kết với tài khoản của bạn.')),
            )),
        const SizedBox(height: 10),
        _card(
            p,
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(context.tr('About CaloAI', 'Về CaloAI')),
              subtitle: Text(context.tr(
                  'Nutrition estimates are informational.',
                  'Thông tin dinh dưỡng chỉ mang tính ước tính.')),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'CaloAI',
                applicationVersion: '1.0.0',
                children: [
                  Text(context.tr('Track meals, calories and nutrition goals.',
                      'Theo dõi bữa ăn, calo và mục tiêu dinh dưỡng.'))
                ],
              ),
            )),
      ]),
    );
  }

  Future<void> _chooseLanguage(LanguageProvider language) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(context.tr('Choose language', 'Chọn ngôn ngữ'),
                  style: Theme.of(sheet).textTheme.titleLarge),
            ),
            for (final option in LanguageProvider.options)
              ListTile(
                title: Text(option.nativeName),
                subtitle: Text(option.name),
                trailing: language.code == option.code
                    ? Icon(Icons.check, color: sheet.palette.brand)
                    : null,
                onTap: () async {
                  await language.setLanguage(option.code);
                  if (sheet.mounted) Navigator.pop(sheet);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _card(dynamic palette, Widget child) => Container(
        decoration: BoxDecoration(
          color: palette.surface,
          border: Border.all(color: palette.outline),
          borderRadius: BorderRadius.circular(18),
        ),
        child: child,
      );
}

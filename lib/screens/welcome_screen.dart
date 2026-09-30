import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/lifestyle_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';
import 'onboarding/onboarding_flow.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(25, 22, 25, 20),
                      child: Column(
                        children: [
                          Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                        width: 29,
                                        height: 29,
                                        decoration: BoxDecoration(
                                            color: p.brand,
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: Icon(Icons.eco_outlined,
                                            color: p.onBrand, size: 17)),
                                    const SizedBox(width: 9),
                                    Text('CALOAI',
                                        style: TextStyle(
                                            color: p.textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.4)),
                                  ])),
                          SizedBox(height: constraints.maxHeight * .075),
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                                color: p.brand,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: p.brand.withOpacity(.15),
                                      blurRadius: 28,
                                      offset: const Offset(0, 9))
                                ]),
                            child: Icon(Icons.local_fire_department_outlined,
                                color: p.onBrand, size: 43),
                          ),
                          const SizedBox(height: 24),
                          Text('Ăn uống cân bằng,\nđúng mục tiêu của bạn.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(fontSize: 31, height: 1.12)),
                          const SizedBox(height: 10),
                          Text(
                              'Ghi lại bữa ăn và theo dõi dinh dưỡng mỗi ngày.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: p.textSecondary,
                                  fontSize: 14,
                                  height: 1.45)),
                          const SizedBox(height: 30),
                          _Benefit(
                              icon: Icons.camera_alt_outlined,
                              text: 'Phân tích món ăn từ ảnh'),
                          _Benefit(
                              icon: Icons.donut_large_outlined,
                              text: 'Theo dõi calo và macros'),
                          _Benefit(
                              icon: Icons.tune_rounded,
                              text: 'Mục tiêu phù hợp với bạn'),
                          const SizedBox(height: 26),
                          SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                  onPressed: _loading ? null : _startOnboarding,
                                  child: const Text('Bắt đầu'))),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: _loading ? null : _signInExisting,
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: p.textPrimary,
                                  side: BorderSide(color: p.outline),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md))),
                              child: _loading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: p.brand))
                                  : const Text('Tôi đã có tài khoản'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
      ),
    );
  }

  void _startOnboarding() {
    Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const OnboardingFlow()));
  }

  Future<void> _signInExisting() async {
    setState(() => _loading = true);
    final profile = await AuthService().signInExisting();
    if (!mounted) return;
    setState(() => _loading = false);

    if (profile != null) {
      final life = context.read<LifestyleProvider>();
      await life.configureMeasurements(
        weight: profile.weight,
        targetWeight: profile.targetWeight,
        height: profile.height,
        age: profile.age,
        sex: profile.sex,
        activity: profile.activity,
        goal: profile.goal,
        rate: profile.rate,
      );
      final app = context.read<AppProvider>();
      await app.updateCalorieGoal(profile.dailyCalories);
      await app.updateMacroGoals(
          protein: profile.proteinGoal,
          carbs: profile.carbsGoal,
          fat: profile.fatGoal);
      await app.loadAccountDataFromBackend();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const MainScreen()));
      return;
    }

    final error = AuthService().lastSignInError;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), duration: const Duration(seconds: 8)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text(
          'Không tìm thấy hồ sơ đã lưu cho tài khoản này. Hãy kiểm tra đúng tài khoản Google hoặc kết nối mạng rồi thử lại.'),
      duration: Duration(seconds: 7),
    ));
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(children: [
        Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: p.surface, borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, color: p.brand, size: 19)),
        const SizedBox(width: 12),
        Text(text,
            style: TextStyle(
                color: p.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

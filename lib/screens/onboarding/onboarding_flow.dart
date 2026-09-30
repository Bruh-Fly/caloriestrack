import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/user_profile.dart';
import '../../providers/app_provider.dart';
import '../../providers/lifestyle_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../main_screen.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  int _page = 0;

  String _goal = '';
  String _rate = '';
  String _sex = '';
  String _name = '';
  int _age = 25;
  double _height = 165;
  double _weight = 65;
  double _target = 60;
  String _activity = '';
  String _diet = '';
  int _meals = 3;
  String _exercise = '';
  String _sleep = '';
  int _calories = 0;
  double _protein = 0;
  double _carbs = 0;
  double _fat = 0;

  static const _totalPages = 15;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _totalPages - 1) {
      HapticFeedback.selectionClick();
      _pageController.nextPage(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic);
    }
  }

  void _back() {
    if (_page > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic);
    } else {
      Navigator.maybePop(context);
    }
  }

  void _computeCalories() {
    _calories = UserProfile.calculateTDEE(
        sex: _sex,
        weight: _weight,
        height: _height,
        age: _age,
        activity: _activity,
        goal: _goal,
        rate: _rate);
    final macros = UserProfile.calculateMacros(_calories, _goal);
    _protein = macros['protein']!;
    _carbs = macros['carbs']!;
    _fat = macros['fat']!;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final pages = _buildPages();
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          children: [
            if (_page < _totalPages - 1)
              _OnboardingHeader(
                  page: _page, total: _totalPages - 1, onBack: _back),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (value) => setState(() => _page = value),
                children: pages,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPages() => [
        _ChoiceQuestion(
          eyebrow: 'MỤC TIÊU',
          icon: Icons.flag_outlined,
          title: 'Bạn muốn hướng tới điều gì?',
          subtitle: 'Chúng tôi sẽ cá nhân hóa kế hoạch theo mục tiêu của bạn.',
          selected: _goal,
          options: const [
            _ChoiceOption('lose_weight', 'Giảm cân',
                'Giảm mỡ theo nhịp độ phù hợp', Icons.trending_down_rounded),
            _ChoiceOption('eat_healthier', 'Duy trì cân nặng',
                'Ăn uống cân bằng mỗi ngày', Icons.balance_rounded),
            _ChoiceOption('gain_weight', 'Tăng cân',
                'Tăng cân và khối lượng lành mạnh', Icons.trending_up_rounded),
          ],
          onSelect: (value) => setState(() => _goal = value),
          onNext: _next,
        ),
        _ChoiceQuestion(
          eyebrow: 'NHỊP ĐỘ',
          icon: Icons.speed_outlined,
          title: 'Bạn muốn thay đổi với tốc độ nào?',
          subtitle: 'Ước tính chỉ là điểm khởi đầu, bạn có thể điều chỉnh sau.',
          selected: _rate,
          options: const [
            _ChoiceOption('slow', 'Từ từ', 'Mức điều chỉnh nhỏ, dễ duy trì',
                Icons.spa_outlined),
            _ChoiceOption(
                'moderate',
                'Ổn định',
                'Cân bằng giữa tiến độ và thói quen',
                Icons.directions_walk_outlined),
            _ChoiceOption('fast', 'Nhanh hơn', 'Mức điều chỉnh lớn hơn',
                Icons.bolt_outlined),
          ],
          onSelect: (value) => setState(() => _rate = value),
          onNext: _next,
        ),
        _ChoiceQuestion(
          eyebrow: 'THÔNG TIN CƠ THỂ',
          icon: Icons.person_outline_rounded,
          title: 'Giới tính của bạn là gì?',
          subtitle:
              'Thông tin này giúp ước tính nhu cầu năng lượng phù hợp hơn.',
          selected: _sex,
          options: const [
            _ChoiceOption('female', 'Nữ', 'Dùng công thức sinh lý nữ',
                Icons.female_rounded),
            _ChoiceOption('male', 'Nam', 'Dùng công thức sinh lý nam',
                Icons.male_rounded),
          ],
          onSelect: (value) => setState(() => _sex = value),
          onNext: _next,
        ),
        _NameQuestion(
            controller: _nameController,
            onChanged: (value) => setState(() => _name = value),
            onNext: _next),
        _WelcomeStep(name: _name, onNext: _next),
        _SliderQuestion(
          eyebrow: 'THÔNG TIN CƠ THỂ',
          icon: Icons.cake_outlined,
          title: 'Bạn bao nhiêu tuổi?',
          subtitle: 'Tuổi ảnh hưởng đến mức năng lượng cơ thể sử dụng.',
          value: _age.toDouble(),
          min: 10,
          max: 80,
          divisions: 70,
          unit: 'tuổi',
          format: (value) => value.toInt().toString(),
          onChanged: (value) => setState(() => _age = value.toInt()),
          onNext: _next,
        ),
        _SliderQuestion(
          eyebrow: 'THÔNG TIN CƠ THỂ',
          icon: Icons.height_rounded,
          title: 'Chiều cao của bạn?',
          subtitle: 'Điều chỉnh để chọn số đo gần nhất.',
          value: _height,
          min: 140,
          max: 220,
          divisions: 80,
          unit: 'cm',
          format: (value) => value.toInt().toString(),
          onChanged: (value) => setState(() => _height = value),
          onNext: _next,
        ),
        _SliderQuestion(
          eyebrow: 'THÔNG TIN CƠ THỂ',
          icon: Icons.monitor_weight_outlined,
          title: 'Cân nặng hiện tại?',
          subtitle: 'Dùng làm mốc ban đầu để theo dõi tiến trình.',
          value: _weight,
          min: 30,
          max: 200,
          divisions: 170,
          unit: 'kg',
          format: (value) => value.toStringAsFixed(1),
          onChanged: (value) => setState(() => _weight = value),
          onNext: _next,
        ),
        _SliderQuestion(
          eyebrow: 'MỤC TIÊU CỦA BẠN',
          icon: Icons.flag_circle_outlined,
          title: 'Cân nặng mục tiêu?',
          subtitle: 'Bạn có thể thay đổi mục tiêu bất cứ lúc nào.',
          value: _target,
          min: 30,
          max: 200,
          divisions: 170,
          unit: 'kg',
          format: (value) => value.toStringAsFixed(1),
          onChanged: (value) => setState(() => _target = value),
          onNext: _next,
        ),
        _ChoiceQuestion(
          eyebrow: 'VẬN ĐỘNG',
          icon: Icons.directions_run_outlined,
          title: 'Mức độ vận động thường ngày?',
          subtitle: 'Hãy chọn mức gần nhất với lịch sinh hoạt của bạn.',
          selected: _activity,
          options: const [
            _ChoiceOption('sedentary', 'Ít vận động',
                'Ngồi nhiều, ít tập thể dục', Icons.weekend_outlined),
            _ChoiceOption('light', 'Vận động nhẹ',
                'Tập khoảng 1–3 ngày mỗi tuần', Icons.directions_walk_outlined),
            _ChoiceOption('moderate', 'Vừa phải',
                'Tập khoảng 3–5 ngày mỗi tuần', Icons.directions_bike_outlined),
            _ChoiceOption(
                'active',
                'Năng động',
                'Tập cường độ cao 6–7 ngày mỗi tuần',
                Icons.fitness_center_outlined),
            _ChoiceOption('very_active', 'Rất năng động',
                'Công việc thể lực và thường xuyên tập', Icons.bolt_outlined),
          ],
          onSelect: (value) => setState(() => _activity = value),
          onNext: _next,
        ),
        _ChoiceQuestion(
          eyebrow: 'THÓI QUEN ĂN UỐNG',
          icon: Icons.restaurant_outlined,
          title: 'Bạn có chế độ ăn đặc biệt?',
          subtitle: 'Chọn lựa chọn phù hợp nhất với bạn.',
          selected: _diet,
          options: const [
            _ChoiceOption('none', 'Không hạn chế', 'Tôi ăn đa dạng thực phẩm',
                Icons.restaurant_menu_outlined),
            _ChoiceOption(
                'vegetarian', 'Ăn chay', 'Không ăn thịt', Icons.eco_outlined),
            _ChoiceOption('vegan', 'Thuần chay', 'Không dùng sản phẩm động vật',
                Icons.spa_outlined),
            _ChoiceOption('gluten_free', 'Không gluten',
                'Hạn chế lúa mì và gluten', Icons.grain_outlined),
            _ChoiceOption('dairy_free', 'Không sữa',
                'Tránh sữa và sản phẩm từ sữa', Icons.water_drop_outlined),
          ],
          onSelect: (value) => setState(() => _diet = value),
          onNext: _next,
        ),
        _ChoiceQuestion(
          eyebrow: 'LỊCH ĂN',
          icon: Icons.restaurant_menu_outlined,
          title: 'Bạn thường ăn mấy bữa một ngày?',
          subtitle: 'Kế hoạch sẽ chia mục tiêu calo theo số bữa này.',
          selected: '$_meals',
          options: const [
            _ChoiceOption(
                '2', '2 bữa', 'Các bữa lớn hơn', Icons.looks_two_outlined),
            _ChoiceOption(
                '3', '3 bữa', 'Sáng, trưa và tối', Icons.looks_3_outlined),
            _ChoiceOption(
                '4', '4 bữa', 'Chia đều trong ngày', Icons.looks_4_outlined),
            _ChoiceOption('5', '5 bữa trở lên', 'Nhiều bữa nhỏ',
                Icons.more_horiz_rounded),
          ],
          onSelect: (value) => setState(() => _meals = int.parse(value)),
          onNext: _next,
        ),
        _ChoiceQuestion(
          eyebrow: 'VẬN ĐỘNG',
          icon: Icons.fitness_center_outlined,
          title: 'Bạn tập thể dục thường xuyên thế nào?',
          subtitle: 'Tính trung bình trong một tuần.',
          selected: _exercise,
          options: const [
            _ChoiceOption('never', 'Hiếm khi', 'Chưa có lịch tập cố định',
                Icons.self_improvement_outlined),
            _ChoiceOption('1_2', '1–2 buổi', 'Thỉnh thoảng vận động',
                Icons.looks_two_outlined),
            _ChoiceOption('3_4', '3–4 buổi', 'Có lịch tập đều đặn',
                Icons.calendar_today_outlined),
            _ChoiceOption('5_plus', '5 buổi trở lên', 'Tập luyện thường xuyên',
                Icons.bolt_outlined),
          ],
          onSelect: (value) => setState(() => _exercise = value),
          onNext: _next,
        ),
        _ChoiceQuestion(
          eyebrow: 'PHỤC HỒI',
          icon: Icons.bedtime_outlined,
          title: 'Bạn thường ngủ bao lâu?',
          subtitle: 'Giấc ngủ góp phần vào quá trình phục hồi.',
          selected: _sleep,
          options: const [
            _ChoiceOption('less_6', 'Dưới 6 giờ', 'Thường ngủ muộn hoặc ít ngủ',
                Icons.nights_stay_outlined),
            _ChoiceOption('6_7', '6–7 giờ', 'Thời lượng ngủ vừa phải',
                Icons.bed_outlined),
            _ChoiceOption('7_8', '7–8 giờ', 'Khoảng thời gian phổ biến',
                Icons.bedtime_outlined),
            _ChoiceOption('8_plus', 'Trên 8 giờ', 'Thời gian nghỉ ngơi dài hơn',
                Icons.hotel_outlined),
          ],
          onSelect: (value) {
            setState(() => _sleep = value);
            _computeCalories();
          },
          onNext: _next,
        ),
        _PlanResult(
          name: _name,
          goal: _goal,
          rate: _rate,
          calories: _calories,
          protein: _protein,
          carbs: _carbs,
          fat: _fat,
          meals: _meals,
          onSignIn: _onSignIn,
        ),
      ];

  Future<void> _onSignIn() async {
    final account = await AuthService().signInWithGoogle();
    if (!mounted) return;
    if (account == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            AuthService().lastSignInError ?? 'Đăng nhập thất bại. Thử lại.'),
        duration: const Duration(seconds: 8),
      ));
      return;
    }

    // If this Google account already has a profile, preserve it and its goals;
    // the onboarding answers must never overwrite an existing account.
    final existing = await AuthService().loadProfile();
    if (existing != null) {
      final provider = context.read<AppProvider>();
      await context.read<LifestyleProvider>().configureMeasurements(
            weight: existing.weight,
            targetWeight: existing.targetWeight,
            height: existing.height,
            age: existing.age,
            sex: existing.sex,
            activity: existing.activity,
            goal: existing.goal,
            rate: existing.rate,
          );
      await provider.updateCalorieGoal(existing.dailyCalories);
      await provider.updateMacroGoals(
          protein: existing.proteinGoal,
          carbs: existing.carbsGoal,
          fat: existing.fatGoal);
      await provider.loadAccountDataFromBackend();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute<void>(builder: (_) => const MainScreen()),
          (_) => false);
      return;
    }

    final profile = UserProfile(
      uid: account.id,
      name: _name,
      goal: _goal,
      rate: _rate,
      sex: _sex,
      age: _age,
      height: _height,
      weight: _weight,
      targetWeight: _target,
      activity: _activity,
      diet: _diet,
      mealsPerDay: _meals,
      exercise: _exercise,
      sleep: _sleep,
      dailyCalories: _calories,
      proteinGoal: _protein,
      carbsGoal: _carbs,
      fatGoal: _fat,
      email: account.email,
      photoUrl: account.photoUrl,
      createdAt: DateTime.now(),
    );
    await AuthService().saveProfile(profile);
    if (!mounted) return;
    final provider = context.read<AppProvider>();
    await provider.updateCalorieGoal(_calories);
    await provider.updateMacroGoals(
        protein: _protein, carbs: _carbs, fat: _fat);
    await context.read<LifestyleProvider>().configureMeasurements(
          weight: profile.weight,
          targetWeight: profile.targetWeight,
          height: profile.height,
          age: profile.age,
          sex: profile.sex,
          activity: profile.activity,
          goal: profile.goal,
          rate: profile.rate,
        );
    await provider.loadAccountDataFromBackend();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(builder: (_) => const MainScreen()),
        (_) => false);
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader(
      {required this.page, required this.total, required this.onBack});
  final int page;
  final int total;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final progress = ((page + 1) / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 22, 0),
      child: Row(children: [
        IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back_rounded, color: p.textPrimary),
            tooltip: 'Quay lại'),
        const SizedBox(width: 8),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text('Bước ${page + 1} trên $total',
                    style: TextStyle(color: p.textSecondary, fontSize: 11))),
            Text('${(progress * 100).round()}%',
                style: TextStyle(
                    color: p.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600))
          ]),
          const SizedBox(height: 7),
          ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: p.surfaceRaised,
                  color: p.brand)),
        ])),
      ]),
    );
  }
}

class _ChoiceOption {
  const _ChoiceOption(this.value, this.title, this.detail, this.icon);
  final String value;
  final String title;
  final String detail;
  final IconData icon;
}

class _ChoiceQuestion extends StatelessWidget {
  const _ChoiceQuestion({
    required this.eyebrow,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
    required this.onSelect,
    required this.onNext,
  });
  final String eyebrow;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<_ChoiceOption> options;
  final String selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 18),
          children: [
            Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: p.brandSoft,
                    borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: p.brand, size: 23)),
            const SizedBox(height: 22),
            Text(eyebrow,
                style: TextStyle(
                    color: p.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontSize: 27, height: 1.13)),
            const SizedBox(height: 8),
            Text(subtitle,
                style: TextStyle(
                    color: p.textSecondary, fontSize: 13, height: 1.45)),
            const SizedBox(height: 23),
            ...options.map((option) {
              final isSelected = selected == option.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelect(option.value);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 170),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: isSelected ? p.brandSoft : p.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                          color:
                              isSelected ? p.brand.withOpacity(.65) : p.outline,
                          width: isSelected ? 1.4 : 1),
                    ),
                    child: Row(children: [
                      Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                              color: isSelected
                                  ? p.brand.withOpacity(.12)
                                  : p.surfaceRaised,
                              borderRadius: BorderRadius.circular(13)),
                          child: Icon(option.icon,
                              color: isSelected ? p.brand : p.textSecondary,
                              size: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(option.title,
                                style: TextStyle(
                                    color: p.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(option.detail,
                                style: TextStyle(
                                    color: p.textSecondary, fontSize: 11))
                          ])),
                      AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 21,
                          height: 21,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: isSelected ? p.brand : p.outline,
                                  width: isSelected ? 6 : 1.5))),
                    ]),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            Text('Thông tin này chỉ dùng để cá nhân hóa mục tiêu của bạn.',
                style: TextStyle(
                    color: p.textSecondary, fontSize: 10, height: 1.4)),
          ],
        ),
      ),
      _BottomContinue(onPressed: selected.isEmpty ? null : onNext),
    ]);
  }
}

class _NameQuestion extends StatelessWidget {
  const _NameQuestion(
      {required this.controller,
      required this.onChanged,
      required this.onNext});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(children: [
      Expanded(
          child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 32, 22, 18),
              children: [
            Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: p.brandSoft,
                    borderRadius: BorderRadius.circular(16)),
                child:
                    Icon(Icons.waving_hand_outlined, color: p.brand, size: 23)),
            const SizedBox(height: 22),
            Text('CÁ NHÂN HÓA',
                style: TextStyle(
                    color: p.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Text('Bạn muốn được gọi là gì?',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontSize: 27)),
            const SizedBox(height: 8),
            Text('Tên của bạn sẽ xuất hiện trong lời chào và kế hoạch.',
                style: TextStyle(color: p.textSecondary, fontSize: 13)),
            const SizedBox(height: 25),
            TextField(
                controller: controller,
                onChanged: onChanged,
                textCapitalization: TextCapitalization.words,
                maxLength: 40,
                decoration: const InputDecoration(
                    labelText: 'Tên của bạn', hintText: 'Nhập tên')),
          ])),
      _BottomContinue(
          onPressed: controller.text.trim().length < 2 ? null : onNext),
    ]);
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.name, required this.onNext});
  final String name;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(children: [
      Expanded(
          child: Center(
              child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                            color: p.brand, shape: BoxShape.circle),
                        child: Icon(Icons.waving_hand_outlined,
                            color: p.onBrand, size: 38)),
                    const SizedBox(height: 28),
                    Text('Chào mừng${name.isEmpty ? '' : ','}',
                        style: TextStyle(color: p.textSecondary, fontSize: 16)),
                    if (name.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(fontSize: 36))
                    ],
                    const SizedBox(height: 12),
                    Text(
                        'Hãy hoàn thiện vài thông tin để tạo kế hoạch phù hợp với bạn.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: p.textSecondary, fontSize: 14, height: 1.5)),
                  ])))),
      _BottomContinue(onPressed: onNext, label: 'Tiếp tục'),
    ]);
  }
}

class _SliderQuestion extends StatelessWidget {
  const _SliderQuestion({
    required this.eyebrow,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.unit,
    required this.format,
    required this.onChanged,
    required this.onNext,
  });
  final String eyebrow;
  final IconData icon;
  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String unit;
  final String Function(double) format;
  final ValueChanged<double> onChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(children: [
      Expanded(
          child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 18),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: p.brandSoft,
                            borderRadius: BorderRadius.circular(16)),
                        child: Icon(icon, color: p.brand, size: 23)),
                    const SizedBox(height: 22),
                    Text(eyebrow,
                        style: TextStyle(
                            color: p.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontSize: 27)),
                    const SizedBox(height: 8),
                    Text(subtitle,
                        style: TextStyle(color: p.textSecondary, fontSize: 13)),
                    const Spacer(),
                    Center(
                        child: Column(children: [
                      Text(format(value),
                          style: TextStyle(
                              color: p.textPrimary,
                              fontSize: 52,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1.5,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ])),
                      Text(unit,
                          style:
                              TextStyle(color: p.textSecondary, fontSize: 13)),
                    ])),
                    const SizedBox(height: 22),
                    SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                            activeTrackColor: p.brand,
                            inactiveTrackColor: p.surfaceRaised,
                            thumbColor: p.brand,
                            overlayColor: p.brand.withOpacity(.14),
                            trackHeight: 5,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 12)),
                        child: Slider(
                            value: value.clamp(min, max),
                            min: min,
                            max: max,
                            divisions: divisions,
                            onChanged: onChanged)),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${min.toInt()} $unit',
                              style: TextStyle(
                                  color: p.textSecondary, fontSize: 10)),
                          Text('${max.toInt()} $unit',
                              style: TextStyle(
                                  color: p.textSecondary, fontSize: 10))
                        ]),
                    const Spacer(),
                  ]))),
      _BottomContinue(onPressed: onNext),
    ]);
  }
}

class _PlanResult extends StatefulWidget {
  const _PlanResult(
      {required this.name,
      required this.goal,
      required this.rate,
      required this.calories,
      required this.protein,
      required this.carbs,
      required this.fat,
      required this.meals,
      required this.onSignIn});
  final String name;
  final String goal;
  final String rate;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final int meals;
  final Future<void> Function() onSignIn;

  @override
  State<_PlanResult> createState() => _PlanResultState();
}

class _PlanResultState extends State<_PlanResult>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..forward();
  late Animation<int> _count = IntTween(begin: 0, end: widget.calories).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  bool _signingIn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final meals = switch (widget.meals) {
      2 => ['Bữa sáng', 'Bữa tối'],
      4 => ['Bữa sáng', 'Bữa trưa', 'Bữa phụ', 'Bữa tối'],
      5 => ['Bữa sáng', 'Bữa phụ sáng', 'Bữa trưa', 'Bữa phụ chiều', 'Bữa tối'],
      _ => ['Bữa sáng', 'Bữa trưa', 'Bữa tối'],
    };
    return Column(children: [
      Expanded(
          child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 25, 22, 20),
              children: [
            Text('KẾ HOẠCH CỦA BẠN',
                style: TextStyle(
                    color: p.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Text('${widget.name}, kế hoạch đã sẵn sàng',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontSize: 25)),
            const SizedBox(height: 6),
            Text(
                '${_goalName(widget.goal)} · Nhịp độ ${_rateName(widget.rate).toLowerCase()}',
                style: TextStyle(color: p.textSecondary, fontSize: 12)),
            const SizedBox(height: 23),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 21, 20, 19),
              decoration: BoxDecoration(
                  color: p.brand,
                  borderRadius: BorderRadius.circular(AppRadius.lg)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MỤC TIÊU NĂNG LƯỢNG',
                        style: TextStyle(
                            color: p.onBrand.withOpacity(.75),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 9),
                    AnimatedBuilder(
                        animation: _count,
                        builder: (_, __) => Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${_count.value}',
                                      style: TextStyle(
                                          color: p.onBrand,
                                          fontSize: 48,
                                          fontWeight: FontWeight.w700,
                                          height: 1,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures()
                                          ])),
                                  const SizedBox(width: 8),
                                  Padding(
                                      padding: const EdgeInsets.only(bottom: 5),
                                      child: Text('kcal / ngày',
                                          style: TextStyle(
                                              color: p.onBrand.withOpacity(.75),
                                              fontSize: 12)))
                                ])),
                  ]),
            ),
            const SizedBox(height: 18),
            Text('MỤC TIÊU DINH DƯỠNG',
                style: TextStyle(
                    color: p.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2)),
            const SizedBox(height: 9),
            Row(children: [
              Expanded(
                  child: _MacroTarget(
                      name: 'Protein',
                      value: widget.protein,
                      color: p.protein)),
              const SizedBox(width: 8),
              Expanded(
                  child: _MacroTarget(
                      name: 'Carbs', value: widget.carbs, color: p.carbs)),
              const SizedBox(width: 8),
              Expanded(
                  child: _MacroTarget(
                      name: 'Fat', value: widget.fat, color: p.fat)),
            ]),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gợi ý chia bữa',
                        style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    ...meals.asMap().entries.map((entry) => Padding(
                        padding: EdgeInsets.only(
                            bottom: entry.key == meals.length - 1 ? 0 : 10),
                        child: Row(children: [
                          Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  color: p.brand, shape: BoxShape.circle)),
                          const SizedBox(width: 9),
                          Expanded(
                              child: Text(entry.value,
                                  style: TextStyle(
                                      color: p.textSecondary, fontSize: 12))),
                          Text(
                              '~${(widget.calories / meals.length).round()} kcal',
                              style: TextStyle(
                                  color: p.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600))
                        ]))),
                  ]),
            ),
            const SizedBox(height: 12),
            Text(
                'Đây là mức ước tính ban đầu. Hãy điều chỉnh theo cảm nhận và hướng dẫn chuyên môn khi cần.',
                style: TextStyle(
                    color: p.textSecondary, fontSize: 10, height: 1.4)),
          ])),
      SafeArea(
          top: false,
          child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 9, 20, 13),
              child: Column(children: [
                SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                        onPressed: _signingIn ? null : _signIn,
                        child: _signingIn
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                    Icon(Icons.g_mobiledata_rounded, size: 24),
                                    SizedBox(width: 8),
                                    Text('Tiếp tục với Google')
                                  ]))),
                const SizedBox(height: 7),
                Text('Đăng nhập để lưu hồ sơ và đồng bộ nhật ký.',
                    style: TextStyle(color: p.textSecondary, fontSize: 10)),
              ]))),
    ]);
  }

  Future<void> _signIn() async {
    setState(() => _signingIn = true);
    try {
      await widget.onSignIn();
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  String _goalName(String goal) => switch (goal) {
        'lose_weight' => 'Giảm cân',
        'gain_weight' => 'Tăng cân',
        'build_muscle' => 'Tăng cơ',
        _ => 'Duy trì cân nặng',
      };

  String _rateName(String rate) => switch (rate) {
        'slow' => 'từ từ',
        'fast' => 'nhanh hơn',
        _ => 'ổn định',
      };
}

class _MacroTarget extends StatelessWidget {
  const _MacroTarget(
      {required this.name, required this.value, required this.color});
  final String name;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
        decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(height: 10),
          Text('${value.round()}g',
              style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(name, style: TextStyle(color: p.textSecondary, fontSize: 10))
        ]));
  }
}

class _BottomContinue extends StatelessWidget {
  const _BottomContinue({required this.onPressed, this.label = 'Tiếp tục'});
  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) => SafeArea(
      top: false,
      child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 9, 20, 12),
          child: SizedBox(
              width: double.infinity,
              height: 54,
              child:
                  ElevatedButton(onPressed: onPressed, child: Text(label)))));
}

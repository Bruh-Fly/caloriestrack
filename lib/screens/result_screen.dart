import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/food_result.dart';
import '../models/meal_entry.dart';
import '../providers/app_provider.dart';
import '../services/share_card_service.dart';
import '../theme/app_theme.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen(
      {super.key,
      required this.result,
      required this.imageFile,
      this.mealType});
  final FoodResult result;
  final File imageFile;
  final String? mealType;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late FoodResult _result = widget.result;
  late final AnimationController _countController;
  late Animation<int> _calorieCount;
  bool _saving = false;
  bool _saved = false;
  late String _mealType = widget.mealType ?? _suggestMealType();

  @override
  void initState() {
    super.initState();
    _countController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _calorieCount = IntTween(begin: 0, end: _result.calories).animate(
        CurvedAnimation(parent: _countController, curve: Curves.easeOutCubic));
    _countController.forward();
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  static String _suggestMealType() {
    final hour = DateTime.now().hour;
    if (hour < 10) return 'breakfast';
    if (hour < 14) return 'lunch';
    if (hour < 17) return 'snack';
    return 'dinner';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: false,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _RoundAction(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context)),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(widget.imageFile,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          color: p.surfaceRaised,
                          child: Icon(Icons.restaurant_outlined,
                              color: p.textSecondary, size: 42))),
                  DecoratedBox(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                        Colors.black.withOpacity(.12),
                        Colors.transparent,
                        p.background.withOpacity(.97)
                      ],
                              stops: const [
                        0,
                        .48,
                        1
                      ]))),
                  Positioned(
                      left: 22,
                      bottom: 24,
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: 7),
                          decoration: BoxDecoration(
                              color: p.surface.withOpacity(.92),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.auto_awesome_outlined,
                                size: 14, color: p.brand),
                            const SizedBox(width: 6),
                            Text('KẾT QUẢ PHÂN TÍCH',
                                style: TextStyle(
                                    color: p.textPrimary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1))
                          ]))),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(_result.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontSize: 24)),
                            const SizedBox(height: 5),
                            Text(_result.serving,
                                style: TextStyle(
                                    color: p.textSecondary, fontSize: 12)),
                          ])),
                      IconButton.filledTonal(
                          onPressed: _saved ? null : _editResult,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Chỉnh sửa kết quả'),
                    ],
                  ),
                  if (_result.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    Text(_result.description!,
                        style: TextStyle(
                            color: p.textSecondary,
                            fontSize: 13,
                            height: 1.45)),
                  ],
                  const SizedBox(height: 24),
                  Text('BỮA ĂN',
                      style: TextStyle(
                          color: p.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4)),
                  const SizedBox(height: 10),
                  _MealTypeSelector(
                      selected: _mealType,
                      onSelect: (value) => setState(() => _mealType = value)),
                  const SizedBox(height: 23),
                  Row(children: [
                    Expanded(
                        child: Text('Thông tin dinh dưỡng',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontSize: 16))),
                    TextButton(
                        onPressed: _saved ? null : _editResult,
                        child: Text('Sửa',
                            style: TextStyle(
                                color: p.brand, fontWeight: FontWeight.w600))),
                  ]),
                  const SizedBox(height: 8),
                  _NutritionGrid(result: _result, calorieCount: _calorieCount),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: p.brandSoft.withOpacity(.65),
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: p.brand, size: 18),
                          const SizedBox(width: 9),
                          Expanded(
                              child: Text(
                                  'Ước tính dinh dưỡng có thể sai khác. Bạn có thể chỉnh sửa trước khi lưu.',
                                  style: TextStyle(
                                      color: p.textSecondary,
                                      fontSize: 11,
                                      height: 1.4)))
                        ]),
                  ),
                ],
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 110)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            OutlinedButton.icon(
              onPressed: () => ShareCardService.shareMeal(
                title: _result.name,
                meals: [
                  MealEntry.fromFoodResult(
                    _result,
                    id: 'share-preview',
                    timestamp: DateTime.now(),
                    imagePath: widget.imageFile.path,
                    mealType: _mealType,
                  )
                ],
                imagePath: widget.imageFile.path,
              ),
              icon: const Icon(Icons.ios_share),
              label: const Text('Share to Locket / apps'),
            ),
            const SizedBox(height: 5),
            SizedBox(
              height: 54,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving || _saved ? null : _logMeal,
                icon: Icon(
                    _saved ? Icons.check_rounded : Icons.bookmark_add_outlined,
                    size: 19),
                label: Text(_saved
                    ? 'Đã lưu vào nhật ký'
                    : _saving
                        ? 'Đang lưu…'
                        : 'Lưu vào nhật ký'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _logMeal() async {
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    try {
      await context.read<AppProvider>().logMeal(_result,
          imagePath: widget.imageFile.path, mealType: _mealType);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã lưu ${_result.name} vào nhật ký.')));
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể lưu món ăn: $error')));
    }
  }

  Future<void> _editResult() async {
    final name = TextEditingController(text: _result.name);
    final serving = TextEditingController(text: _result.serving);
    final calories = TextEditingController(text: '${_result.calories}');
    final protein =
        TextEditingController(text: _result.protein.toStringAsFixed(1));
    final carbs = TextEditingController(text: _result.carbs.toStringAsFixed(1));
    final fat = TextEditingController(text: _result.fat.toStringAsFixed(1));
    final p = context.palette;

    final edited = await showModalBottomSheet<FoodResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
            22, 14, 22, MediaQuery.viewInsetsOf(sheetContext).bottom + 20),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 35,
                      height: 4,
                      decoration: BoxDecoration(
                          color: p.outline,
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill)))),
              const SizedBox(height: 18),
              Text('Chỉnh sửa ước tính',
                  style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 15),
              Flexible(
                  child: SingleChildScrollView(
                      child: Column(children: [
                _editField(name, 'Tên món'),
                _editField(serving, 'Khẩu phần'),
                Row(children: [
                  Expanded(child: _editField(calories, 'Calo', numeric: true)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _editField(protein, 'Protein (g)', numeric: true))
                ]),
                Row(children: [
                  Expanded(
                      child: _editField(carbs, 'Carbs (g)', numeric: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _editField(fat, 'Fat (g)', numeric: true))
                ]),
              ]))),
              const SizedBox(height: 14),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: () {
                        final c = int.tryParse(calories.text);
                        final pr = double.tryParse(protein.text);
                        final cb = double.tryParse(carbs.text);
                        final ft = double.tryParse(fat.text);
                        if (name.text.trim().isEmpty ||
                            serving.text.trim().isEmpty ||
                            c == null ||
                            pr == null ||
                            cb == null ||
                            ft == null ||
                            c < 0 ||
                            pr < 0 ||
                            cb < 0 ||
                            ft < 0) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text(
                                  'Kiểm tra lại tên, khẩu phần và các giá trị dinh dưỡng.')));
                          return;
                        }
                        Navigator.pop(
                            sheetContext,
                            _result.copyWith(
                                name: name.text.trim(),
                                serving: serving.text.trim(),
                                calories: c,
                                protein: pr,
                                carbs: cb,
                                fat: ft));
                      },
                      child: const Text('Áp dụng'))),
            ]),
      ),
    );
    name.dispose();
    serving.dispose();
    calories.dispose();
    protein.dispose();
    carbs.dispose();
    fat.dispose();
    if (edited == null || !mounted) return;
    setState(() {
      _result = edited;
      _calorieCount = IntTween(begin: _calorieCount.value, end: edited.calories)
          .animate(CurvedAnimation(
              parent: _countController, curve: Curves.easeOutCubic));
      _countController.forward(from: 0);
    });
  }

  Widget _editField(TextEditingController controller, String label,
          {bool numeric = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: controller,
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          inputFormatters: numeric
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
              : null,
          decoration: InputDecoration(labelText: label),
        ),
      );
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
      color: context.palette.surface.withOpacity(.94),
      shape: const CircleBorder(),
      child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
              width: 38,
              height: 38,
              child:
                  Icon(icon, color: context.palette.textPrimary, size: 19))));
}

class _MealTypeSelector extends StatelessWidget {
  const _MealTypeSelector({required this.selected, required this.onSelect});
  final String selected;
  final ValueChanged<String> onSelect;
  static const options = [
    ('breakfast', 'Sáng', Icons.wb_sunny_outlined),
    ('lunch', 'Trưa', Icons.light_mode_outlined),
    ('dinner', 'Tối', Icons.nightlight_outlined),
    ('snack', 'Phụ', Icons.cookie_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Wrap(
        spacing: 7,
        runSpacing: 7,
        children: options.map((option) {
          final active = selected == option.$1;
          return ChoiceChip(
            selected: active,
            showCheckmark: false,
            onSelected: (_) => onSelect(option.$1),
            avatar: Icon(option.$3,
                size: 15, color: active ? p.onBrand : p.textSecondary),
            label: Text(option.$2),
            labelStyle: TextStyle(
                color: active ? p.onBrand : p.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600),
            backgroundColor: p.surface,
            selectedColor: p.brand,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill)),
          );
        }).toList());
  }
}

class _NutritionGrid extends StatelessWidget {
  const _NutritionGrid({required this.result, required this.calorieCount});
  final FoodResult result;
  final Animation<int> calorieCount;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final items = [
      ('Calo', '${result.calories}', 'kcal', p.brand),
      ('Protein', result.protein.toStringAsFixed(0), 'g', p.protein),
      ('Carbs', result.carbs.toStringAsFixed(0), 'g', p.carbs),
      ('Fat', result.fat.toStringAsFixed(0), 'g', p.fat),
    ];
    return Row(
      children: List.generate(items.length, (index) {
        final item = items[index];
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == items.length - 1 ? 0 : 7),
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 7),
            decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Column(children: [
              if (index == 0)
                AnimatedBuilder(
                    animation: calorieCount,
                    builder: (_, __) => Text('${calorieCount.value}',
                        style: TextStyle(
                            color: item.$4,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            height: 1.2)))
              else
                Text(item.$2,
                    style: TextStyle(
                        color: item.$4,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.2)),
              const SizedBox(height: 5),
              Text('${item.$1} · ${item.$3}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.textSecondary, fontSize: 9)),
            ]),
          ),
        );
      }),
    );
  }
}

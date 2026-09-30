import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/food_result.dart';
import '../providers/app_provider.dart';
import '../providers/language_provider.dart';
import '../services/app_text.dart';
import '../theme/app_theme.dart';
import 'camera_screen.dart';

class TrackFoodScreen extends StatefulWidget {
  const TrackFoodScreen({super.key, required this.mealType});
  final String mealType;
  @override
  State<TrackFoodScreen> createState() => _TrackFoodScreenState();
}

class _Food {
  const _Food(this.name, this.kcal, this.protein, this.carbs, this.fat,
      {this.serving = '100 g', this.image});
  final String name, serving;
  final int kcal;
  final double protein, carbs, fat;
  final String? image;
  factory _Food.fromOff(Map<String, dynamic> p) {
    final n = p['nutriments'] as Map<String, dynamic>? ?? {};
    double val(List<String> keys) {
      for (final key in keys) {
        final v = n[key];
        if (v is num) return v.toDouble();
        final parsed = double.tryParse('$v');
        if (parsed != null) return parsed;
      }
      return 0;
    }

    return _Food(
        (p['product_name'] as String?)?.trim().isNotEmpty == true
            ? (p['product_name'] as String).trim()
            : 'Food product',
        val(['energy-kcal_100g', 'energy-kcal_value']).round(),
        val(['proteins_100g']),
        val(['carbohydrates_100g']),
        val(['fat_100g']),
        serving: '100 g',
        image: p['image_front_small_url'] as String?);
  }
  FoodResult result(double grams) => FoodResult(
      name: name,
      calories: (kcal * grams / 100).round(),
      protein: protein * grams / 100,
      carbs: carbs * grams / 100,
      fat: fat * grams / 100,
      serving: '${grams.round()} g');
}

class _TrackFoodScreenState extends State<TrackFoodScreen> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  List<_Food> _foods = [];
  bool _loading = false;
  String? _error;
  int _added = 0;
  late String _mealType = widget.mealType;
  static const _sample = <_Food>[
    _Food('White rice, cooked', 130, 2.7, 28.2, .3),
    _Food('Chicken breast, cooked', 165, 31, 0, 3.6),
    _Food('Banana', 89, 1.1, 22.8, .3),
    _Food('Olive oil', 884, 0, 0, 100),
    _Food('Broccoli, cooked', 35, 2.4, 7.2, .4),
    _Food('Avocado', 160, 2, 8.5, 14.7),
    _Food('Egg, whole', 143, 12.6, .7, 9.5),
    _Food('Strawberries', 32, .7, 7.7, .3),
  ];

  @override
  void initState() {
    super.initState();
    _foods = _sample;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _searchOnline(String query) async {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _foods = _sample;
        _loading = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      if (!mounted) return;
      setState(() {
        _loading = true;
        _error = null;
      });
      try {
        final uri = Uri.https('world.openfoodfacts.org', '/cgi/search.pl', {
          'search_terms': query.trim(),
          'search_simple': '1',
          'action': 'process',
          'json': '1',
          'page_size': '30',
          'fields': 'product_name,nutriments,image_front_small_url',
          'lc': context.read<LanguageProvider>().code,
        });
        final response = await http.get(uri, headers: {
          'User-Agent': 'CaloAI/1.0 (food tracker)'
        }).timeout(const Duration(seconds: 12));
        if (response.statusCode != 200)
          throw Exception('Search service is unavailable.');
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final products =
            (json['products'] as List? ?? []).whereType<Map<String, dynamic>>();
        final results = products
            .map(_Food.fromOff)
            .where((f) => f.name != 'Food product')
            .toList();
        if (!mounted) return;
        setState(() {
          _foods = results;
          _loading = false;
          if (results.isEmpty)
            _error =
                'Không tìm thấy món. Thử tên tiếng Anh hoặc thêm thủ công bằng Voice/Text.';
        });
      } catch (_) {
        if (mounted)
          setState(() {
            _loading = false;
            _foods = [];
            _error =
                'Không thể tìm trực tuyến. Kiểm tra kết nối mạng rồi thử lại.';
          });
      }
    });
  }

  Future<void> _barcode() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Tra cứu mã vạch'),
              content: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Nhập hoặc quét mã vạch')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Hủy')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                    child: const Text('Tra cứu'))
              ],
            ));
    controller.dispose();
    if (code == null || code.isEmpty || !mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final url = Uri.https(
          'world.openfoodfacts.org',
          '/api/v2/product/$code.json',
          {'fields': 'product_name,nutriments,image_front_small_url'});
      final response = await http.get(url).timeout(const Duration(seconds: 12));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200 || data['status'] != 1)
        throw Exception('not found');
      final food = _Food.fromOff(data['product'] as Map<String, dynamic>);
      setState(() {
        _foods = [food];
        _loading = false;
      });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'Không tìm thấy sản phẩm có mã vạch này.';
        });
    }
  }

  Future<void> _details(_Food food) async {
    final amount = TextEditingController(text: '100');
    final grams = await showModalBottomSheet<double>(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.palette.surface,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) {
          final p = ctx.palette;
          return Padding(
              padding: EdgeInsets.fromLTRB(
                  22, 20, 22, MediaQuery.viewInsetsOf(ctx).bottom + 22),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${foodEmoji(food.name)}  ${food.name}',
                        style: Theme.of(ctx).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('Dinh dưỡng ước tính trên 100 g',
                        style: TextStyle(color: p.textSecondary)),
                    const SizedBox(height: 15),
                    Text(
                        '${food.kcal} kcal  ·  P ${food.protein.toStringAsFixed(1)} g  ·  C ${food.carbs.toStringAsFixed(1)} g  ·  F ${food.fat.toStringAsFixed(1)} g'),
                    const SizedBox(height: 14),
                    TextField(
                        controller: amount,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Khẩu phần', suffixText: 'g')),
                    const SizedBox(height: 16),
                    SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                            onPressed: () {
                              final v = double.tryParse(
                                  amount.text.replaceAll(',', '.'));
                              if (v != null && v > 0 && v <= 3000)
                                Navigator.pop(ctx, v);
                            },
                            child: const Text('Thêm vào nhật ký'))),
                  ]));
        });
    amount.dispose();
    if (grams == null || !mounted) return;
    final result = food.result(grams);
    await context.read<AppProvider>().logManualMeal(
        name: result.name,
        calories: result.calories,
        protein: result.protein,
        carbs: result.carbs,
        fat: result.fat,
        serving: result.serving,
        mealType: _mealType);
    if (!mounted) return;
    setState(() => _added++);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Đã thêm ${result.name} vào ${mealLabel(_mealType)}')));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
          title: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                  value: _mealType,
                  items: const [
                    DropdownMenuItem(
                        value: 'breakfast', child: Text('Breakfast')),
                    DropdownMenuItem(value: 'lunch', child: Text('Lunch')),
                    DropdownMenuItem(value: 'dinner', child: Text('Dinner')),
                    DropdownMenuItem(value: 'snack', child: Text('Snacks'))
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _mealType = v);
                  })),
          actions: [
            IconButton(
                onPressed: () => setState(() => _mealType = widget.mealType),
                icon: const Icon(Icons.restaurant_menu))
          ]),
      body: Column(children: [
        SizedBox(
            height: 112,
            child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _tool('🔎', context.tr('Search', 'Tìm kiếm'), true,
                      () => FocusScope.of(context).requestFocus(_searchFocus)),
                  _tool('📷', context.tr('Camera', 'Camera'), false, () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CameraScreen(mealType: _mealType)));
                  }),
                  _tool('▥', context.tr('Barcode', 'Mã vạch'), false, _barcode),
                  _tool('🎙️', context.tr('Voice/Text', 'Giọng nói/Văn bản'),
                      false, () {
                    FocusScope.of(context).requestFocus(_searchFocus);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Nhấn ô tìm kiếm rồi dùng micro trên bàn phím để nhập bằng giọng nói.')));
                  }),
                ])),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: TextField(
                controller: _search,
                focusNode: _searchFocus,
                onChanged: _searchOnline,
                decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: context.tr(
                        'Search food online', 'Tìm món ăn trực tuyến'),
                    suffixIcon: IconButton(
                        onPressed: () {
                          _search.clear();
                          _searchOnline('');
                          setState(() {});
                        },
                        icon: const Icon(Icons.close))))),
        const SizedBox(height: 12),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(children: [
              Expanded(
                  child: Text(_search.text.isEmpty ? 'Foods' : 'Online results',
                      style: Theme.of(context).textTheme.titleMedium)),
              TextButton(onPressed: _barcode, child: const Text('Barcode'))
            ])),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        if (_error != null)
          Padding(
              padding: const EdgeInsets.all(18),
              child: Text(_error!, style: TextStyle(color: p.textSecondary))),
        Expanded(
            child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                itemCount: _foods.length,
                separatorBuilder: (_, __) => Divider(color: p.outline),
                itemBuilder: (ctx, i) {
                  final f = _foods[i];
                  return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text(foodEmoji(f.name),
                          style: const TextStyle(fontSize: 28)),
                      title: Text(f.name,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                          '100 g · P ${f.protein.round()} g · C ${f.carbs.round()} g · F ${f.fat.round()} g',
                          style:
                              TextStyle(color: p.textSecondary, fontSize: 12)),
                      trailing: SizedBox(
                          width: 104,
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text('${f.kcal} kcal',
                                    style: TextStyle(
                                        color: p.textSecondary, fontSize: 12)),
                                IconButton(
                                    onPressed: () => _details(f),
                                    icon: Icon(Icons.add_circle_outline,
                                        color: p.brand, size: 27))
                              ])),
                      onTap: () => _details(f));
                })),
      ]),
      bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                          _added == 0 ? 'Done' : 'Done · $_added added'))))),
    );
  }

  Widget _tool(String emoji, String title, bool selected, VoidCallback onTap) {
    final p = context.palette;
    return InkWell(
        onTap: onTap,
        child: Container(
            width: 88,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
                color: selected ? p.brandSoft : p.surface,
                border: Border.all(
                    color: selected ? p.brand : p.outline,
                    width: selected ? 2 : 1),
                borderRadius: BorderRadius.circular(18)),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 5),
              Text(title,
                  style: TextStyle(
                      fontSize: 11,
                      color: selected ? p.brand : p.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500))
            ])));
  }
}

String mealLabel(String type) => switch (type) {
      'breakfast' => 'Breakfast',
      'lunch' => 'Lunch',
      'dinner' => 'Dinner',
      _ => 'Snacks'
    };
String foodEmoji(String name) {
  final n = name.toLowerCase();
  if (n.contains('rice')) return '🍚';
  if (n.contains('chicken')) return '🐥';
  if (n.contains('banana')) return '🍌';
  if (n.contains('egg')) return '🥚';
  if (n.contains('oil')) return '🫒';
  if (n.contains('broccoli')) return '🥦';
  if (n.contains('avocado')) return '🥑';
  if (n.contains('strawber')) return '🍓';
  if (n.contains('apple')) return '🍎';
  if (n.contains('fish') || n.contains('salmon')) return '🐟';
  if (n.contains('bread')) return '🍞';
  if (n.contains('coffee')) return '☕';
  return '🍽️';
}

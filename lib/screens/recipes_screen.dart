import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../providers/lifestyle_provider.dart';
import '../services/recipe_service.dart';
import '../theme/app_theme.dart';
import '../services/app_text.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});
  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final _service = RecipeService();
  final _search = TextEditingController();
  Timer? _debounce;
  List<String> _areas = [];
  List<Recipe> _recipes = [];
  final Map<String, Recipe> _seen = {};
  String _area = 'Vietnamese';
  String _error = '';
  bool _loading = true, _favorites = false, _wizard = false;
  int _wizardStep = 0;
  String _level = 'Beginner', _time = 'Any time', _diet = 'No preference';
  RangeValues _calorieRange = const RangeValues(100, 900);
  bool _filterCalories = false;
  int _catalogGeneration = 0;
  int _titleLocalizationGeneration = 0;
  int _favoriteLocalizationGeneration = 0;
  String? _activeLanguage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !context.read<LifestyleProvider>().recipesOnboarded)
        setState(() => _wizard = true);
      _ensureFavorites();
    });
    _loadAreas();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode;
    if (_activeLanguage == language) return;
    _activeLanguage = language;
    if (_recipes.isNotEmpty) {
      _localizeCatalogTitles(List.of(_recipes), _catalogGeneration);
    }
    if (_favorites) _localizeFavoriteTitles(language);
  }

  Future<void> _ensureFavorites() async {
    final ids = context.read<LifestyleProvider>().favoriteRecipes;
    final loaded = <Recipe>[];
    for (final id in ids) {
      if (_seen.containsKey(id)) continue;
      try {
        final recipe = await _service.details(id);
        if (recipe != null) loaded.add(recipe);
      } catch (_) {
        // Keep favorites that are already in the in-memory catalog visible.
      }
    }
    if (loaded.isNotEmpty) {
      if (!mounted) return;
      final localized = await _service.localizedTitles(
        loaded,
        Localizations.localeOf(context).languageCode,
      );
      if (!mounted) return;
      for (final recipe in localized) {
        _seen[recipe.id] = recipe;
      }
    }
    if (mounted) {
      setState(() {});
      if (_favorites) {
        _localizeFavoriteTitles(Localizations.localeOf(context).languageCode);
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadAreas() async {
    try {
      final a = await _service.areas();
      if (!mounted) return;
      setState(() => _areas = a);
      final life = context.read<LifestyleProvider>();
      if (life.recipeDiet == 'Vegetarian' || life.recipeDiet == 'Vegan') {
        await _loadCategory(life.recipeDiet);
        return;
      }
      final chosen = a.firstWhere(
        (v) => v.toLowerCase() == 'vietnamese',
        orElse: () => a.isEmpty ? '' : a.first,
      );
      if (chosen.isNotEmpty) {
        setState(() => _area = chosen);
        await _loadArea(chosen);
      }
    } catch (e) {
      if (mounted)
        setState(
          () => _error = context.tr(
            'Could not reach the recipe catalog. Check your internet connection.',
            'Không kết nối được danh sách món ăn. Hãy kiểm tra Internet.',
          ),
        );
    }
  }

  Future<void> _loadArea(String area) async {
    final generation = ++_catalogGeneration;
    setState(() => _loading = true);
    try {
      final list = await _service.byArea(area);
      if (mounted && generation == _catalogGeneration) {
        setState(() {
          _recipes = list;
          for (final r in list) {
            _seen[r.id] = r;
          }
          _loading = false;
          _error = '';
        });
        _localizeCatalogTitles(list, generation);
      }
    } catch (_) {
      if (mounted && generation == _catalogGeneration)
        setState(() {
          _loading = false;
          _error = context.tr(
            'Could not load these recipes. Try again.',
            'Không tải được công thức. Hãy thử lại.',
          );
        });
    }
  }

  Future<void> _loadCategory(String category) async {
    final generation = ++_catalogGeneration;
    setState(() => _loading = true);
    try {
      final list = await _service.byCategory(category);
      if (mounted && generation == _catalogGeneration) {
        setState(() {
          _recipes = list;
          for (final r in list) {
            _seen[r.id] = r;
          }
          _loading = false;
          _error = '';
        });
        _localizeCatalogTitles(list, generation);
      }
    } catch (_) {
      if (mounted && generation == _catalogGeneration)
        setState(() {
          _loading = false;
          _error = context.tr(
            'Could not load this category. Try again.',
            'Không tải được danh mục này. Hãy thử lại.',
          );
        });
    }
  }

  Future<void> _searchRecipes(String value) async {
    if (value.trim().isEmpty) {
      _loadArea(_area);
      return;
    }
    final generation = ++_catalogGeneration;
    setState(() => _loading = true);
    try {
      final list = await _service.search(value.trim());
      if (mounted && generation == _catalogGeneration) {
        setState(() {
          _recipes = list;
          for (final r in list) {
            _seen[r.id] = r;
          }
          _loading = false;
          _error = '';
        });
        _localizeCatalogTitles(list, generation);
      }
    } catch (_) {
      if (mounted && generation == _catalogGeneration)
        setState(() {
          _loading = false;
          _error = context.tr(
            'Online search is temporarily unavailable.',
            'Tìm kiếm trực tuyến hiện không khả dụng.',
          );
        });
    }
  }

  void _localizeCatalogTitles(List<Recipe> recipes, int catalogGeneration) {
    final language = Localizations.localeOf(context).languageCode;
    final localizationGeneration = ++_titleLocalizationGeneration;
    if (language == 'en') {
      final originals = {for (final recipe in recipes) recipe.id: recipe};
      setState(() {
        _recipes = _recipes
            .map((recipe) => originals.containsKey(recipe.id)
                ? recipe.copyWith(
                    name: recipe.sourceName ?? recipe.name,
                    category: recipe.sourceCategory ?? recipe.category,
                    sourceName: recipe.sourceName ?? recipe.name,
                    sourceCategory: recipe.sourceCategory ?? recipe.category,
                  )
                : recipe)
            .toList();
        for (final recipe in recipes) {
          final current = _seen[recipe.id];
          if (current != null) {
            _seen[recipe.id] = current.copyWith(
              name: current.sourceName ?? current.name,
              category: current.sourceCategory ?? current.category,
              sourceName: current.sourceName ?? current.name,
              sourceCategory: current.sourceCategory ?? current.category,
            );
          }
        }
      });
      return;
    }
    unawaited(() async {
      final localized = await _service.localizedTitles(recipes, language);
      if (!mounted ||
          catalogGeneration != _catalogGeneration ||
          localizationGeneration != _titleLocalizationGeneration ||
          Localizations.localeOf(context).languageCode != language) {
        return;
      }
      final byId = {for (final recipe in localized) recipe.id: recipe};
      setState(() {
        _recipes = _recipes
            .map((recipe) => byId[recipe.id] ?? recipe)
            .toList();
        _seen.addAll(byId);
      });
    }());
  }

  void _localizeFavoriteTitles(String language) {
    final recipes = _seen.values
        .where((recipe) =>
            context.read<LifestyleProvider>().favoriteRecipes.contains(recipe.id))
        .toList();
    if (recipes.isEmpty) return;
    final generation = ++_favoriteLocalizationGeneration;
    unawaited(() async {
      final localized = language == 'en'
          ? recipes
              .map((recipe) => recipe.copyWith(
                    name: recipe.sourceName ?? recipe.name,
                    category: recipe.sourceCategory ?? recipe.category,
                    sourceName: recipe.sourceName ?? recipe.name,
                    sourceCategory: recipe.sourceCategory ?? recipe.category,
                  ))
              .toList()
          : await _service.localizedTitles(recipes, language);
      if (!mounted ||
          generation != _favoriteLocalizationGeneration ||
          Localizations.localeOf(context).languageCode != language) {
        return;
      }
      setState(() => _seen.addAll({
            for (final recipe in localized) recipe.id: recipe,
          }));
    }());
  }

  @override
  Widget build(BuildContext context) {
    final life = context.watch<LifestyleProvider>();
    if (_wizard || !life.recipesOnboarded)
      return _wizard ? _welcome(context) : _catalog(context, life);
    return _catalog(context, life);
  }

  Widget _welcome(BuildContext context) {
    final p = context.palette;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 18, 26, 18),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_wizardStep + 1) / 4,
              minHeight: 6,
              borderRadius: BorderRadius.circular(9),
              backgroundColor: p.surfaceRaised,
              color: p.brand,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32,
                    ),
                    child: Align(
                      alignment: Alignment.center,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: _wizardStep == 0
                            ? _welcomePanel(
                                context,
                                (constraints.maxWidth * .62)
                                    .clamp(150.0, 230.0)
                                    .toDouble(),
                              )
                            : _questionPanel(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: () => setState(() {
                  if (_wizardStep < 3) {
                    _wizardStep++;
                  } else {
                    context.read<LifestyleProvider>().finishRecipeOnboarding(
                      _level,
                      diet: _diet,
                      time: _time,
                    );
                    _wizard = false;
                    if (_diet == 'Vegetarian')
                      _loadCategory('Vegetarian');
                    else if (_diet == 'Vegan')
                      _loadCategory('Vegan');
                    else
                      _loadArea(_area);
                  }
                }),
                child: Text(
                  _wizardStep == 0
                      ? context.tr('Get Started', 'Bắt đầu')
                      : _wizardStep == 3
                      ? context.tr('Show me recipes', 'Xem công thức')
                      : context.tr('Continue', 'Tiếp tục'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _welcomePanel(BuildContext context, double imageSize) {
    final p = context.palette;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: imageSize,
          width: imageSize,
          decoration: BoxDecoration(
            color: p.brandSoft,
            borderRadius: BorderRadius.circular(34),
          ),
          child: Center(
            child: Text(
              '🥗\n🍲\n🥕',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: imageSize * .24, height: 1.28),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          context.tr('Welcome to recipes!', 'Chào mừng đến với công thức!'),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 15),
        Text(
          context.tr(
            'Transform your cooking experience into a delightful and rewarding adventure.',
            'Biến việc nấu ăn thành một hành trình thú vị và bổ ích.',
          ),
          textAlign: TextAlign.center,
          style: TextStyle(color: p.textSecondary, fontSize: 17, height: 1.35),
        ),
        const SizedBox(height: 25),
        Text(
          context.tr(
            'Let’s start by answering a few quick questions about your cooking habits and preferences.',
            'Hãy trả lời vài câu hỏi ngắn về thói quen và sở thích nấu ăn của bạn.',
          ),
          textAlign: TextAlign.center,
          style: TextStyle(color: p.textSecondary, fontSize: 15, height: 1.4),
        ),
      ],
    );
  }

  Widget _questionPanel(BuildContext context) {
    final p = context.palette;
    final options = switch (_wizardStep) {
      1 => [
        ('🥄', 'Beginner', 'I am learning the basics'),
        ('🍳', 'Home cook', 'I cook familiar meals'),
        ('👩‍🍳', 'Confident', 'I enjoy trying new techniques'),
      ],
      2 => [
        ('⚡', 'Under 20 min', 'Quick recipes'),
        ('⏱️', 'Under 45 min', 'A little more time'),
        ('🧑‍🍳', 'Any time', 'No time limit'),
      ],
      _ => [
        ('🥗', 'No preference', 'Show all recipes'),
        ('🌱', 'Vegetarian', 'Plant-forward ideas'),
        ('🌿', 'Vegan', 'Plant-based recipes'),
      ],
    };
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          switch (_wizardStep) {
            1 => context.tr(
              'What is your cooking level?',
              'Trình độ nấu ăn của bạn?',
            ),
            2 => context.tr(
              'How much time do you have?',
              'Bạn có bao nhiêu thời gian?',
            ),
            _ => context.tr(
              'What kind of food do you prefer?',
              'Bạn thích loại món ăn nào?',
            ),
          },
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Text(
          context.tr(
            'You can change these preferences any time.',
            'Bạn có thể thay đổi lựa chọn này bất cứ lúc nào.',
          ),
          style: TextStyle(color: p.textSecondary),
        ),
        const SizedBox(height: 22),
        for (var i = 0; i < options.length; i++)
          _option(
            context,
            options[i].$1,
            context.tr(options[i].$2, _recipeVietnamese(options[i].$2)),
            context.tr(options[i].$3, _recipeVietnamese(options[i].$3)),
            _selected(options[i].$2),
            () => setState(() => _select(options[i].$2)),
          ),
      ],
    );
  }

  Widget _option(
    BuildContext context,
    String emoji,
    String title,
    String subtitle,
    bool selected,
    VoidCallback tap,
  ) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Material(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: tap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? p.brand : p.outline,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(color: p.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? p.brand : p.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _selected(String label) => _wizardStep == 1
      ? _level == label
      : _wizardStep == 2
      ? _time == label
      : _diet == label;
  void _select(String label) {
    if (_wizardStep == 1) _level = label;
    if (_wizardStep == 2) _time = label;
    if (_wizardStep == 3) _diet = label;
  }

  Widget _catalog(BuildContext context, LifestyleProvider life) {
    final p = context.palette;
    final baseShown = _favorites
        ? _seen.values
              .where((r) => life.favoriteRecipes.contains(r.id))
              .toList()
        : _recipes;
    final shown = !_filterCalories
        ? baseShown
        : baseShown.where((recipe) {
            final estimate = _estimateCalories(recipe);
            return estimate >= _calorieRange.start &&
                estimate <= _calorieRange.end;
          }).toList();
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
          sliver: SliverList.list(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr('Recipes', 'Công thức'),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    tooltip: context.tr(
                      'Filter recipes by calories',
                      'Lọc công thức theo calo',
                    ),
                    onPressed: () => _showCalorieFilter(context),
                    icon: Icon(
                      Icons.tune,
                      color: _filterCalories ? p.brand : p.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _shopping(context, life),
                    icon: Badge(
                      isLabelVisible: life.shoppingList.isNotEmpty,
                      label: Text('${life.shoppingList.length}'),
                      child: const Icon(Icons.shopping_basket_outlined),
                    ),
                  ),
                ],
              ),
              TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: context.tr(
                    'Search recipes around the world',
                    'Tìm công thức trên khắp thế giới',
                  ),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: p.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) {
                  _debounce?.cancel();
                  _debounce = Timer(
                    const Duration(milliseconds: 450),
                    () => _searchRecipes(v),
                  );
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _tab(
                      context.tr('Discover', 'Khám phá'),
                      !_favorites,
                      () => setState(() => _favorites = false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _tab(
                      context.tr('My Favorites', 'Món yêu thích'),
                      _favorites,
                      () {
                        setState(() => _favorites = true);
                        _ensureFavorites();
                      },
                    ),
                  ),
                ],
              ),
              if (!_favorites && _search.text.isEmpty) ...[
                const SizedBox(height: 22),
                Text(
                  context.tr('Popular Categories', 'Danh mục phổ biến'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    for (final c in [
                      'Breakfast',
                      'Chicken',
                      'Seafood',
                      'Vegetarian',
                      'Vegan',
                    ])
                      ActionChip(
                        avatar: Text(
                          {
                            'Breakfast': '☕',
                            'Chicken': '🍗',
                            'Seafood': '🐟',
                            'Vegetarian': '🥗',
                            'Vegan': '🌱',
                          }[c]!,
                        ),
                        label: Text(context.tr(c, _recipeVietnamese(c))),
                        onPressed: () => _loadCategory(c),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  context.tr('Explore by country', 'Khám phá theo quốc gia'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 43,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final a in _areas)
                        Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: ChoiceChip(
                            label: Text(_countryLabel(context, a)),
                            selected: a == _area,
                            onSelected: (_) {
                              setState(() => _area = a);
                              _search.clear();
                              _loadArea(a);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                _favorites
                    ? context.tr('My Favorites', 'Món yêu thích')
                    : _search.text.isEmpty
                    ? '${context.tr('Recipes from', 'Công thức từ')} ${_countryLabel(context, _area)}'
                    : context.tr('Search results', 'Kết quả tìm kiếm'),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              if (_error.isNotEmpty)
                Center(
                  child: Column(
                    children: [
                      Text(_error, style: TextStyle(color: p.textSecondary)),
                      TextButton(
                        onPressed: () => _search.text.isEmpty
                            ? _loadArea(_area)
                            : _searchRecipes(_search.text),
                        child: Text(context.tr('Retry', 'Thử lại')),
                      ),
                    ],
                  ),
                )
              else if (_loading)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(25),
                  child: Center(
                    child: Text(
                      _favorites
                          ? context.tr(
                              'No favorite recipes yet.',
                              'Bạn chưa lưu món yêu thích nào.',
                            )
                          : context.tr(
                              'No recipes found.',
                              'Không tìm thấy công thức.',
                            ),
                      style: TextStyle(color: p.textSecondary),
                    ),
                  ),
                )
              else
                for (final recipe in shown) _recipeTile(context, recipe, life),
              const SizedBox(height: 15),
              Text(
                context.tr(
                  'Recipe data by TheMealDB · nutrition values are not supplied for every recipe.',
                  'Dữ liệu công thức từ TheMealDB · không phải món nào cũng có thông tin dinh dưỡng.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tab(String name, bool selected, VoidCallback onTap) {
    final p = context.palette;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? p.brandSoft : p.surface,
        side: BorderSide(
          color: selected ? p.brand : p.outline,
          width: selected ? 2 : 1,
        ),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(vertical: 13),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: selected ? p.brand : p.textPrimary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }

  Widget _recipeTile(
    BuildContext context,
    Recipe recipe,
    LifestyleProvider life,
  ) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Material(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _showDetails(context, recipe, life),
          borderRadius: BorderRadius.circular(20),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(20),
                ),
                child: SizedBox(
                  width: 106,
                  height: 100,
                  child: recipe.thumbnail.isEmpty
                      ? const Center(
                          child: Text('🍲', style: TextStyle(fontSize: 36)),
                        )
                      : Image.network(
                          recipe.thumbnail,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Text('🍲', style: TextStyle(fontSize: 34)),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_countryLabel(context, recipe.area.isEmpty ? _area : recipe.area)}${recipe.category.isEmpty ? '' : ' · ${recipe.category}'}',
                      style: TextStyle(fontSize: 11, color: p.textSecondary),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '~${_estimateCalories(recipe)} kcal · ${context.tr('View ingredients & method', 'Xem nguyên liệu và cách nấu')}',
                      style: TextStyle(fontSize: 11, color: p.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => life.toggleFavorite(recipe.id),
                icon: Icon(
                  life.favoriteRecipes.contains(recipe.id)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: life.favoriteRecipes.contains(recipe.id)
                      ? Colors.red
                      : p.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _estimateCalories(Recipe recipe) {
    final text =
        '${recipe.sourceName ?? recipe.name} ${recipe.sourceCategory ?? recipe.category} ${recipe.ingredients.map((i) => i.$1).join(' ')}'
            .toLowerCase();
    if (text.contains('soup') ||
        text.contains('broth') ||
        text.contains('salad'))
      return 300;
    if (text.contains('fried') ||
        text.contains('cream') ||
        text.contains('butter') ||
        text.contains('cheese'))
      return 700;
    if (text.contains('rice') ||
        text.contains('pasta') ||
        text.contains('noodle') ||
        text.contains('curry'))
      return 550;
    if (text.contains('chicken') ||
        text.contains('beef') ||
        text.contains('pork') ||
        text.contains('lamb'))
      return 600;
    return 450;
  }

  Future<void> _showCalorieFilter(BuildContext context) async {
    var draft = _calorieRange;
    var enabled = _filterCalories;
    final result = await showModalBottomSheet<(bool, RangeValues)>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setSheet) {
          final p = sheet.palette;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sheet.tr(
                      'Filter by estimated calories',
                      'Lọc theo calo ước tính',
                    ),
                    style: Theme.of(sheet).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    sheet.tr(
                      'Recipes without nutrition labels use a rough category estimate.',
                      'Món chưa có nhãn dinh dưỡng dùng mức ước tính theo danh mục.',
                    ),
                    style: TextStyle(color: p.textSecondary, fontSize: 12),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      sheet.tr('Enable calorie filter', 'Bật bộ lọc calo'),
                    ),
                    value: enabled,
                    onChanged: (v) => setSheet(() => enabled = v),
                  ),
                  RangeSlider(
                    values: draft,
                    min: 100,
                    max: 900,
                    divisions: 16,
                    labels: RangeLabels(
                      '${draft.start.round()} kcal',
                      '${draft.end.round()} kcal',
                    ),
                    onChanged: enabled
                        ? (value) => setSheet(() => draft = value)
                        : null,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${draft.start.round()}–${draft.end.round()} kcal ${sheet.tr('per serving', 'mỗi khẩu phần')}',
                        ),
                      ),
                      TextButton(
                        onPressed: () => setSheet(() {
                          enabled = false;
                          draft = const RangeValues(100, 900);
                        }),
                        child: Text(sheet.tr('Reset', 'Đặt lại')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(sheet, (enabled, draft)),
                      child: Text(sheet.tr('Show recipes', 'Hiện công thức')),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (result != null && mounted)
      setState(() {
        _filterCalories = result.$1;
        _calorieRange = result.$2;
      });
  }

  Future<void> _showDetails(
    BuildContext context,
    Recipe summary,
    LifestyleProvider life,
  ) async {
    final source = await _service.details(summary.id);
    if (!context.mounted) return;
    if (source == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Recipe details are unavailable.',
              'Chi tiết công thức hiện không khả dụng.',
            ),
          ),
        ),
      );
      return;
    }
    final language = Localizations.localeOf(context).languageCode;
    if (language != 'en') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 45),
          content: Text(
            context.tr('Translating recipe…', 'Đang dịch công thức…'),
          ),
        ),
      );
    }
    final recipe = await _service.localized(source, language);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (language != 'en' && identical(recipe, source)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Recipe translation is unavailable; showing the original text.',
              'Chưa thể dịch công thức; đang hiển thị nội dung gốc.',
            ),
          ),
        ),
      );
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.surface,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            15,
            20,
            MediaQuery.viewInsetsOf(sheet).bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (recipe.thumbnail.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      recipe.thumbnail,
                      width: double.infinity,
                      height: 210,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(height: 70),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  recipe.name,
                  style: Theme.of(sheet).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${recipe.area} · ${recipe.category}',
                  style: TextStyle(color: sheet.palette.textSecondary),
                ),
                const SizedBox(height: 19),
                Text(
                  sheet.tr('Ingredients', 'Nguyên liệu'),
                  style: Theme.of(sheet).textTheme.titleLarge,
                ),
                for (final i in recipe.ingredients)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.circle,
                      color: sheet.palette.brand,
                      size: 8,
                    ),
                    title: Text(i.$1),
                    trailing: Text(
                      i.$2,
                      style: TextStyle(color: sheet.palette.textSecondary),
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  sheet.tr('Cooking steps', 'Các bước nấu'),
                  style: Theme.of(sheet).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ...recipe.instructions
                    .split(RegExp(r'\r?\n|(?<=[.!?])\s+(?=[A-Z0-9])'))
                    .where((s) => s.trim().isNotEmpty)
                    .toList()
                    .asMap()
                    .entries
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          '${e.key + 1}. ${e.value.trim()}',
                          style: const TextStyle(height: 1.4),
                        ),
                      ),
                    ),
                if (recipe.source != null && recipe.source!.isNotEmpty)
                  SelectableText(
                    '${sheet.tr('Source', 'Nguồn')}: ${recipe.source}',
                    style: TextStyle(
                      fontSize: 11,
                      color: sheet.palette.textSecondary,
                    ),
                  ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => life.addShoppingItems(
                      recipe.ingredients.map(
                        (e) => e.$2.isEmpty ? e.$1 : '${e.$1} · ${e.$2}',
                      ),
                    ),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: Text(
                      sheet.tr(
                        'Add ingredients to basket',
                        'Thêm nguyên liệu vào giỏ',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  sheet.tr(
                    'Recipe instructions provided by TheMealDB. Nutrition information may not be available.',
                    'Hướng dẫn từ TheMealDB. Thông tin dinh dưỡng có thể chưa có.',
                  ),
                  style: TextStyle(
                    color: sheet.palette.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _shopping(BuildContext context, LifestyleProvider life) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.surface,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      sheet.tr('Shopping basket', 'Giỏ nguyên liệu'),
                      style: Theme.of(sheet).textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: life.clearShoppingList,
                    child: Text(sheet.tr('Clear', 'Xóa')),
                  ),
                ],
              ),
              if (life.shoppingList.isEmpty)
                Padding(
                  padding: EdgeInsets.all(22),
                  child: Text(
                    sheet.tr(
                      'Add ingredients from a recipe to see them here.',
                      'Thêm nguyên liệu từ công thức để xem chúng ở đây.',
                    ),
                  ),
                )
              else
                ...life.shoppingList.map(
                  (item) => CheckboxListTile(
                    value: false,
                    onChanged: (_) => life.removeShoppingItem(item),
                    title: Text(item),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

String _recipeVietnamese(String value) => switch (value) {
  'Breakfast' => 'Bữa sáng',
  'Chicken' => 'Món gà',
  'Seafood' => 'Hải sản',
  'Vegetarian' => 'Món chay',
  'Vegan' => 'Thuần chay',
  'Beginner' => 'Mới bắt đầu',
  'Home cook' => 'Nấu ăn gia đình',
  'Confident' => 'Tự tin nấu ăn',
  'I am learning the basics' => 'Tôi đang học những điều cơ bản',
  'I cook familiar meals' => 'Tôi nấu các món quen thuộc',
  'I enjoy trying new techniques' => 'Tôi thích thử kỹ thuật mới',
  'Under 20 min' => 'Dưới 20 phút',
  'Under 45 min' => 'Dưới 45 phút',
  'Any time' => 'Không giới hạn thời gian',
  'Quick recipes' => 'Công thức nhanh',
  'A little more time' => 'Có thể nấu lâu hơn',
  'No time limit' => 'Không giới hạn thời gian',
  'No preference' => 'Không có yêu cầu',
  'Show all recipes' => 'Hiển thị mọi công thức',
  'Plant-forward ideas' => 'Ưu tiên món nhiều thực vật',
  'Plant-based recipes' => 'Công thức thuần thực vật',
  _ => value,
};

String _countryLabel(BuildContext context, String country) {
  final vietnamese = switch (country) {
    'American' => 'Mỹ',
    'British' => 'Anh',
    'Canadian' => 'Canada',
    'Chinese' => 'Trung Quốc',
    'Croatian' => 'Croatia',
    'Dutch' => 'Hà Lan',
    'Egyptian' => 'Ai Cập',
    'Filipino' => 'Philippines',
    'French' => 'Pháp',
    'Greek' => 'Hy Lạp',
    'Indian' => 'Ấn Độ',
    'Irish' => 'Ireland',
    'Italian' => 'Ý',
    'Jamaican' => 'Jamaica',
    'Japanese' => 'Nhật Bản',
    'Kenyan' => 'Kenya',
    'Malaysian' => 'Malaysia',
    'Mexican' => 'Mexico',
    'Moroccan' => 'Maroc',
    'Polish' => 'Ba Lan',
    'Portuguese' => 'Bồ Đào Nha',
    'Russian' => 'Nga',
    'Spanish' => 'Tây Ban Nha',
    'Thai' => 'Thái Lan',
    'Tunisian' => 'Tunisia',
    'Turkish' => 'Thổ Nhĩ Kỳ',
    'Ukrainian' => 'Ukraine',
    'Vietnamese' => 'Việt Nam',
    _ => country,
  };
  return context.tr(country, vietnamese);
}

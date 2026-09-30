import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';
import 'api_client.dart';

/// Uses TheMealDB's free development key. Keep this service replaceable so a
/// production API key/proxy can be configured without changing the UI.
class RecipeService {
  static const _base = 'https://www.themealdb.com/api/json/v1/1';
  final http.Client _client;
  final ApiClient _api = ApiClient();
  RecipeService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<String>> areas() async {
    final json = await _get('/list.php', {'a': 'list'});
    return (json['meals'] as List? ?? [])
        .map((e) => (e as Map<String, dynamic>)['strArea'] as String)
        .toList()
      ..sort();
  }

  Future<List<Recipe>> search(String query) async {
    final json = await _get('/search.php', {'s': query});
    return _recipes(json);
  }

  Future<List<Recipe>> byArea(String area) async {
    final json = await _get('/filter.php', {'a': area});
    return _recipes(json);
  }

  Future<List<Recipe>> byCategory(String category) async {
    final json = await _get('/filter.php', {'c': category});
    return _recipes(json);
  }

  Future<Recipe?> details(String id) async {
    final json = await _get('/lookup.php', {'i': id});
    final meals = json['meals'] as List? ?? [];
    return meals.isEmpty
        ? null
        : Recipe.fromJson(meals.first as Map<String, dynamic>);
  }

  Future<List<Recipe>> localizedTitles(
    List<Recipe> recipes,
    String language,
  ) async {
    if (language == 'en' || recipes.isEmpty) return recipes;
    final prefs = await SharedPreferences.getInstance();
    final cacheKeys = {
      for (final recipe in recipes)
        recipe.id: 'caloai_recipe_title_${language}_${recipe.id}',
    };
    final translations = <String, Map<String, dynamic>>{};
    final pending = <Recipe>[];
    for (final recipe in recipes) {
      final cached = prefs.getString(cacheKeys[recipe.id]!);
      if (cached == null) {
        pending.add(recipe);
        continue;
      }
      try {
        translations[recipe.id] =
            jsonDecode(cached) as Map<String, dynamic>;
      } catch (_) {
        await prefs.remove(cacheKeys[recipe.id]!);
        pending.add(recipe);
      }
    }

    for (var start = 0; start < pending.length; start += 30) {
      final batch = pending.skip(start).take(30).toList();
      try {
        final result = await _api.translateRecipeTitles(
          language: language,
          recipes: [
            for (final recipe in batch)
              {
                'id': recipe.id,
                'name': recipe.sourceName ?? recipe.name,
                'area': recipe.area,
                'category': recipe.sourceCategory ?? recipe.category,
              },
          ],
        );
        for (final value in result) {
          final translation = value as Map<String, dynamic>;
          final id = translation['id'] as String?;
          if (id == null || !cacheKeys.containsKey(id)) continue;
          translations[id] = translation;
          await prefs.setString(cacheKeys[id]!, jsonEncode(translation));
        }
      } catch (_) {
        // Keep source names in place when the translation service is unavailable.
        break;
      }
    }

    return recipes.map((recipe) {
      final translation = translations[recipe.id];
      return translation == null
          ? recipe
          : recipe.copyWith(
              name: translation['name'] as String?,
              category: translation['category'] as String?,
            );
    }).toList();
  }

  Future<Recipe> localized(Recipe recipe, String language) async {
    if (language == 'en' || recipe.id.isEmpty) return recipe;
    final prefs = await SharedPreferences.getInstance();
    final key = 'caloai_recipe_${recipe.id}_$language';
    final cached = prefs.getString(key);
    if (cached != null) {
      try {
        return _translatedCopy(
          recipe,
          jsonDecode(cached) as Map<String, dynamic>,
        );
      } catch (_) {
        await prefs.remove(key);
      }
    }
    try {
      final translated = await _api.translateRecipe({
        'language': language,
        'name': recipe.name,
        'area': recipe.area,
        'category': recipe.category,
        'instructions': recipe.instructions,
        'ingredients': [
          for (final item in recipe.ingredients)
            {'name': item.$1, 'measure': item.$2},
        ],
        'tags': recipe.tags,
      });
      await prefs.setString(key, jsonEncode(translated));
      return _translatedCopy(recipe, translated);
    } catch (_) {
      // Keep the source recipe readable when translation service is unavailable.
      return recipe;
    }
  }

  Recipe _translatedCopy(Recipe recipe, Map<String, dynamic> json) {
    final ingredients = (json['ingredients'] as List<dynamic>? ?? [])
        .map((value) => value as Map<String, dynamic>)
        .map(
          (value) => (
            value['name'] as String? ?? '',
            value['measure'] as String? ?? '',
          ),
        )
        .toList();
    return recipe.copyWith(
      name: json['name'] as String?,
      area: json['area'] as String?,
      category: json['category'] as String?,
      instructions: json['instructions'] as String?,
      ingredients: ingredients,
      tags: (json['tags'] as List<dynamic>? ?? []).cast<String>(),
    );
  }

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> params,
  ) async {
    final uri = Uri.parse('$_base$path').replace(queryParameters: params);
    final prefs = await SharedPreferences.getInstance();
    final cacheKey =
        'caloai_recipe_cache_${Uri.encodeComponent(uri.toString())}';
    final cached = prefs.getString(cacheKey);
    final cachedAt = prefs.getInt('${cacheKey}_time');
    if (cached != null &&
        cachedAt != null &&
        DateTime.now().millisecondsSinceEpoch - cachedAt <
            const Duration(hours: 24).inMilliseconds) {
      return jsonDecode(cached) as Map<String, dynamic>;
    }
    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw const RecipeApiException('Recipe service is unavailable.');
      }
      await prefs.setString(cacheKey, response.body);
      await prefs.setInt(
        '${cacheKey}_time',
        DateTime.now().millisecondsSinceEpoch,
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      if (cached != null) return jsonDecode(cached) as Map<String, dynamic>;
      rethrow;
    }
  }

  List<Recipe> _recipes(Map<String, dynamic> json) =>
      (json['meals'] as List? ?? [])
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .toList();
}

class RecipeApiException implements Exception {
  const RecipeApiException(this.message);
  final String message;
}

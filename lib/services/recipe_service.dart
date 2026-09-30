import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';

/// Uses TheMealDB's free development key. Keep this service replaceable so a
/// production API key/proxy can be configured without changing the UI.
class RecipeService {
  static const _base = 'https://www.themealdb.com/api/json/v1/1';
  final http.Client _client;
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

  Future<Map<String, dynamic>> _get(
      String path, Map<String, String> params) async {
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
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw const RecipeApiException('Recipe service is unavailable.');
      }
      await prefs.setString(cacheKey, response.body);
      await prefs.setInt(
          '${cacheKey}_time', DateTime.now().millisecondsSinceEpoch);
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

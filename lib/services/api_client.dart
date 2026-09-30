import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/food_result.dart';
import '../models/meal_entry.dart';
import '../models/user_profile.dart';

class ApiClient {
  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
  static const _accessKey = 'caloai_access_token';
  static const _refreshKey = 'caloai_refresh_token';
  static const _requestTimeout = Duration(seconds: 20);

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<bool> hasStoredSession() async =>
      await _secureStorage.read(key: _refreshKey) != null;

  Future<void> signInWithGoogle(String idToken) async {
    final response = await _sendJson(
      'POST',
      '/api/v1/auth/google',
      body: {'id_token': idToken},
      authenticated: false,
    );
    await _saveTokens(_decode(response) as Map<String, dynamic>);
  }

  Future<void> signOut() async {
    final refresh = await _secureStorage.read(key: _refreshKey);
    if (refresh != null) {
      try {
        await _sendJson(
          'POST',
          '/api/v1/auth/logout',
          body: {'refresh_token': refresh},
        );
      } catch (_) {
        // Local sign-out must still complete when the server is unavailable.
      }
    }
    await _secureStorage.delete(key: _accessKey);
    await _secureStorage.delete(key: _refreshKey);
  }

  Future<UserProfile?> loadProfile() async {
    final response = await _send('GET', '/api/v1/me/profile');
    if (response.statusCode == 404) return null;
    final json = _decode(response) as Map<String, dynamic>;
    return _profileFromApi(json);
  }

  Future<void> saveProfile(UserProfile profile) async {
    final body = {
      'name': profile.name,
      'goal': profile.goal,
      'goal_rate': profile.rate,
      'sex': profile.sex,
      'age': profile.age,
      'height': profile.height,
      'weight': profile.weight,
      'target_weight': profile.targetWeight,
      'activity': profile.activity,
      'diet': profile.diet,
      'meals_per_day': profile.mealsPerDay,
      'exercise': profile.exercise,
      'sleep': profile.sleep,
      'daily_calories': profile.dailyCalories,
      'protein_goal': profile.proteinGoal,
      'carbs_goal': profile.carbsGoal,
      'fat_goal': profile.fatGoal,
      'photo_url': profile.photoUrl,
    };
    await _sendJson('PUT', '/api/v1/me/profile', body: body);
  }

  Future<void> updateNutritionGoals({
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
  }) async {
    await _sendJson('PATCH', '/api/v1/me/goals', body: {
      'daily_calories': calories,
      'protein_goal': protein,
      'carbs_goal': carbs,
      'fat_goal': fat,
    });
  }

  Future<FoodResult> analyzeFood(File image, {String language = 'vi'}) async {
    final token = await _secureStorage.read(key: _accessKey);
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/api/v1/food/analyze'),
    )
      ..headers['Accept-Language'] = language
      ..files.add(await http.MultipartFile.fromPath('image', image.path));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    var streamed = await request.send().timeout(const Duration(seconds: 60));
    var response = await http.Response.fromStream(streamed);
    if (response.statusCode == 401 && await _refreshAccessToken()) {
      final refreshed = await _secureStorage.read(key: _accessKey);
      final retry = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/v1/food/analyze'),
      )
        ..headers['Accept-Language'] = language
        ..headers['Authorization'] = 'Bearer $refreshed'
        ..files.add(await http.MultipartFile.fromPath('image', image.path));
      streamed = await retry.send().timeout(const Duration(seconds: 60));
      response = await http.Response.fromStream(streamed);
    }
    final json = _decode(response) as Map<String, dynamic>;
    return FoodResult.fromJson(json);
  }

  Future<String> logMeal(FoodResult result, DateTime consumedAt,
      {String mealType = 'other'}) async {
    final body = {
      'consumed_at': consumedAt.toUtc().toIso8601String(),
      'nutrition_date':
          '${consumedAt.year.toString().padLeft(4, '0')}-${consumedAt.month.toString().padLeft(2, '0')}-${consumedAt.day.toString().padLeft(2, '0')}',
      'meal_type': mealType,
      'analysis_id': result.analysisId,
      'items': [
        {
          'analysis_id': result.analysisId,
          'name': result.name,
          'serving': result.serving,
          'calories': result.calories,
          'protein': result.protein,
          'carbs': result.carbs,
          'fat': result.fat,
        },
      ],
    };
    final json =
        _decode(await _sendJson('POST', '/api/v1/me/meals', body: body))
            as Map<String, dynamic>;
    return json['id'] as String;
  }

  Future<String> logManualMeal({
    required String name,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    required String serving,
    required DateTime consumedAt,
    required String mealType,
  }) async {
    final date =
        '${consumedAt.year.toString().padLeft(4, '0')}-${consumedAt.month.toString().padLeft(2, '0')}-${consumedAt.day.toString().padLeft(2, '0')}';
    final json = _decode(await _sendJson('POST', '/api/v1/me/meals', body: {
      'consumed_at': consumedAt.toUtc().toIso8601String(),
      'nutrition_date': date,
      'meal_type': mealType,
      'items': [
        {
          'name': name,
          'serving': serving,
          'calories': calories,
          'protein': protein,
          'carbs': carbs,
          'fat': fat,
        },
      ],
    })) as Map<String, dynamic>;
    return json['id'] as String;
  }

  Future<void> deleteMeal(String id) async {
    final response = await _send('DELETE', '/api/v1/me/meals/$id');
    if (response.statusCode == 404) return;
    _decode(response);
  }

  Future<List<MealEntry>> loadMeals() async {
    final response = await _send('GET', '/api/v1/me/meals');
    final list = _decode(response) as List<dynamic>;
    return list.map((value) {
      final meal = value as Map<String, dynamic>;
      final items = meal['items'] as List<dynamic>;
      final names = <String>[];
      var calories = 0;
      var protein = 0.0;
      var carbs = 0.0;
      var fat = 0.0;
      for (final itemValue in items) {
        final item = itemValue as Map<String, dynamic>;
        names.add(item['name'] as String);
        calories += (item['calories'] as num).toInt();
        protein += (item['protein'] as num).toDouble();
        carbs += (item['carbs'] as num).toDouble();
        fat += (item['fat'] as num).toDouble();
      }
      return MealEntry(
        id: meal['id'] as String,
        name: names.join(' + '),
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        serving: '${items.length} món',
        timestamp: DateTime.parse(meal['timestamp'] as String).toLocal(),
        mealType: meal['meal_type'] as String? ?? 'other',
      );
    }).toList();
  }

  Future<http.Response> _sendJson(
    String method,
    String path, {
    required Map<String, dynamic> body,
    bool authenticated = true,
  }) async {
    return _send(method, path,
        body: jsonEncode(body), authenticated: authenticated);
  }

  Future<http.Response> _send(
    String method,
    String path, {
    String? body,
    bool authenticated = true,
  }) async {
    Future<http.Response> sendOnce({String? token}) {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';
      final uri = Uri.parse('$_baseUrl$path');
      switch (method) {
        case 'GET':
          return http.get(uri, headers: headers).timeout(_requestTimeout);
        case 'DELETE':
          return http.delete(uri, headers: headers).timeout(_requestTimeout);
        case 'PUT':
          return http
              .put(uri, headers: headers, body: body)
              .timeout(_requestTimeout);
        case 'PATCH':
          return http
              .patch(uri, headers: headers, body: body)
              .timeout(_requestTimeout);
        default:
          return http
              .post(uri, headers: headers, body: body)
              .timeout(_requestTimeout);
      }
    }

    try {
      var token =
          authenticated ? await _secureStorage.read(key: _accessKey) : null;
      var response = await sendOnce(token: token);
      if (authenticated &&
          response.statusCode == 401 &&
          await _refreshAccessToken()) {
        token = await _secureStorage.read(key: _accessKey);
        response = await sendOnce(token: token);
      }
      return response;
    } on TimeoutException {
      throw TimeoutException(
        'Máy chủ không phản hồi trong 20 giây ($_baseUrl). Nếu dùng backend local, hãy bật FastAPI và chạy: adb reverse tcp:8000 tcp:8000',
        _requestTimeout,
      );
    } on SocketException catch (error) {
      throw Exception(
        'Không kết nối được backend tại $_baseUrl. Hãy kiểm tra backend và kết nối ADB reverse. (${error.message})',
      );
    }
  }

  Future<bool> _refreshAccessToken() async {
    final refresh = await _secureStorage.read(key: _refreshKey);
    if (refresh == null) return false;
    try {
      final response = await _sendJson(
        'POST',
        '/api/v1/auth/refresh',
        body: {'refresh_token': refresh},
        authenticated: false,
      );
      if (response.statusCode != 200) return false;
      await _saveTokens(_decode(response) as Map<String, dynamic>);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveTokens(Map<String, dynamic> json) async {
    await _secureStorage.write(
        key: _accessKey, value: json['access_token'] as String);
    await _secureStorage.write(
        key: _refreshKey, value: json['refresh_token'] as String);
  }

  dynamic _decode(http.Response response) {
    dynamic json;
    try {
      json = jsonDecode(response.body);
    } on FormatException {
      json = null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          json is Map<String, dynamic> ? json['detail']?.toString() : null;
      throw Exception(
          message ?? 'Backend request failed (${response.statusCode})');
    }
    return json;
  }

  double _profileNumber(Map<String, dynamic> json, String key,
      {double fallback = 0}) {
    final value = json[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  int _profileInt(Map<String, dynamic> json, String key, {int fallback = 0}) {
    final value = json[key];
    if (value is num) return value.toInt();
    if (value is String) {
      return double.tryParse(value)?.toInt() ?? fallback;
    }
    return fallback;
  }

  UserProfile _profileFromApi(Map<String, dynamic> json) => UserProfile(
        uid: json['uid'].toString(),
        name: json['name'] as String,
        goal: json['goal'] as String,
        rate: json['goal_rate'] as String? ?? 'moderate',
        sex: json['sex'] as String,
        age: _profileInt(json, 'age'),
        height: _profileNumber(json, 'height'),
        weight: _profileNumber(json, 'weight'),
        targetWeight: _profileNumber(json, 'target_weight'),
        activity: json['activity'] as String,
        diet: json['diet'] as String,
        mealsPerDay: _profileInt(json, 'meals_per_day', fallback: 3),
        exercise: json['exercise'] as String,
        sleep: json['sleep'] as String,
        dailyCalories: _profileInt(json, 'daily_calories', fallback: 2000),
        proteinGoal: _profileNumber(json, 'protein_goal'),
        carbsGoal: _profileNumber(json, 'carbs_goal'),
        fatGoal: _profileNumber(json, 'fat_goal'),
        email: json['email'] as String,
        photoUrl: json['photo_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

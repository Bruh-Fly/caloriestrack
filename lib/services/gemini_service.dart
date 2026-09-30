import 'dart:io';

import '../models/food_result.dart';
import 'api_client.dart';

/// Kept under its existing name so the current camera UI needs no rewrite.
/// Food photos are analyzed by the authenticated FastAPI backend.
class GeminiService {
  final ApiClient _api = ApiClient();

  Future<FoodResult> analyzeFood(File image, {String language = 'vi'}) =>
      _api.analyzeFood(image, language: language);
}

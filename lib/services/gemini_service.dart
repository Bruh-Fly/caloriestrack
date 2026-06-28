import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/food_result.dart';

/// Google Gemini 1.5 Flash – FREE tier (aistudio.google.com/app/apikey)
/// Limits: 15 requests/min, 1,500 requests/day – perfect for personal use
class GeminiService {
  // ──────────────────────────────────────────────────────────────
  //  🔑  Replace with your key from https://aistudio.google.com
  // ──────────────────────────────────────────────────────────────
  static const String _apiKey = '';

  static const String _model   = 'gemini-1.5-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  static const String _prompt = '''
Bạn là chuyên gia dinh dưỡng. Hãy phân tích ảnh thức ăn này thật kỹ.

Nhận diện TẤT CẢ các món ăn/thức uống nhìn thấy được và ước tính tổng giá trị dinh dưỡng.

Trả về MỘT JSON object duy nhất, không có markdown, không có giải thích, không có ```json block:
{
  "name": "Tên món ăn chính bằng tiếng Việt",
  "calories": <số nguyên>,
  "protein": <gram, số thực>,
  "carbs": <gram, số thực>,
  "fat": <gram, số thực>,
  "serving": "Mô tả khẩu phần ước tính (vd: 1 bát cơm + 2 miếng thịt)",
  "description": "Mô tả ngắn về món ăn"
}

Quy tắc quan trọng:
- Nếu có nhiều món, cộng tổng calo và macro lại
- Đặt tên theo món chính nhìn thấy
- Ước tính khẩu phần dựa trên kích thước thực tế trong ảnh
- Nếu KHÔNG thấy thức ăn: {"error": "Không phát hiện thức ăn trong ảnh"}
- CHỈ trả về JSON, không có gì khác
''';

  Future<FoodResult> analyzeFood(File image) async {
    final bytes     = await image.readAsBytes();
    final b64       = base64Encode(bytes);
    final mimeType  = _mimeType(image.path);

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': b64,
              },
            },
            {'text': _prompt},
          ],
        }
      ],
      'generationConfig': {
        'temperature':     0.1,
        'maxOutputTokens': 600,
        'topP':            0.8,
      },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT',        'threshold': 'BLOCK_NONE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH',       'threshold': 'BLOCK_NONE'},
        {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_NONE'},
      ],
    });

    final response = await http
        .post(
          Uri.parse('$_baseUrl?key=$_apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      final err = _parseApiError(response.body);
      throw Exception('Lỗi API (${ response.statusCode}): $err');
    }

    final data       = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List?;

    if (candidates == null || candidates.isEmpty) {
      throw Exception('AI không trả về kết quả. Hãy thử lại.');
    }

    final rawText = candidates[0]['content']['parts'][0]['text'] as String;
    return _parseResult(rawText);
  }

  FoodResult _parseResult(String rawText) {
    // Strip any accidental markdown fences
    var clean = rawText
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    // Extract first JSON object if extra text present
    final startIdx = clean.indexOf('{');
    final endIdx   = clean.lastIndexOf('}');
    if (startIdx == -1 || endIdx == -1) {
      throw Exception('AI trả về định dạng không đúng. Thử chụp lại ảnh.');
    }
    clean = clean.substring(startIdx, endIdx + 1);

    final Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(clean) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Không thể đọc kết quả AI. Thử chụp lại ảnh rõ hơn.');
    }

    if (parsed['error'] != null) {
      throw Exception(parsed['error'] as String);
    }

    return FoodResult.fromJson(parsed);
  }

  String _mimeType(String path) {
    switch (path.toLowerCase().split('.').last) {
      case 'png':  return 'image/png';
      case 'webp': return 'image/webp';
      case 'gif':  return 'image/gif';
      default:     return 'image/jpeg';
    }
  }

  String _parseApiError(String body) {
    try {
      final map = jsonDecode(body) as Map<String, dynamic>;
      return map['error']?['message'] as String? ?? body;
    } catch (_) {
      return body;
    }
  }
}

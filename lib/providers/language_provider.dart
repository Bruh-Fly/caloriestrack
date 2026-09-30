import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const options = <({String code, String name, String nativeName})>[
    (code: 'en', name: 'English', nativeName: 'English'),
    (code: 'vi', name: 'Vietnamese', nativeName: 'Tiếng Việt'),
    (code: 'es', name: 'Spanish', nativeName: 'Español'),
    (code: 'fr', name: 'French', nativeName: 'Français'),
    (code: 'zh', name: 'Chinese', nativeName: '中文'),
    (code: 'hi', name: 'Hindi', nativeName: 'हिन्दी'),
    (code: 'ar', name: 'Arabic', nativeName: 'العربية'),
  ];

  static const _key = 'caloai_language';
  Locale _locale = const Locale('vi');
  Locale get locale => _locale;
  String get code => _locale.languageCode;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key) ?? 'vi';
    if (options.any((option) => option.code == saved)) {
      _locale = Locale(saved);
    }
  }

  Future<void> setLanguage(String code) async {
    if (!options.any((option) => option.code == code)) return;
    _locale = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
    notifyListeners();
  }
}

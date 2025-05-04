import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('ar', '');
  Map<String, String> _localizedStrings = {};

  Locale get locale => _locale;
  Map<String, String> get strings => _localizedStrings;

  LanguageProvider() {
    _loadLanguagePreference();
    loadTranslations();
  }

  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final language = prefs.getString('language') ?? 'ar';
    _locale = Locale(language, '');
    notifyListeners();
  }

  Future<void> loadTranslations() async {
    String jsonString = await rootBundle.loadString('assets/lang/${_locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    
    _locale = locale;
    
    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', locale.languageCode);
    
    // Load new translations
    await loadTranslations();
    
    notifyListeners();
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}

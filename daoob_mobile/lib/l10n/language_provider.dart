import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('ar', ''); // Default to Arabic
  Map<String, dynamic> _localizedValues = {};
  bool _isLoading = true;

  Locale get locale => _locale;
  bool get isLoading => _isLoading;

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('language');
    
    if (savedLanguage != null) {
      _locale = Locale(savedLanguage, '');
    }
    
    await loadLanguageData();
  }

  Future<void> loadLanguageData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      String path = 'assets/lang/${_locale.languageCode}.json';
      String jsonString = await rootBundle.loadString(path);
      _localizedValues = json.decode(jsonString);
    } catch (e) {
      print('Error loading language file: $e');
      // Default to a basic set in case of error
      _localizedValues = {
        'appName': 'DAOOB',
        'welcome': 'Welcome',
      };
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale.languageCode == locale.languageCode) return;
    
    _locale = locale;
    
    // Save the language preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', locale.languageCode);
    
    await loadLanguageData();
  }

  String translate(String key) {
    if (_localizedValues.containsKey(key)) {
      return _localizedValues[key].toString();
    }
    return key; // Return the key if translation is not found
  }
}

// File: lib/app/core/providers/locale_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('vi');

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language_code') ?? 'vi';
      _locale = Locale(languageCode);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading locale: $e');
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();

    // Save to preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', locale.languageCode);
    } catch (e) {
      debugPrint('Error saving locale: $e');
    }
  }

  // Helper method to get localized strings for common terms
  String getLocalizedString(String key) {
    final isVietnamese = _locale.languageCode == 'vi';

    final Map<String, Map<String, String>> localizedStrings = {
      'loading': {'en': 'Loading...', 'vi': 'Đang tải...'},
      'error': {'en': 'Error', 'vi': 'Lỗi'},
      'success': {'en': 'Success', 'vi': 'Thành công'},
      'noData': {'en': 'No data available', 'vi': 'Không có dữ liệu'},
      'pullToRefresh': {'en': 'Pull to refresh', 'vi': 'Kéo để làm mới'},
    };

    return localizedStrings[key]?[_locale.languageCode] ?? key;
  }
}

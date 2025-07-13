import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadTheme();
  }

  /// Load tema yang tersimpan dari SharedPreferences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);

      if (savedTheme != null) {
        switch (savedTheme) {
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          case 'system':
            _themeMode = ThemeMode.system;
            break;
          default:
            _themeMode = ThemeMode.light;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  /// Set tema dan simpan ke SharedPreferences
  Future<void> setTheme(ThemeMode themeMode) async {
    _themeMode = themeMode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      String themeName;

      switch (themeMode) {
        case ThemeMode.light:
          themeName = 'light';
          break;
        case ThemeMode.dark:
          themeName = 'dark';
          break;
        case ThemeMode.system:
          themeName = 'system';
          break;
      }

      await prefs.setString(_themeKey, themeName);
      debugPrint('Theme saved: $themeName');
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  /// Toggle antara dark dan light theme
  Future<void> toggleTheme() async {
    final newTheme =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setTheme(newTheme);
  }

  /// Set dark theme dengan boolean
  Future<void> setDarkTheme(bool isDark) async {
    final newTheme = isDark ? ThemeMode.dark : ThemeMode.light;
    await setTheme(newTheme);
  }
}

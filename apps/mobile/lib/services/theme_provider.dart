import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  system,
  light,
  dark,
}

/// Provider untuk preferensi tema aplikasi (Light, Dark, System Default).
///
/// Disimpan secara persisten di SharedPreferences dengan kunci `farlean_theme_mode`.
class ThemeProvider extends ChangeNotifier {
  static const String _prefKey = 'farlean_theme_mode';

  AppThemeMode _appThemeMode = AppThemeMode.system;

  AppThemeMode get appThemeMode => _appThemeMode;

  ThemeMode get themeMode {
    switch (_appThemeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  bool get isDarkMode => _appThemeMode == AppThemeMode.dark;

  /// Memuat preferensi tema dari SharedPreferences saat startup.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null) {
      switch (saved) {
        case 'light':
          _appThemeMode = AppThemeMode.light;
          break;
        case 'dark':
          _appThemeMode = AppThemeMode.dark;
          break;
        case 'system':
        default:
          _appThemeMode = AppThemeMode.system;
          break;
      }
      notifyListeners();
    }
  }

  /// Mengubah mode tema dan menyimpannya secara persisten.
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_appThemeMode == mode) return;
    _appThemeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, mode.name);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeProvider Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('1. Default theme mode adalah AppThemeMode.system dan ThemeMode.system', () {
      final provider = ThemeProvider();
      expect(provider.appThemeMode, equals(AppThemeMode.system));
      expect(provider.themeMode, equals(ThemeMode.system));
      expect(provider.isDarkMode, isFalse);
    });

    test('2. setThemeMode(AppThemeMode.dark) mengubah mode ke dark dan memberitahu listeners', () async {
      final provider = ThemeProvider();
      bool notified = false;
      provider.addListener(() => notified = true);

      await provider.setThemeMode(AppThemeMode.dark);

      expect(provider.appThemeMode, equals(AppThemeMode.dark));
      expect(provider.themeMode, equals(ThemeMode.dark));
      expect(provider.isDarkMode, isTrue);
      expect(notified, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('farlean_theme_mode'), equals('dark'));
    });

    test('3. setThemeMode(AppThemeMode.light) mengubah mode ke light dan menyimpan ke SharedPreferences', () async {
      final provider = ThemeProvider();
      await provider.setThemeMode(AppThemeMode.light);

      expect(provider.appThemeMode, equals(AppThemeMode.light));
      expect(provider.themeMode, equals(ThemeMode.light));
      expect(provider.isDarkMode, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('farlean_theme_mode'), equals('light'));
    });

    test('4. load() memulihkan nilai tersimpan dari SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'farlean_theme_mode': 'dark'});

      final provider = ThemeProvider();
      await provider.load();

      expect(provider.appThemeMode, equals(AppThemeMode.dark));
      expect(provider.themeMode, equals(ThemeMode.dark));
    });

    test('5. load() tetap fallback ke system jika nilai di SharedPreferences tidak ada/tidak dikenal', () async {
      SharedPreferences.setMockInitialValues({});

      final provider = ThemeProvider();
      await provider.load();

      expect(provider.appThemeMode, equals(AppThemeMode.system));
      expect(provider.themeMode, equals(ThemeMode.system));
    });
  });
}

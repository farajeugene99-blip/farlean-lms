import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider untuk preferensi locale aplikasi.
///
/// Kunci prefs: `farlean_locale` — nilai: `'id'` | `'en'`.
///
/// **Fase 2A (migrasi i18n)**: locale dikunci ke `id` secara programatik;
/// pemilih bahasa di UI belum diaktifkan. Setelah semua modul selesai migrasi
/// dan hijau di QA, kunci ini dilepas dan pemilih UI diperlihatkan.
class LocaleProvider extends ChangeNotifier {
  static const String _prefKey = 'farlean_locale';

  /// Locale yang sedang aktif. Default `id`.
  Locale _locale = const Locale('id');

  Locale get locale => _locale;

  /// Memuat preferensi locale tersimpan dari SharedPreferences.
  /// Jika belum ada preferensi tersimpan (null), fallback default selalu 'id'.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null && _supportedCodes.contains(saved)) {
      _locale = Locale(saved);
      notifyListeners();
    } else {
      _locale = const Locale('id');
    }
  }

  /// Menyimpan dan menerapkan locale baru.
  /// Dipanggil hanya saat pemilih bahasa diaktifkan (setelah fase 2A selesai).
  Future<void> setLocale(Locale locale) async {
    if (!_supportedCodes.contains(locale.languageCode)) return;
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, locale.languageCode);
  }

  static const List<String> _supportedCodes = ['id', 'en'];
}

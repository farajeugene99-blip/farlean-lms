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
  /// Selama fase migrasi i18n, apapun nilai tersimpannya dikunci ke `id`.
  Future<void> load() async {
    // TODO(i18n-phase-2a): uncomment block di bawah ini setelah semua modul
    // migrasi selesai dan QA hijau, lalu hapus baris `_locale = Locale('id')`.
    //
    // final prefs = await SharedPreferences.getInstance();
    // final saved = prefs.getString(_prefKey);
    // if (saved != null && _supportedCodes.contains(saved)) {
    //   _locale = Locale(saved);
    //   notifyListeners();
    // }
    _locale = const Locale('id');
    // notifyListeners tidak dipanggil — locale sudah `id` dari awal.
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

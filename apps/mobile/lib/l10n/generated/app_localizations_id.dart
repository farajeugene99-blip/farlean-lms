// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appName => 'Farlean LMS';

  @override
  String get navHome => 'Beranda';

  @override
  String get navClass => 'Kelas';

  @override
  String get navProfile => 'Profil';

  @override
  String get btnSave => 'Simpan';

  @override
  String get btnCancel => 'Batal';

  @override
  String get btnConfirm => 'Konfirmasi';

  @override
  String get btnClose => 'Tutup';

  @override
  String get btnLogout => 'Keluar';

  @override
  String get btnChangePassword => 'Ganti Kata Sandi';

  @override
  String get labelLoading => 'Memuat...';

  @override
  String get labelError => 'Terjadi kesalahan';

  @override
  String get labelRetry => 'Coba Lagi';

  @override
  String labelVersion(int version) {
    return 'Versi $version';
  }

  @override
  String get labelLastSaved => 'Terakhir disimpan';

  @override
  String get labelWib => 'WIB';
}

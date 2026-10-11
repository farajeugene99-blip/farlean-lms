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

  @override
  String get authLoginTitle => 'Masuk ke Farlean LMS';

  @override
  String get authLoginSubtitle => 'Platform Pembelajaran dan Manajemen Kelas';

  @override
  String get authFieldEmail => 'Email Kampus / Umum';

  @override
  String get authFieldPassword => 'Kata Sandi';

  @override
  String get authForgotPasswordLink => 'Lupa Kata Sandi?';

  @override
  String get authBtnLogin => 'Masuk';

  @override
  String get authNoAccount => 'Belum memiliki akun?';

  @override
  String get authBtnRegisterLink => 'Daftar Sekarang';

  @override
  String get authAppBarRegister => 'Buat Akun Baru';

  @override
  String get authRegisterTitle => 'Daftar Farlean LMS';

  @override
  String get authRegisterSubtitle =>
      'Gunakan email kampus untuk mendapatkan tipe MAHASISWA / DOSEN otomatis.';

  @override
  String get authFieldName => 'Nama Lengkap';

  @override
  String get authFieldEmailPlain => 'Email';

  @override
  String authFieldPasswordMin(int min) {
    return 'Kata Sandi (min. $min karakter)';
  }

  @override
  String get authFieldPasswordConfirm => 'Konfirmasi Kata Sandi';

  @override
  String get authBtnRegisterSubmit => 'Daftar';

  @override
  String get authForgotAppBar => 'Lupa Kata Sandi';

  @override
  String get authForgotHeading => 'Atur Ulang Kata Sandi';

  @override
  String get authForgotBody =>
      'Masukkan alamat email terdaftar Anda untuk menerima tautan pemulihan kata sandi.';

  @override
  String get authFieldEmailAddress => 'Alamat Email';

  @override
  String get authBtnSendReset => 'Kirim Tautan Pemulihan';

  @override
  String get authResetSentMsg =>
      'Tautan reset kata sandi telah dikirim ke email Anda.';

  @override
  String get authVerifyAppBar => 'Verifikasi Email';

  @override
  String get authVerifyHeading => 'Periksa Email Anda';

  @override
  String authVerifyBody(String email) {
    return 'Kami telah mengirimkan tautan verifikasi ke email Anda ($email). Akun belum dapat mengakses kelas sebelum email terverifikasi.';
  }

  @override
  String get authVerifyNotYet =>
      'Email belum terverifikasi. Silakan klik tautan di email Anda terlebih dahulu.';

  @override
  String get authBtnVerifyCheck => 'Saya Sudah Verifikasi';

  @override
  String get authVerifyResent =>
      'Tautan verifikasi telah dikirim ulang ke email Anda.';

  @override
  String get authBtnResendEmail => 'Kirim Ulang Email';

  @override
  String get authBtnSwitchAccount => 'Keluar / Ganti Akun';

  @override
  String get validEmailRequired => 'Email wajib diisi';

  @override
  String get validEmailFormat => 'Format email tidak valid';

  @override
  String get validPasswordRequired => 'Kata sandi wajib diisi';

  @override
  String validPasswordMin(int min) {
    return 'Minimal $min karakter';
  }

  @override
  String get validNameRequired => 'Nama wajib diisi';

  @override
  String get validPasswordMismatch => 'Konfirmasi kata sandi tidak cocok';

  @override
  String get authErrUserNotFound =>
      'Akun dengan alamat email ini tidak ditemukan.';

  @override
  String get authErrWrongPassword => 'Kata sandi yang Anda masukkan salah.';

  @override
  String get authErrInvalidCredential =>
      'Email atau kata sandi yang dimasukkan tidak sesuai.';

  @override
  String get authErrEmailInUse =>
      'Alamat email ini sudah terdaftar. Silakan gunakan menu Masuk.';

  @override
  String get authErrInvalidEmail => 'Format alamat email tidak valid.';

  @override
  String get authErrWeakPassword =>
      'Kata sandi terlalu lemah. Gunakan minimal 6 karakter.';

  @override
  String get authErrTooManyRequests =>
      'Terlalu banyak percobaan gagal. Silakan tunggu beberapa saat lagi.';

  @override
  String get authErrNetworkFailed =>
      'Koneksi ke server Firebase gagal. Pastikan jaringan atau Firebase Emulator aktif dan dapat dijangkau.';

  @override
  String get authErrRequiresRecentLogin =>
      'Sesi Anda telah kedaluwarsa. Harap keluar dan masuk kembali sebelum mengubah kata sandi.';

  @override
  String get authErrUserDisabled =>
      'Akun ini telah dinonaktifkan oleh administrator.';

  @override
  String get authErrUnknown =>
      'Terjadi kesalahan otentikasi. Silakan coba lagi.';
}

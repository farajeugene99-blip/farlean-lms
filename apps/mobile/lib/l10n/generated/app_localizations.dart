import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// Nama aplikasi
  ///
  /// In id, this message translates to:
  /// **'Farlean LMS'**
  String get appName;

  /// Label navigasi beranda
  ///
  /// In id, this message translates to:
  /// **'Beranda'**
  String get navHome;

  /// Label navigasi kelas
  ///
  /// In id, this message translates to:
  /// **'Kelas'**
  String get navClass;

  /// Label navigasi profil
  ///
  /// In id, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// Tombol simpan generik
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get btnSave;

  /// Tombol batal generik
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get btnCancel;

  /// Tombol konfirmasi generik
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi'**
  String get btnConfirm;

  /// Tombol tutup generik
  ///
  /// In id, this message translates to:
  /// **'Tutup'**
  String get btnClose;

  /// Tombol keluar/logout
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get btnLogout;

  /// Tombol ganti kata sandi
  ///
  /// In id, this message translates to:
  /// **'Ganti Kata Sandi'**
  String get btnChangePassword;

  /// Teks loading generik
  ///
  /// In id, this message translates to:
  /// **'Memuat...'**
  String get labelLoading;

  /// Label error generik
  ///
  /// In id, this message translates to:
  /// **'Terjadi kesalahan'**
  String get labelError;

  /// Tombol coba lagi setelah error
  ///
  /// In id, this message translates to:
  /// **'Coba Lagi'**
  String get labelRetry;

  /// Label versi dengan nomor
  ///
  /// In id, this message translates to:
  /// **'Versi {version}'**
  String labelVersion(int version);

  /// Label riwayat simpan materi
  ///
  /// In id, this message translates to:
  /// **'Terakhir disimpan'**
  String get labelLastSaved;

  /// Label zona waktu WIB
  ///
  /// In id, this message translates to:
  /// **'WIB'**
  String get labelWib;

  /// Judul halaman login
  ///
  /// In id, this message translates to:
  /// **'Masuk ke Farlean LMS'**
  String get authLoginTitle;

  /// Subjudul halaman login
  ///
  /// In id, this message translates to:
  /// **'Platform Pembelajaran dan Manajemen Kelas'**
  String get authLoginSubtitle;

  /// Label field email di halaman login
  ///
  /// In id, this message translates to:
  /// **'Email Kampus / Umum'**
  String get authFieldEmail;

  /// Label field kata sandi
  ///
  /// In id, this message translates to:
  /// **'Kata Sandi'**
  String get authFieldPassword;

  /// Tautan lupa kata sandi di halaman login
  ///
  /// In id, this message translates to:
  /// **'Lupa Kata Sandi?'**
  String get authForgotPasswordLink;

  /// Tombol masuk/login
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get authBtnLogin;

  /// Teks prompt daftar di halaman login
  ///
  /// In id, this message translates to:
  /// **'Belum memiliki akun?'**
  String get authNoAccount;

  /// Tautan ke halaman registrasi
  ///
  /// In id, this message translates to:
  /// **'Daftar Sekarang'**
  String get authBtnRegisterLink;

  /// Judul AppBar halaman registrasi
  ///
  /// In id, this message translates to:
  /// **'Buat Akun Baru'**
  String get authAppBarRegister;

  /// Judul besar halaman registrasi
  ///
  /// In id, this message translates to:
  /// **'Daftar Farlean LMS'**
  String get authRegisterTitle;

  /// Keterangan email kampus di halaman registrasi
  ///
  /// In id, this message translates to:
  /// **'Gunakan email kampus untuk mendapatkan tipe MAHASISWA / DOSEN otomatis.'**
  String get authRegisterSubtitle;

  /// Label field nama lengkap
  ///
  /// In id, this message translates to:
  /// **'Nama Lengkap'**
  String get authFieldName;

  /// Label field email generik (registrasi)
  ///
  /// In id, this message translates to:
  /// **'Email'**
  String get authFieldEmailPlain;

  /// Label field kata sandi dengan batas minimum
  ///
  /// In id, this message translates to:
  /// **'Kata Sandi (min. {min} karakter)'**
  String authFieldPasswordMin(int min);

  /// Label field konfirmasi kata sandi
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi Kata Sandi'**
  String get authFieldPasswordConfirm;

  /// Tombol submit registrasi
  ///
  /// In id, this message translates to:
  /// **'Daftar'**
  String get authBtnRegisterSubmit;

  /// Judul AppBar halaman lupa kata sandi
  ///
  /// In id, this message translates to:
  /// **'Lupa Kata Sandi'**
  String get authForgotAppBar;

  /// Judul besar halaman lupa kata sandi
  ///
  /// In id, this message translates to:
  /// **'Atur Ulang Kata Sandi'**
  String get authForgotHeading;

  /// Instruksi di halaman lupa kata sandi
  ///
  /// In id, this message translates to:
  /// **'Masukkan alamat email terdaftar Anda untuk menerima tautan pemulihan kata sandi.'**
  String get authForgotBody;

  /// Label field alamat email di lupa kata sandi
  ///
  /// In id, this message translates to:
  /// **'Alamat Email'**
  String get authFieldEmailAddress;

  /// Tombol kirim tautan reset kata sandi
  ///
  /// In id, this message translates to:
  /// **'Kirim Tautan Pemulihan'**
  String get authBtnSendReset;

  /// Snackbar sukses kirim reset kata sandi
  ///
  /// In id, this message translates to:
  /// **'Tautan reset kata sandi telah dikirim ke email Anda.'**
  String get authResetSentMsg;

  /// Judul AppBar halaman verifikasi email
  ///
  /// In id, this message translates to:
  /// **'Verifikasi Email'**
  String get authVerifyAppBar;

  /// Judul besar halaman verifikasi email
  ///
  /// In id, this message translates to:
  /// **'Periksa Email Anda'**
  String get authVerifyHeading;

  /// Instruksi verifikasi email dengan alamat email pengguna
  ///
  /// In id, this message translates to:
  /// **'Kami telah mengirimkan tautan verifikasi ke email Anda ({email}). Akun belum dapat mengakses kelas sebelum email terverifikasi.'**
  String authVerifyBody(String email);

  /// Snackbar saat cek verifikasi belum berhasil
  ///
  /// In id, this message translates to:
  /// **'Email belum terverifikasi. Silakan klik tautan di email Anda terlebih dahulu.'**
  String get authVerifyNotYet;

  /// Tombol cek ulang status verifikasi email
  ///
  /// In id, this message translates to:
  /// **'Saya Sudah Verifikasi'**
  String get authBtnVerifyCheck;

  /// Snackbar sukses kirim ulang verifikasi
  ///
  /// In id, this message translates to:
  /// **'Tautan verifikasi telah dikirim ulang ke email Anda.'**
  String get authVerifyResent;

  /// Tombol kirim ulang email verifikasi
  ///
  /// In id, this message translates to:
  /// **'Kirim Ulang Email'**
  String get authBtnResendEmail;

  /// Tombol keluar atau ganti akun di halaman verifikasi
  ///
  /// In id, this message translates to:
  /// **'Keluar / Ganti Akun'**
  String get authBtnSwitchAccount;

  /// Pesan validasi email kosong
  ///
  /// In id, this message translates to:
  /// **'Email wajib diisi'**
  String get validEmailRequired;

  /// Pesan validasi format email salah
  ///
  /// In id, this message translates to:
  /// **'Format email tidak valid'**
  String get validEmailFormat;

  /// Pesan validasi kata sandi kosong
  ///
  /// In id, this message translates to:
  /// **'Kata sandi wajib diisi'**
  String get validPasswordRequired;

  /// Pesan validasi panjang minimum kata sandi
  ///
  /// In id, this message translates to:
  /// **'Minimal {min} karakter'**
  String validPasswordMin(int min);

  /// Pesan validasi nama kosong
  ///
  /// In id, this message translates to:
  /// **'Nama wajib diisi'**
  String get validNameRequired;

  /// Pesan validasi konfirmasi sandi tidak sama
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi kata sandi tidak cocok'**
  String get validPasswordMismatch;

  /// Pesan error Firebase user-not-found
  ///
  /// In id, this message translates to:
  /// **'Akun dengan alamat email ini tidak ditemukan.'**
  String get authErrUserNotFound;

  /// Pesan error Firebase wrong-password
  ///
  /// In id, this message translates to:
  /// **'Kata sandi yang Anda masukkan salah.'**
  String get authErrWrongPassword;

  /// Pesan error Firebase invalid-credential (enum protection)
  ///
  /// In id, this message translates to:
  /// **'Email atau kata sandi yang dimasukkan tidak sesuai.'**
  String get authErrInvalidCredential;

  /// Pesan error Firebase email-already-in-use
  ///
  /// In id, this message translates to:
  /// **'Alamat email ini sudah terdaftar. Silakan gunakan menu Masuk.'**
  String get authErrEmailInUse;

  /// Pesan error Firebase invalid-email
  ///
  /// In id, this message translates to:
  /// **'Format alamat email tidak valid.'**
  String get authErrInvalidEmail;

  /// Pesan error Firebase weak-password
  ///
  /// In id, this message translates to:
  /// **'Kata sandi terlalu lemah. Gunakan minimal 6 karakter.'**
  String get authErrWeakPassword;

  /// Pesan error Firebase too-many-requests
  ///
  /// In id, this message translates to:
  /// **'Terlalu banyak percobaan gagal. Silakan tunggu beberapa saat lagi.'**
  String get authErrTooManyRequests;

  /// Pesan error Firebase network-request-failed
  ///
  /// In id, this message translates to:
  /// **'Koneksi ke server Firebase gagal. Pastikan jaringan atau Firebase Emulator aktif dan dapat dijangkau.'**
  String get authErrNetworkFailed;

  /// Pesan error Firebase requires-recent-login
  ///
  /// In id, this message translates to:
  /// **'Sesi Anda telah kedaluwarsa. Harap keluar dan masuk kembali sebelum mengubah kata sandi.'**
  String get authErrRequiresRecentLogin;

  /// Pesan error Firebase user-disabled
  ///
  /// In id, this message translates to:
  /// **'Akun ini telah dinonaktifkan oleh administrator.'**
  String get authErrUserDisabled;

  /// Fallback error otentikasi tidak dikenal
  ///
  /// In id, this message translates to:
  /// **'Terjadi kesalahan otentikasi. Silakan coba lagi.'**
  String get authErrUnknown;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

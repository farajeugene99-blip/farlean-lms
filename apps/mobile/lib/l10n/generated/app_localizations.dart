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

  /// Tombol masuk menggunakan akun Google
  ///
  /// In id, this message translates to:
  /// **'Masuk dengan Google'**
  String get authBtnGoogleSignIn;

  /// Tombol pendaftaran menggunakan akun Google
  ///
  /// In id, this message translates to:
  /// **'Daftar dengan Google'**
  String get authBtnGoogleSignUp;

  /// Pemisah 'atau' antara form email dan OAuth
  ///
  /// In id, this message translates to:
  /// **'atau'**
  String get authOrDivider;

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
  /// **'Kata sandi yang Anda masukkan salah. Jika sebelumnya Anda mendaftar dengan Google, silakan gunakan tombol Masuk dengan Google.'**
  String get authErrWrongPassword;

  /// Pesan error Firebase invalid-credential (enum protection)
  ///
  /// In id, this message translates to:
  /// **'Email atau kata sandi yang dimasukkan tidak sesuai. Jika sebelumnya Anda mendaftar dengan Google, silakan gunakan tombol Masuk dengan Google.'**
  String get authErrInvalidCredential;

  /// Pesan error Firebase account-exists-with-different-credential
  ///
  /// In id, this message translates to:
  /// **'Alamat email ini sudah terdaftar menggunakan metode masuk lain. Silakan masuk menggunakan metode tersebut.'**
  String get authErrAccountExistsDifferentCredential;

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

  /// Judul AppBar halaman profil
  ///
  /// In id, this message translates to:
  /// **'Profil Pengguna'**
  String get profileScreenTitle;

  /// Nama fallback pengguna jika profil kosong
  ///
  /// In id, this message translates to:
  /// **'Pengguna Farlean'**
  String get profileDefaultName;

  /// Tooltip ikon ubah nama
  ///
  /// In id, this message translates to:
  /// **'Ubah Nama'**
  String get profileEditNameTooltip;

  /// Badge tipe akun pengguna
  ///
  /// In id, this message translates to:
  /// **'Tipe: {type}'**
  String profileBadgeType(String type);

  /// Badge peran pengguna
  ///
  /// In id, this message translates to:
  /// **'Role: {role}'**
  String profileBadgeRole(String role);

  /// Judul dialog ubah nama
  ///
  /// In id, this message translates to:
  /// **'Ubah Nama Lengkap'**
  String get profileEditNameTitle;

  /// Validasi batas maksimum karakter nama
  ///
  /// In id, this message translates to:
  /// **'Maksimal {max} karakter'**
  String profileNameMaxLength(int max);

  /// Snackbar gagal perbarui nama
  ///
  /// In id, this message translates to:
  /// **'Gagal memperbarui nama: {detail}'**
  String profileNameUpdateFail(String detail);

  /// Snackbar sukses perbarui nama
  ///
  /// In id, this message translates to:
  /// **'Nama profil berhasil diperbarui.'**
  String get profileNameUpdated;

  /// Judul dialog dan ListTile identitas dinamis NIM/NIP
  ///
  /// In id, this message translates to:
  /// **'Nomor Induk ({label})'**
  String profileIdentityTitle(String label);

  /// Keterangan privasi sub-koleksi identitas
  ///
  /// In id, this message translates to:
  /// **'Data ini disimpan di sub-koleksi private/identity yang terisolasi dan hanya dapat diakses oleh Anda dan Admin. Pengajar kelas Anda melihatnya hanya melalui rekap resmi, bukan dari aplikasi.'**
  String get profileIdentityPrivacyNote;

  /// Validasi field identitas kosong
  ///
  /// In id, this message translates to:
  /// **'{label} wajib diisi'**
  String profileIdentityRequired(String label);

  /// Snackbar gagal simpan identitas
  ///
  /// In id, this message translates to:
  /// **'Gagal menyimpan {label}: {detail}'**
  String profileIdentitySaveFail(String label, String detail);

  /// Snackbar sukses simpan identitas
  ///
  /// In id, this message translates to:
  /// **'{label} berhasil disimpan di private identity.'**
  String profileIdentitySaved(String label);

  /// Subjudul identitas saat nilai masih kosong
  ///
  /// In id, this message translates to:
  /// **'Belum diisi (Klik untuk menambahkan)'**
  String get profileIdentityNotSet;

  /// Judul menu keamanan dan kata sandi
  ///
  /// In id, this message translates to:
  /// **'Keamanan & Kata Sandi'**
  String get profileSecurityTitle;

  /// Subjudul menu keamanan kata sandi
  ///
  /// In id, this message translates to:
  /// **'Ubah kata sandi akun untuk perangkat ini'**
  String get profileSecuritySubtitle;

  /// Judul menu dan dialog penyimpanan dan cache
  ///
  /// In id, this message translates to:
  /// **'Penyimpanan & Cache'**
  String get profileCacheTitle;

  /// Subjudul menu penyimpanan dan cache
  ///
  /// In id, this message translates to:
  /// **'Kelola memori sementara dan pilihan kelas aktif'**
  String get profileCacheSubtitle;

  /// Judul menu status verifikasi email
  ///
  /// In id, this message translates to:
  /// **'Status Verifikasi Email'**
  String get profileEmailVerificationTitle;

  /// Label email telah diverifikasi
  ///
  /// In id, this message translates to:
  /// **'Email Terverifikasi'**
  String get profileEmailVerified;

  /// Label email belum diverifikasi
  ///
  /// In id, this message translates to:
  /// **'Menunggu Verifikasi'**
  String get profileEmailPending;

  /// Judul menu sinkronisasi peran
  ///
  /// In id, this message translates to:
  /// **'Sinkronisasi Sesi & Peran'**
  String get profileSyncTitle;

  /// Peringatan peran belum sinkron
  ///
  /// In id, this message translates to:
  /// **'Peran belum sinkron (Token: {claimsRole} vs Profil: {profileRole}). Tekan perbarui.'**
  String profileSyncOutOfSync(String claimsRole, String profileRole);

  /// Keterangan sesi mutakhir
  ///
  /// In id, this message translates to:
  /// **'Sesi dan hak akses token mutakhir.'**
  String get profileSyncUpToDate;

  /// Tooltip ikon perbarui sesi
  ///
  /// In id, this message translates to:
  /// **'Perbarui Sesi'**
  String get profileRefreshSessionTooltip;

  /// Snackbar sukses perbarui sesi
  ///
  /// In id, this message translates to:
  /// **'Sesi dan token hak akses berhasil diperbarui.'**
  String get profileSessionRefreshed;

  /// Label tombol merah keluar akun di bagian bawah profil
  ///
  /// In id, this message translates to:
  /// **'Keluar dari Akun'**
  String get profileLogoutBtn;

  /// Status saat proses logout sedang berjalan
  ///
  /// In id, this message translates to:
  /// **'Sedang Keluar...'**
  String get profileLoggingOut;

  /// Judul dialog konfirmasi logout
  ///
  /// In id, this message translates to:
  /// **'Keluar dari Akun?'**
  String get profileLogoutConfirmTitle;

  /// Deskripsi dialog konfirmasi logout
  ///
  /// In id, this message translates to:
  /// **'Apakah Anda yakin ingin keluar dari sesi Farlean LMS di perangkat ini?'**
  String get profileLogoutConfirmBody;

  /// Peringatan Active Quiz Guard saat logout
  ///
  /// In id, this message translates to:
  /// **'Perhatian: Anda memiliki kuis yang sedang dikerjakan. Jika Anda keluar sekarang, pengerjaan kuis dapat terganggu dan jawaban yang belum tersimpan dapat hilang.'**
  String get profileLogoutQuizWarning;

  /// Peringatan perangkat offline saat logout
  ///
  /// In id, this message translates to:
  /// **'Tidak dapat memverifikasi status kuis karena perangkat sedang offline. Jika Anda sedang mengerjakan kuis, jawaban yang belum tersinkronisasi ke server mungkin hilang.'**
  String get profileLogoutOfflineWarning;

  /// Snackbar gagal logout
  ///
  /// In id, this message translates to:
  /// **'Gagal keluar akun: {detail}'**
  String profileLogoutFailed(String detail);

  /// Judul dialog ubah kata sandi
  ///
  /// In id, this message translates to:
  /// **'Ubah Kata Sandi'**
  String get profileChangePasswordTitle;

  /// Catatan kebijakan panjang kata sandi di dialog ubah sandi
  ///
  /// In id, this message translates to:
  /// **'Untuk keamanan akun Anda, masukkan kata sandi saat ini lalu buat kata sandi baru minimal {min} karakter.'**
  String profileChangePasswordNote(int min);

  /// Label field kata sandi saat ini
  ///
  /// In id, this message translates to:
  /// **'Kata Sandi Saat Ini'**
  String get profileCurrentPasswordLabel;

  /// Validasi kata sandi saat ini kosong
  ///
  /// In id, this message translates to:
  /// **'Kata sandi saat ini wajib diisi'**
  String get profileCurrentPasswordRequired;

  /// Label field kata sandi baru
  ///
  /// In id, this message translates to:
  /// **'Kata Sandi Baru (Min. {min} Karakter)'**
  String profileNewPasswordLabel(int min);

  /// Validasi kata sandi baru kosong
  ///
  /// In id, this message translates to:
  /// **'Kata sandi baru wajib diisi'**
  String get profileNewPasswordRequired;

  /// Pesan validasi kata sandi baru kurang dari minimum
  ///
  /// In id, this message translates to:
  /// **'Kata sandi baru minimal {min} karakter.'**
  String profileNewPasswordMinError(int min);

  /// Validasi kata sandi baru sama dengan yang lama
  ///
  /// In id, this message translates to:
  /// **'Kata sandi baru tidak boleh sama dengan kata sandi saat ini.'**
  String get profileNewPasswordSameAsCurrent;

  /// Label field konfirmasi kata sandi baru
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi Kata Sandi Baru'**
  String get profileConfirmNewPasswordLabel;

  /// Validasi konfirmasi kata sandi kosong
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi kata sandi wajib diisi'**
  String get profileConfirmPasswordRequired;

  /// Tautan lupa kata sandi saat ini di dialog ubah sandi
  ///
  /// In id, this message translates to:
  /// **'Lupa kata sandi saat ini?'**
  String get profileForgotCurrentPasswordLink;

  /// Tombol simpan kata sandi baru
  ///
  /// In id, this message translates to:
  /// **'Simpan Sandi'**
  String get profileSavePasswordBtn;

  /// Pesan error kredensial saat ini salah
  ///
  /// In id, this message translates to:
  /// **'Kata sandi saat ini yang Anda masukkan salah.'**
  String get profileCurrentPasswordWrong;

  /// Pesan error gagal update kata sandi selain kredensial
  ///
  /// In id, this message translates to:
  /// **'Gagal memperbarui kata sandi: {detail}'**
  String profilePasswordUpdateFail(String detail);

  /// Snackbar sukses perbarui kata sandi
  ///
  /// In id, this message translates to:
  /// **'Kata sandi berhasil diperbarui untuk akun ini.'**
  String get profilePwUpdated;

  /// Deskripsi dialog penyimpanan & cache
  ///
  /// In id, this message translates to:
  /// **'Kelola memori sementara gambar dan preferensi kelas aktif di perangkat ini secara aman.'**
  String get profileCacheDesc;

  /// Statistik memori gambar saat kosong
  ///
  /// In id, this message translates to:
  /// **'0 KB (belum ada gambar dimuat di memori)'**
  String get profileCacheEmpty;

  /// Statistik penggunaan cache gambar RAM
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{kb} KB ({count} gambar aktif di memori)}}'**
  String profileCacheStats(int count, String kb);

  /// Judul seksi cache gambar RAM
  ///
  /// In id, this message translates to:
  /// **'Cache Gambar di Memori (RAM)'**
  String get profileCacheImageSection;

  /// Catatan penjelasan cache memori gambar
  ///
  /// In id, this message translates to:
  /// **'Catatan: Cache memori menampung gambar materi yang sedang dibuka. Mengosongkannya aman dan gambar akan diunduh kembali saat dibuka.'**
  String get profileCacheImageNote;

  /// Tombol bersihkan cache memori gambar
  ///
  /// In id, this message translates to:
  /// **'Kosongkan Cache Gambar RAM'**
  String get profileCacheClearBtn;

  /// Snackbar sukses bersihkan cache gambar
  ///
  /// In id, this message translates to:
  /// **'Cache memori gambar berhasil dikosongkan.'**
  String get profileCacheCleared;

  /// Judul seksi pilihan kelas aktif
  ///
  /// In id, this message translates to:
  /// **'Pilihan Kelas Aktif Tersimpan'**
  String get profileClassSavedSection;

  /// Keterangan saat tidak ada kelas aktif
  ///
  /// In id, this message translates to:
  /// **'Belum ada kelas aktif yang dipilih'**
  String get profileClassNoneSelected;

  /// Catatan penjelasan reset kelas aktif
  ///
  /// In id, this message translates to:
  /// **'Mereset kelas aktif akan mengarahkan Anda ke Beranda untuk memilih kembali kelas pembelajaran.'**
  String get profileClassResetNote;

  /// Judul dialog blokir reset kelas karena kuis aktif
  ///
  /// In id, this message translates to:
  /// **'Kuis Sedang Dikerjakan'**
  String get profileActiveQuizTitle;

  /// Isi dialog blokir reset kelas karena kuis aktif
  ///
  /// In id, this message translates to:
  /// **'Tidak dapat mereset kelas aktif: Anda sedang memiliki kuis yang sedang dikerjakan. Selesaikan atau kumpulkan kuis terlebih dahulu sebelum mereset kelas.'**
  String get profileResetClassQuizBlocked;

  /// Tombol konfirmasi dialog informasi kuis aktif/offline
  ///
  /// In id, this message translates to:
  /// **'Mengerti'**
  String get profileBtnGotIt;

  /// Judul dialog blokir reset kelas saat offline
  ///
  /// In id, this message translates to:
  /// **'Perangkat Offline'**
  String get profileOfflineTitle;

  /// Isi dialog blokir reset kelas saat offline
  ///
  /// In id, this message translates to:
  /// **'Tidak dapat memverifikasi status kuis karena perangkat sedang offline. Untuk keamanan jawaban kuis Anda, reset kelas aktif ditunda hingga perangkat terhubung kembali.'**
  String get profileResetClassOfflineBlocked;

  /// Judul konfirmasi reset kelas aktif
  ///
  /// In id, this message translates to:
  /// **'Reset Pilihan Kelas?'**
  String get profileResetClassConfirmTitle;

  /// Isi konfirmasi reset kelas aktif
  ///
  /// In id, this message translates to:
  /// **'Anda akan diarahkan kembali ke Beranda untuk memilih kelas pembelajaran.'**
  String get profileResetClassConfirmBody;

  /// Tombol aksi reset kelas pada dialog konfirmasi
  ///
  /// In id, this message translates to:
  /// **'Reset'**
  String get profileBtnReset;

  /// Tombol buka dialog reset pilihan kelas aktif
  ///
  /// In id, this message translates to:
  /// **'Reset Pilihan Kelas Aktif'**
  String get profileResetClassBtn;

  /// Snackbar sukses reset kelas aktif
  ///
  /// In id, this message translates to:
  /// **'Pilihan kelas aktif berhasil direset.'**
  String get profileResetClassDone;

  /// Label status draf
  ///
  /// In id, this message translates to:
  /// **'Draf'**
  String get meetingStatusDraft;

  /// Label status terjadwal
  ///
  /// In id, this message translates to:
  /// **'Terjadwal'**
  String get meetingStatusScheduled;

  /// Label status dipublikasikan
  ///
  /// In id, this message translates to:
  /// **'Dipublikasikan'**
  String get meetingStatusPublished;

  /// Label status diarsipkan
  ///
  /// In id, this message translates to:
  /// **'Diarsipkan'**
  String get meetingStatusArchived;

  /// Judul AppBar daftar pertemuan
  ///
  /// In id, this message translates to:
  /// **'Materi & Pertemuan'**
  String get meetingListTitle;

  /// Tooltip ikon sinkronkan jadwal
  ///
  /// In id, this message translates to:
  /// **'Sinkronkan Jadwal Publikasi'**
  String get meetingSyncTooltip;

  /// Tooltip ikon segarkan data
  ///
  /// In id, this message translates to:
  /// **'Segarkan'**
  String get meetingRefreshTooltip;

  /// Tombol aksi terapung tambah pertemuan baru
  ///
  /// In id, this message translates to:
  /// **'Tambah Pertemuan'**
  String get meetingAddFab;

  /// Pesan error permission-denied untuk staf/pengajar
  ///
  /// In id, this message translates to:
  /// **'Akses ditolak: Anda tidak memiliki wewenang untuk mengelola kelas ini.'**
  String get meetingErrorPermissionStaff;

  /// Pesan error permission-denied untuk mahasiswa
  ///
  /// In id, this message translates to:
  /// **'Akses ditolak: Anda belum terdaftar sebagai anggota aktif di kelas ini. Pastikan Anda telah bergabung dan disetujui.'**
  String get meetingErrorPermissionStudent;

  /// Pesan error jaringan pada daftar pertemuan
  ///
  /// In id, this message translates to:
  /// **'Koneksi ke server bermasalah. Periksa jaringan internet atau emulator Anda.'**
  String get meetingErrorNetwork;

  /// Pesan error umum gagal memuat pertemuan
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat daftar pertemuan: {detail}'**
  String meetingErrorLoadFailed(String detail);

  /// Snackbar peringatan belum memilih kelas saat buat pertemuan
  ///
  /// In id, this message translates to:
  /// **'Pilih kelas yang valid terlebih dahulu untuk membuat pertemuan.'**
  String get meetingSelectClassFirst;

  /// Judul dialog buat pertemuan baru
  ///
  /// In id, this message translates to:
  /// **'Buat Pertemuan Baru'**
  String get meetingCreateTitle;

  /// Label input nomor pertemuan
  ///
  /// In id, this message translates to:
  /// **'Nomor Pertemuan'**
  String get meetingNumberLabel;

  /// Validasi nomor pertemuan kosong
  ///
  /// In id, this message translates to:
  /// **'Nomor wajib diisi'**
  String get meetingNumberRequired;

  /// Validasi nomor pertemuan harus angka positif
  ///
  /// In id, this message translates to:
  /// **'Nomor harus angka > 0'**
  String get meetingNumberMustBePositive;

  /// Label input judul pertemuan
  ///
  /// In id, this message translates to:
  /// **'Judul Pertemuan'**
  String get meetingTitleLabel;

  /// Validasi judul pertemuan kosong
  ///
  /// In id, this message translates to:
  /// **'Judul wajib diisi'**
  String get meetingTitleRequired;

  /// Tombol simpan draf pertemuan
  ///
  /// In id, this message translates to:
  /// **'Simpan Draft'**
  String get meetingSaveDraftBtn;

  /// Snackbar gagal aksi pertemuan
  ///
  /// In id, this message translates to:
  /// **'Gagal: {detail}'**
  String meetingCreateFailed(String detail);

  /// Snackbar generik gagal operasi pada pertemuan
  ///
  /// In id, this message translates to:
  /// **'Gagal: {detail}'**
  String meetingActionFailed(String detail);

  /// Snackbar hasil sinkronisasi jadwal publikasi
  ///
  /// In id, this message translates to:
  /// **'{count, plural, =0{Tidak ada pertemuan terjadwal yang jatuh tempo saat ini.} other{{count} pertemuan terjadwal yang jatuh tempo berhasil dipublikasikan.}}'**
  String meetingSyncScheduleSuccess(int count);

  /// Snackbar gagal sinkronisasi jadwal
  ///
  /// In id, this message translates to:
  /// **'Gagal menyinkronkan jadwal: {detail}'**
  String meetingSyncFailed(String detail);

  /// Judul tampilan saat belum memilih kelas
  ///
  /// In id, this message translates to:
  /// **'Pilih Kelas Pembelajaran'**
  String get meetingNoClassTitle;

  /// Instruksi saat belum memilih kelas
  ///
  /// In id, this message translates to:
  /// **'Anda belum memilih kelas. Silakan bergabung menggunakan kode kelas atau pilih kelas dari Beranda untuk melihat pertemuan.'**
  String get meetingNoClassBody;

  /// Tombol menuju layar gabung kelas
  ///
  /// In id, this message translates to:
  /// **'Gabung Kelas'**
  String get meetingJoinClassBtn;

  /// Label bar pemilih kelas aktif
  ///
  /// In id, this message translates to:
  /// **'Kelas:'**
  String get meetingClassLabel;

  /// Teks indikator memuat daftar pertemuan
  ///
  /// In id, this message translates to:
  /// **'Memuat pertemuan...'**
  String get meetingLoading;

  /// Judul status kosong daftar pertemuan
  ///
  /// In id, this message translates to:
  /// **'Belum Ada Pertemuan'**
  String get meetingEmptyTitle;

  /// Deskripsi status kosong untuk staf/pengajar
  ///
  /// In id, this message translates to:
  /// **'Buat pertemuan baru untuk mulai mengunggah materi, kuis pretest, dan video pembelajaran.'**
  String get meetingEmptyStaffDesc;

  /// Deskripsi status kosong untuk mahasiswa
  ///
  /// In id, this message translates to:
  /// **'Pengajar belum mempublikasikan pertemuan pembelajaran di kelas ini.'**
  String get meetingEmptyStudentDesc;

  /// Tombol buat pertemuan pertama pada status kosong
  ///
  /// In id, this message translates to:
  /// **'Buat Pertemuan Pertama'**
  String get meetingCreateFirstBtn;

  /// Nomor pertemuan pada kartu atau header
  ///
  /// In id, this message translates to:
  /// **'Pertemuan {number}'**
  String meetingCardNumber(int number);

  /// Label jadwal terbit pertemuan pada kartu
  ///
  /// In id, this message translates to:
  /// **'Terbit: {when}'**
  String meetingPublishAtLabel(String when);

  /// Label chip modul pretest
  ///
  /// In id, this message translates to:
  /// **'Pretest'**
  String get meetingModulePretest;

  /// Label chip modul materi
  ///
  /// In id, this message translates to:
  /// **'Materi'**
  String get meetingModuleMateri;

  /// Label chip modul video
  ///
  /// In id, this message translates to:
  /// **'Video'**
  String get meetingModuleVideo;

  /// Label chip modul post test
  ///
  /// In id, this message translates to:
  /// **'Post Test'**
  String get meetingModulePosttest;

  /// Teks indikator memuat detail pertemuan
  ///
  /// In id, this message translates to:
  /// **'Memuat hub pertemuan...'**
  String get meetingDetailLoading;

  /// Judul AppBar detail pertemuan saat fallback
  ///
  /// In id, this message translates to:
  /// **'Detail Pertemuan'**
  String get meetingDetailTitle;

  /// Pesan error pertemuan tidak ditemukan
  ///
  /// In id, this message translates to:
  /// **'Pertemuan tidak ditemukan.'**
  String get meetingNotFound;

  /// Pesan error gagal memuat detail pertemuan
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat detail pertemuan: {detail}'**
  String meetingLoadDetailFailed(String detail);

  /// Snackbar kunci pertemuan terjadwal bagi mahasiswa
  ///
  /// In id, this message translates to:
  /// **'Pertemuan ini masih berstatus Terjadwal. Konten akan dibuka pada {when}.'**
  String meetingScheduledLockedNotice(String when);

  /// Teks fallback waktu jadwal mendatang saat tanggal kosong
  ///
  /// In id, this message translates to:
  /// **'waktu jadwal mendatang'**
  String get meetingScheduledFutureFallback;

  /// Judul pemilih tanggal publikasi
  ///
  /// In id, this message translates to:
  /// **'Pilih Tanggal Publikasi Pertemuan'**
  String get meetingPickScheduleDateTitle;

  /// Judul pemilih jam publikasi
  ///
  /// In id, this message translates to:
  /// **'Pilih Jam Publikasi (WIB)'**
  String get meetingPickScheduleTimeTitle;

  /// Validasi waktu jadwal publikasi harus masa depan
  ///
  /// In id, this message translates to:
  /// **'Waktu publikasi terjadwal harus di waktu mendatang.'**
  String get meetingScheduleMustBeFuture;

  /// Snackbar sukses menjadwalkan pertemuan
  ///
  /// In id, this message translates to:
  /// **'Pertemuan berhasil dijadwalkan terbit pada {when}.'**
  String meetingScheduledSuccess(String when);

  /// Snackbar gagal menjadwalkan pertemuan
  ///
  /// In id, this message translates to:
  /// **'Gagal menjadwalkan pertemuan: {detail}'**
  String meetingScheduleFailed(String detail);

  /// Judul konfirmasi ubah status pertemuan
  ///
  /// In id, this message translates to:
  /// **'Ubah Status ke {status}?'**
  String meetingChangeStatusConfirmTitle(String status);

  /// Deskripsi konfirmasi publikasikan pertemuan
  ///
  /// In id, this message translates to:
  /// **'Pertemuan ini akan dapat diakses oleh seluruh anggota kelas yang aktif.'**
  String get meetingChangeStatusPublishBody;

  /// Deskripsi konfirmasi arsipkan pertemuan
  ///
  /// In id, this message translates to:
  /// **'Pertemuan ini akan diarsipkan dan tidak lagi muncul sebagai sesi aktif.'**
  String get meetingChangeStatusArchiveBody;

  /// Snackbar sukses ubah status pertemuan
  ///
  /// In id, this message translates to:
  /// **'Status berhasil diubah menjadi {status}'**
  String meetingStatusChangedSuccess(String status);

  /// Judul dialog edit informasi pertemuan
  ///
  /// In id, this message translates to:
  /// **'Edit Informasi Pertemuan'**
  String get meetingEditDialogTitle;

  /// Label field deskripsi pertemuan
  ///
  /// In id, this message translates to:
  /// **'Deskripsi / Ringkasan'**
  String get meetingDescriptionLabel;

  /// Tooltip ikon edit pertemuan
  ///
  /// In id, this message translates to:
  /// **'Edit Info Pertemuan'**
  String get meetingEditTooltip;

  /// Tooltip ikon hapus pertemuan
  ///
  /// In id, this message translates to:
  /// **'Hapus Pertemuan'**
  String get meetingDeleteTooltip;

  /// Tooltip ikon popup menu kelola status
  ///
  /// In id, this message translates to:
  /// **'Kelola Status'**
  String get meetingManageStatusTooltip;

  /// Menu publikasikan sekarang
  ///
  /// In id, this message translates to:
  /// **'Publikasikan Sekarang (Published)'**
  String get meetingMenuPublishNow;

  /// Menu jadwalkan publikasi
  ///
  /// In id, this message translates to:
  /// **'Jadwalkan Publikasi (Scheduled)'**
  String get meetingMenuSchedule;

  /// Menu jadikan draf
  ///
  /// In id, this message translates to:
  /// **'Jadikan Draft / Batalkan Jadwal'**
  String get meetingMenuDraft;

  /// Menu arsipkan pertemuan
  ///
  /// In id, this message translates to:
  /// **'Arsipkan (Archived)'**
  String get meetingMenuArchive;

  /// Judul dialog konfirmasi hapus pertemuan
  ///
  /// In id, this message translates to:
  /// **'Hapus Pertemuan Ini?'**
  String get meetingDeleteConfirmTitle;

  /// Deskripsi dialog konfirmasi hapus pertemuan
  ///
  /// In id, this message translates to:
  /// **'Tindakan ini akan menghapus pertemuan dari daftar kelas.'**
  String get meetingDeleteConfirmBody;

  /// Tombol aksi hapus pada dialog konfirmasi
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get meetingDeleteAction;

  /// Snackbar sukses hapus pertemuan
  ///
  /// In id, this message translates to:
  /// **'Pertemuan berhasil dihapus.'**
  String get meetingDeletedSuccess;

  /// Snackbar gagal hapus pertemuan
  ///
  /// In id, this message translates to:
  /// **'Gagal menghapus: {detail}'**
  String meetingDeleteFailed(String detail);

  /// Deskripsi default pertemuan jika tidak diisi pengajar
  ///
  /// In id, this message translates to:
  /// **'Satu pertemuan menghubungkan kuis pretest, materi bacaan terstruktur, video pembelajaran, dan post test evaluasi.'**
  String get meetingDefaultDescription;

  /// Judul kartu banner pertemuan terjadwal
  ///
  /// In id, this message translates to:
  /// **'Pertemuan Terjadwal'**
  String get meetingScheduledBannerTitle;

  /// Deskripsi banner jadwal terbit pertemuan
  ///
  /// In id, this message translates to:
  /// **'Dijadwalkan terbit pada {when}. Publikasi berjalan saat cron/sinkronisasi berikutnya (dalam kisaran jadwal), bukan tepat-menit otomatis.'**
  String meetingScheduledBanner(String when);

  /// Deskripsi banner jadwal jika tanggal belum ditetapkan
  ///
  /// In id, this message translates to:
  /// **'Pertemuan disiapkan untuk jadwal publikasi mendatang.'**
  String get meetingScheduledBannerFallback;

  /// Judul bagian daftar modul pembelajaran
  ///
  /// In id, this message translates to:
  /// **'Modul Pembelajaran'**
  String get meetingModulesTitle;

  /// Judul kartu modul materi
  ///
  /// In id, this message translates to:
  /// **'Materi Pembelajaran'**
  String get meetingModuleMaterialTitle;

  /// Subjudul materi jika sudah tersedia
  ///
  /// In id, this message translates to:
  /// **'Materi bacaan terstruktur format Quill Delta'**
  String get meetingModuleMaterialSubActive;

  /// Subjudul materi kosong untuk pengajar
  ///
  /// In id, this message translates to:
  /// **'Materi belum dibuat. Klik untuk membuat materi baru.'**
  String get meetingModuleMaterialSubStaffEmpty;

  /// Subjudul materi kosong untuk mahasiswa
  ///
  /// In id, this message translates to:
  /// **'Materi belum diunggah oleh pengajar'**
  String get meetingModuleMaterialSubStudentEmpty;

  /// Tombol buka materi
  ///
  /// In id, this message translates to:
  /// **'Buka Materi'**
  String get meetingModuleMaterialActionOpen;

  /// Tombol buat materi baru
  ///
  /// In id, this message translates to:
  /// **'Buat Materi'**
  String get meetingModuleMaterialActionCreate;

  /// Judul kartu modul pretest
  ///
  /// In id, this message translates to:
  /// **'Kuis Pretest'**
  String get meetingModulePretestTitle;

  /// Subjudul kuis pretest jika sudah aktif
  ///
  /// In id, this message translates to:
  /// **'Uji pemahaman awal sebelum memulai materi inti'**
  String get meetingModulePretestSubActive;

  /// Subjudul kuis pretest kosong untuk pengajar
  ///
  /// In id, this message translates to:
  /// **'Pretest belum diaktifkan. Klik untuk membuat pretest.'**
  String get meetingModulePretestSubStaffEmpty;

  /// Subjudul kuis pretest kosong untuk mahasiswa
  ///
  /// In id, this message translates to:
  /// **'Pretest belum diaktifkan untuk pertemuan ini'**
  String get meetingModulePretestSubStudentEmpty;

  /// Tombol mulai kuis pretest
  ///
  /// In id, this message translates to:
  /// **'Mulai Pretest'**
  String get meetingModulePretestActionStart;

  /// Tombol buat kuis pretest baru
  ///
  /// In id, this message translates to:
  /// **'Buat Pretest'**
  String get meetingModulePretestActionCreate;

  /// Tombol kelola butir soal kuis
  ///
  /// In id, this message translates to:
  /// **'Kelola Soal'**
  String get meetingModulePretestManageQuestions;

  /// Badge prasyarat pembukaan kuis pretest
  ///
  /// In id, this message translates to:
  /// **'Wajib pernah buka materi'**
  String get meetingModulePretestBadgeNotice;

  /// Judul kartu modul video
  ///
  /// In id, this message translates to:
  /// **'Video Pembelajaran'**
  String get meetingModuleVideoTitle;

  /// Subjudul video jika sudah ditautkan
  ///
  /// In id, this message translates to:
  /// **'Video tutorial & demonstrasi interaktif'**
  String get meetingModuleVideoSubActive;

  /// Subjudul video kosong untuk pengajar
  ///
  /// In id, this message translates to:
  /// **'Video belum ditautkan. Klik untuk menambahkan link video.'**
  String get meetingModuleVideoSubStaffEmpty;

  /// Subjudul video kosong untuk mahasiswa
  ///
  /// In id, this message translates to:
  /// **'Video belum ditautkan ke pertemuan ini'**
  String get meetingModuleVideoSubStudentEmpty;

  /// Tombol tonton video pembelajaran
  ///
  /// In id, this message translates to:
  /// **'Tonton Video'**
  String get meetingModuleVideoActionWatch;

  /// Tombol tambah tautan video baru
  ///
  /// In id, this message translates to:
  /// **'Tambah Video'**
  String get meetingModuleVideoActionAdd;

  /// Judul kartu modul post test
  ///
  /// In id, this message translates to:
  /// **'Kuis Post Test'**
  String get meetingModulePosttestTitle;

  /// Subjudul kuis post test jika sudah aktif
  ///
  /// In id, this message translates to:
  /// **'Evaluasi akhir capaian pembelajaran setelah memahami materi'**
  String get meetingModulePosttestSubActive;

  /// Subjudul kuis post test kosong untuk pengajar
  ///
  /// In id, this message translates to:
  /// **'Post test belum dibuat. Klik untuk membuat post test.'**
  String get meetingModulePosttestSubStaffEmpty;

  /// Subjudul kuis post test kosong untuk mahasiswa
  ///
  /// In id, this message translates to:
  /// **'Post test belum diaktifkan untuk pertemuan ini'**
  String get meetingModulePosttestSubStudentEmpty;

  /// Tombol mulai kuis post test
  ///
  /// In id, this message translates to:
  /// **'Mulai Post Test'**
  String get meetingModulePosttestActionStart;

  /// Tombol buat kuis post test baru
  ///
  /// In id, this message translates to:
  /// **'Buat Post Test'**
  String get meetingModulePosttestActionCreate;

  /// Judul kartu modul tugas pada pertemuan
  ///
  /// In id, this message translates to:
  /// **'Tugas Pembelajaran'**
  String get meetingModuleAssignmentTitle;

  /// Subjudul modul tugas jika sudah aktif
  ///
  /// In id, this message translates to:
  /// **'Tugas pertemuan dengan tenggat dan instruksi terstruktur'**
  String get meetingModuleAssignmentSubActive;

  /// Subjudul tugas kosong untuk pengajar
  ///
  /// In id, this message translates to:
  /// **'Tugas belum ditautkan. Klik untuk membuat tugas baru.'**
  String get meetingModuleAssignmentSubStaffEmpty;

  /// Subjudul tugas kosong untuk mahasiswa
  ///
  /// In id, this message translates to:
  /// **'Belum ada tugas pembelajaran untuk pertemuan ini'**
  String get meetingModuleAssignmentSubStudentEmpty;

  /// Tombol buka tugas pertemuan
  ///
  /// In id, this message translates to:
  /// **'Buka Tugas'**
  String get meetingModuleAssignmentActionOpen;

  /// Tombol buat tugas pertemuan baru
  ///
  /// In id, this message translates to:
  /// **'Buat Tugas'**
  String get meetingModuleAssignmentActionCreate;

  /// Label ringkas modul tugas
  ///
  /// In id, this message translates to:
  /// **'Tugas'**
  String get meetingModuleAssignment;

  /// Label berkas lampiran instruksi tugas dosen
  ///
  /// In id, this message translates to:
  /// **'Berkas Lampiran Petunjuk'**
  String get assignmentInstructionAttachment;

  /// Tombol unduh berkas lampiran petunjuk
  ///
  /// In id, this message translates to:
  /// **'Unduh Petunjuk'**
  String get assignmentDownloadInstruction;

  /// Tombol buka berkas lampiran petunjuk
  ///
  /// In id, this message translates to:
  /// **'Buka Petunjuk'**
  String get assignmentViewInstruction;

  /// Pesan saat tidak ada berkas petunjuk
  ///
  /// In id, this message translates to:
  /// **'Tidak ada berkas lampiran petunjuk'**
  String get assignmentNoInstructionAttachment;

  /// Judul metrik cache berkas sementara disk
  ///
  /// In id, this message translates to:
  /// **'Berkas Sementara (Disk)'**
  String get profileCacheDiskTitle;

  /// Judul metrik cache memori RAM
  ///
  /// In id, this message translates to:
  /// **'Cache Memori (RAM)'**
  String get profileCacheRamTitle;

  /// Pesan snackbar saat cache berhasil dibersihkan
  ///
  /// In id, this message translates to:
  /// **'Cache dan berkas sementara berhasil dibersihkan'**
  String get profileCacheCleanSuccess;

  /// Label tombol modul yang belum aktif
  ///
  /// In id, this message translates to:
  /// **'Belum Tersedia'**
  String get meetingModuleNotAvailable;

  /// Judul dialog pembuatan kuis pretest
  ///
  /// In id, this message translates to:
  /// **'Buat Kuis Pretest'**
  String get meetingCreatePretestTitle;

  /// Judul bawaan kuis pretest
  ///
  /// In id, this message translates to:
  /// **'Pretest Pertemuan {number}'**
  String meetingPretestDefaultTitle(int number);

  /// Label field judul pretest
  ///
  /// In id, this message translates to:
  /// **'Judul Pretest'**
  String get meetingPretestTitleLabel;

  /// Label durasi kuis dalam menit
  ///
  /// In id, this message translates to:
  /// **'Durasi (Menit)'**
  String get meetingDurationLabel;

  /// Validasi durasi kuis harus angka positif
  ///
  /// In id, this message translates to:
  /// **'Durasi harus > 0 menit'**
  String get meetingDurationMustBePositive;

  /// Tombol simpan kuis dan lanjut mengelola soal
  ///
  /// In id, this message translates to:
  /// **'Simpan & Kelola Soal'**
  String get meetingSaveAndManageQuestionsBtn;

  /// Judul dialog pembuatan kuis post test
  ///
  /// In id, this message translates to:
  /// **'Buat Kuis Post Test'**
  String get meetingCreatePosttestTitle;

  /// Judul bawaan kuis post test
  ///
  /// In id, this message translates to:
  /// **'Post Test Pertemuan {number}'**
  String meetingPosttestDefaultTitle(int number);

  /// Label field judul post test
  ///
  /// In id, this message translates to:
  /// **'Judul Post Test'**
  String get meetingPosttestTitleLabel;

  /// Judul dialog tambah video pembelajaran
  ///
  /// In id, this message translates to:
  /// **'Tambah Video Pembelajaran'**
  String get meetingAddVideoTitle;

  /// Label dropdown penyedia video
  ///
  /// In id, this message translates to:
  /// **'Penyedia Video'**
  String get meetingVideoProviderLabel;

  /// Label input URL video
  ///
  /// In id, this message translates to:
  /// **'URL Video'**
  String get meetingVideoUrlLabel;

  /// Validasi URL video kosong
  ///
  /// In id, this message translates to:
  /// **'URL wajib diisi'**
  String get meetingVideoUrlRequired;

  /// Validasi protokol URL video harus https
  ///
  /// In id, this message translates to:
  /// **'URL harus diawali https://'**
  String get meetingVideoUrlInvalid;

  /// Tombol simpan video
  ///
  /// In id, this message translates to:
  /// **'Simpan Video'**
  String get meetingSaveVideoBtn;

  /// Judul sheet kelola soal kuis
  ///
  /// In id, this message translates to:
  /// **'Kelola Soal {testTitle}'**
  String meetingManageQuestionsTitle(String testTitle);

  /// Keterangan jumlah butir soal aktif
  ///
  /// In id, this message translates to:
  /// **'Jumlah Soal: {count} soal aktif'**
  String meetingQuestionCountActive(int count);

  /// Tombol tambah soal baru
  ///
  /// In id, this message translates to:
  /// **'Tambah Soal'**
  String get meetingAddQuestionBtn;

  /// Tombol publikasikan kuis
  ///
  /// In id, this message translates to:
  /// **'Publikasikan Kuis'**
  String get meetingPublishQuizBtn;

  /// Peringatan kuis kosong sebelum dipublikasikan
  ///
  /// In id, this message translates to:
  /// **'Tambahkan minimal 1 soal sebelum mempublikasikan kuis.'**
  String get meetingPublishMinOneQuestion;

  /// Snackbar gagal publikasi kuis
  ///
  /// In id, this message translates to:
  /// **'Gagal publikasi: {detail}'**
  String meetingPublishFailed(String detail);

  /// Snackbar sukses publikasikan kuis
  ///
  /// In id, this message translates to:
  /// **'Kuis berhasil dipublikasikan! Mahasiswa sekarang dapat mengakses kuis ini.'**
  String get meetingQuizPublishedSuccess;

  /// Judul status kosong sheet soal kuis draf
  ///
  /// In id, this message translates to:
  /// **'Draft, belum ada soal aktif.'**
  String get meetingDraftNoQuestionsTitle;

  /// Instruksi status kosong sheet soal kuis
  ///
  /// In id, this message translates to:
  /// **'Klik tombol \"Tambah Soal\" untuk membuat soal kuis pertama.'**
  String get meetingDraftNoQuestionsBody;

  /// Label jumlah poin soal
  ///
  /// In id, this message translates to:
  /// **'{points} poin'**
  String meetingPointsLabel(int points);

  /// Tombol edit soal atau item
  ///
  /// In id, this message translates to:
  /// **'Edit'**
  String get meetingEditAction;

  /// Peringatan dilarang menghapus soal terakhir pada kuis terbit
  ///
  /// In id, this message translates to:
  /// **'Tidak dapat menghapus soal aktif terakhir pada kuis yang berstatus Published. Silakan arsipkan kuis terlebih dahulu jika ingin menonaktifkannya.'**
  String get meetingCannotDeleteLastPublished;

  /// Judul dialog konfirmasi hapus butir soal
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi Hapus Soal'**
  String get meetingDeleteQuestionConfirmTitle;

  /// Deskripsi konfirmasi hapus butir soal
  ///
  /// In id, this message translates to:
  /// **'Apakah Anda yakin ingin menghapus Soal {number}? Jika kuis sudah pernah dikerjakan siswa, soal akan diarsipkan (soft-delete) dan riwayat nilai siswa terdahulu tetap aman.'**
  String meetingDeleteQuestionConfirmBody(int number);

  /// Tombol hapus soal pada dialog konfirmasi
  ///
  /// In id, this message translates to:
  /// **'Hapus Soal'**
  String get meetingDeleteQuestionBtn;

  /// Judul dialog tambah butir soal baru
  ///
  /// In id, this message translates to:
  /// **'Tambah Soal Baru'**
  String get meetingAddQuestionDialogTitle;

  /// Judul dialog edit butir soal
  ///
  /// In id, this message translates to:
  /// **'Edit Soal'**
  String get meetingEditQuestionDialogTitle;

  /// Label input teks pertanyaan
  ///
  /// In id, this message translates to:
  /// **'Teks Pertanyaan *'**
  String get meetingQuestionTextLabel;

  /// Hint input teks pertanyaan
  ///
  /// In id, this message translates to:
  /// **'Masukkan pertanyaan...'**
  String get meetingQuestionTextHint;

  /// Validasi teks pertanyaan kosong
  ///
  /// In id, this message translates to:
  /// **'Teks pertanyaan wajib diisi'**
  String get meetingQuestionTextRequired;

  /// Label input poin soal
  ///
  /// In id, this message translates to:
  /// **'Poin Soal (1 - 100) *'**
  String get meetingQuestionPointsLabel;

  /// Validasi poin soal kosong
  ///
  /// In id, this message translates to:
  /// **'Poin wajib diisi'**
  String get meetingQuestionPointsRequired;

  /// Validasi rentang poin soal
  ///
  /// In id, this message translates to:
  /// **'Poin harus antara 1 - 100'**
  String get meetingQuestionPointsInvalid;

  /// Judul seksi 5 pilihan jawaban
  ///
  /// In id, this message translates to:
  /// **'Pilihan Jawaban & Kunci (A - E) *'**
  String get meetingOptionsSectionTitle;

  /// Petunjuk seksi 5 pilihan jawaban
  ///
  /// In id, this message translates to:
  /// **'Tentukan 5 pilihan jawaban (A sampai E) dan pilih satu radio sebagai kunci jawaban benar.'**
  String get meetingOptionsSectionSubtitle;

  /// Label field pilihan jawaban yang menjadi kunci benar
  ///
  /// In id, this message translates to:
  /// **'Pilihan {letter} (★ KUNCI BENAR)'**
  String meetingOptionLabelKey(String letter);

  /// Label field pilihan jawaban biasa
  ///
  /// In id, this message translates to:
  /// **'Pilihan {letter}'**
  String meetingOptionLabelRegular(String letter);

  /// Validasi pilihan jawaban kosong
  ///
  /// In id, this message translates to:
  /// **'Pilihan {letter} tidak boleh kosong'**
  String meetingOptionRequired(String letter);

  /// Judul seksi pilihan jawaban warisan tambahan
  ///
  /// In id, this message translates to:
  /// **'Pilihan Tambahan Terarsip (Legacy - Read Only):'**
  String get meetingLegacyOptionsTitle;

  /// Pesan materi tidak ditemukan
  ///
  /// In id, this message translates to:
  /// **'Materi tidak ditemukan.'**
  String get materialNotFound;

  /// Pesan materi tidak ditemukan atau telah dihapus pada editor
  ///
  /// In id, this message translates to:
  /// **'Materi tidak ditemukan atau telah dihapus.'**
  String get materialNotFoundOrDeleted;

  /// Pesan error gagal memuat materi
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat materi: {detail}'**
  String materialLoadFailed(String detail);

  /// Teks indikator memuat materi pembelajaran
  ///
  /// In id, this message translates to:
  /// **'Memuat materi pembelajaran...'**
  String get materialLoading;

  /// Judul AppBar pembaca materi saat fallback
  ///
  /// In id, this message translates to:
  /// **'Materi'**
  String get materialAppBarTitle;

  /// Tooltip ikon edit materi pada pembaca
  ///
  /// In id, this message translates to:
  /// **'Edit Materi'**
  String get materialEditTooltip;

  /// Label format konten materi
  ///
  /// In id, this message translates to:
  /// **'Format: {format}'**
  String materialFormat(String format);

  /// Status saat sistem sedang mencatat progres pembacaan
  ///
  /// In id, this message translates to:
  /// **'Mencatat Progres...'**
  String get materialRecordingProgress;

  /// Status sukses progres pembacaan materi tercatat
  ///
  /// In id, this message translates to:
  /// **'Tercatat Dibuka'**
  String get materialRecordedOpened;

  /// Status gagal catat progres pembacaan dengan ajakan coba lagi
  ///
  /// In id, this message translates to:
  /// **'Belum Tersinkron (Ketuk untuk coba lagi)'**
  String get materialNotSyncedTapRetry;

  /// Teks placeholder saat dokumen materi kosong
  ///
  /// In id, this message translates to:
  /// **'Materi kosong.'**
  String get materialEmptyPlaceholder;

  /// Judul dialog sisipkan gambar pada editor
  ///
  /// In id, this message translates to:
  /// **'Sisipkan Gambar (URL Cloudinary)'**
  String get materialInsertImageTitle;

  /// Petunjuk aturan keamanan penyimpanan gambar materi
  ///
  /// In id, this message translates to:
  /// **'Sesuai aturan keamanan Farlean LMS, gambar harus bersumber dari URL eksternal (Cloudinary). Gambar base64 dilarang.'**
  String get materialInsertImageSecurityNote;

  /// Label field input URL gambar
  ///
  /// In id, this message translates to:
  /// **'URL Gambar (https://...)'**
  String get materialImageUrlLabel;

  /// Validasi URL gambar kosong
  ///
  /// In id, this message translates to:
  /// **'URL gambar wajib diisi'**
  String get materialImageUrlRequired;

  /// Validasi penolakan gambar base64 inline
  ///
  /// In id, this message translates to:
  /// **'Gambar base64 inline dilarang.'**
  String get materialImageBase64Forbidden;

  /// Validasi protokol URL gambar harus https
  ///
  /// In id, this message translates to:
  /// **'URL harus diawali dengan https://'**
  String get materialImageUrlInvalid;

  /// Tombol aksi sisipkan gambar ke dokumen
  ///
  /// In id, this message translates to:
  /// **'Sisipkan'**
  String get materialInsertBtn;

  /// Peringatan template hanya untuk editor kosong
  ///
  /// In id, this message translates to:
  /// **'Template hanya dapat disisipkan pada editor kosong agar konten tidak tertimpa.'**
  String get materialTemplateOnlyEmpty;

  /// Snackbar sukses menyisipkan template struktur materi
  ///
  /// In id, this message translates to:
  /// **'Template materi berhasil disisipkan. Silakan lengkapi setiap bagian.'**
  String get materialTemplateSuccess;

  /// Snackbar gagal menyisipkan template materi
  ///
  /// In id, this message translates to:
  /// **'Gagal menyisipkan template: {detail}'**
  String materialTemplateFailed(String detail);

  /// Judul dialog pratinjau materi jika judul dokumen kosong
  ///
  /// In id, this message translates to:
  /// **'Pratinjau Materi'**
  String get materialPreviewTitle;

  /// Judul dialog konfirmasi buang perubahan materi
  ///
  /// In id, this message translates to:
  /// **'Buang Perubahan?'**
  String get materialDiscardConfirmTitle;

  /// Isi dialog konfirmasi buang perubahan materi
  ///
  /// In id, this message translates to:
  /// **'Ada perubahan materi yang belum disimpan. Keluar sekarang akan membuang perubahan tersebut.'**
  String get materialDiscardConfirmBody;

  /// Tombol batal buang perubahan untuk tetap mengedit
  ///
  /// In id, this message translates to:
  /// **'Lanjutkan Mengedit'**
  String get materialKeepEditingBtn;

  /// Tombol konfirmasi buang perubahan materi
  ///
  /// In id, this message translates to:
  /// **'Buang Perubahan'**
  String get materialDiscardChangesBtn;

  /// Peringatan judul materi kosong saat menyimpan
  ///
  /// In id, this message translates to:
  /// **'Judul materi wajib diisi.'**
  String get materialTitleRequired;

  /// Snackbar sukses simpan materi dengan statusnya
  ///
  /// In id, this message translates to:
  /// **'Materi berhasil disimpan sebagai {status}.'**
  String materialSavedAsStatus(String status);

  /// Snackbar gagal menyimpan materi
  ///
  /// In id, this message translates to:
  /// **'Gagal menyimpan materi: {detail}'**
  String materialSaveFailed(String detail);

  /// Judul AppBar saat membuat materi baru
  ///
  /// In id, this message translates to:
  /// **'Buat Materi Baru'**
  String get materialCreateTitle;

  /// Judul AppBar saat mengedit materi yang ada
  ///
  /// In id, this message translates to:
  /// **'Edit Materi'**
  String get materialEditTitle;

  /// Tooltip ikon pratinjau tampilan mahasiswa
  ///
  /// In id, this message translates to:
  /// **'Pratinjau Tampilan Mahasiswa'**
  String get materialPreviewTooltip;

  /// Tombol publikasikan materi
  ///
  /// In id, this message translates to:
  /// **'Publikasikan'**
  String get materialPublishBtn;

  /// Label field input judul materi pembelajaran
  ///
  /// In id, this message translates to:
  /// **'Judul Materi Pembelajaran'**
  String get materialTitleLabel;

  /// Tombol buka dialog sisipkan gambar
  ///
  /// In id, this message translates to:
  /// **'Gambar'**
  String get materialImageBtn;

  /// Tombol toolbar editor untuk melampirkan berkas dokumen
  ///
  /// In id, this message translates to:
  /// **'Lampirkan Berkas'**
  String get materialAttachFileBtn;

  /// Tombol memilih gambar dari perangkat di dialog gambar
  ///
  /// In id, this message translates to:
  /// **'Pilih dari Perangkat'**
  String get materialPickImageDevice;

  /// Snackbar konfirmasi lampiran berhasil ditambahkan
  ///
  /// In id, this message translates to:
  /// **'Berkas berhasil dilampirkan'**
  String get materialAttachmentSuccess;

  /// Judul daftar lampiran dokumen materi
  ///
  /// In id, this message translates to:
  /// **'Berkas Lampiran Materi'**
  String get materialAttachmentsTitle;

  /// Tombol aksi membuka berkas lampiran materi
  ///
  /// In id, this message translates to:
  /// **'Buka Berkas'**
  String get materialAttachmentOpen;

  /// Tombol sisipkan template struktur materi
  ///
  /// In id, this message translates to:
  /// **'Template'**
  String get materialTemplateBtn;

  /// Indikator jumlah karakter dan format editor materi
  ///
  /// In id, this message translates to:
  /// **'{count} karakter • Format: Delta JSON'**
  String materialCharCountDeltaJson(int count);

  /// Banner peringatan editor materi masih 0 karakter
  ///
  /// In id, this message translates to:
  /// **'Materi masih kosong. Tulis konten atau sisipkan template sebelum menyimpan.'**
  String get materialEmptyWarning;

  /// Placeholder editor Quill saat kosong
  ///
  /// In id, this message translates to:
  /// **'Tuliskan materi pembelajaran terstruktur di sini...'**
  String get materialEditorPlaceholder;

  /// Pesan error gagal memuat detail kelas
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat detail kelas: {detail}'**
  String classDetailLoadFailed(String detail);

  /// Tombol simpan pertemuan pada dialog buat pertemuan kelas
  ///
  /// In id, this message translates to:
  /// **'Simpan Pertemuan'**
  String get classSaveMeetingBtn;

  /// Judul konfirmasi arsipkan kelas
  ///
  /// In id, this message translates to:
  /// **'Arsipkan Kelas?'**
  String get classArchiveConfirmTitle;

  /// Isi konfirmasi arsipkan kelas
  ///
  /// In id, this message translates to:
  /// **'Kelas yang diarsipkan akan terkunci untuk pengeditan dan tidak lagi menerima anggota baru. Anggota lama tetap dapat membaca materi.'**
  String get classArchiveConfirmBody;

  /// Tombol konfirmasi arsipkan kelas
  ///
  /// In id, this message translates to:
  /// **'Arsipkan'**
  String get classArchiveBtn;

  /// Snackbar sukses arsipkan kelas
  ///
  /// In id, this message translates to:
  /// **'Kelas berhasil diarsipkan.'**
  String get classArchiveSuccess;

  /// Snackbar gagal arsipkan kelas
  ///
  /// In id, this message translates to:
  /// **'Gagal mengarsipkan: {detail}'**
  String classArchiveFailed(String detail);

  /// Judul konfirmasi aktifkan kembali kelas
  ///
  /// In id, this message translates to:
  /// **'Aktifkan Kembali Kelas?'**
  String get classReactivateConfirmTitle;

  /// Isi konfirmasi aktifkan kembali kelas
  ///
  /// In id, this message translates to:
  /// **'Kelas yang diaktifkan kembali akan dapat menerima anggota baru serta mengizinkan pengelolaan pertemuan dan kuis seperti semula.'**
  String get classReactivateConfirmBody;

  /// Tombol konfirmasi aktifkan kembali kelas
  ///
  /// In id, this message translates to:
  /// **'Aktifkan'**
  String get classReactivateBtn;

  /// Snackbar sukses aktifkan kembali kelas
  ///
  /// In id, this message translates to:
  /// **'Kelas berhasil diaktifkan kembali.'**
  String get classReactivateSuccess;

  /// Snackbar gagal aktifkan kembali kelas
  ///
  /// In id, this message translates to:
  /// **'Gagal mengaktifkan kembali kelas: {detail}'**
  String classReactivateFailed(String detail);

  /// Teks loading detail kelas
  ///
  /// In id, this message translates to:
  /// **'Memuat detail kelas...'**
  String get classDetailLoading;

  /// Judul AppBar detail kelas saat fallback
  ///
  /// In id, this message translates to:
  /// **'Detail Kelas'**
  String get classDetailTitle;

  /// Pesan kelas tidak ditemukan
  ///
  /// In id, this message translates to:
  /// **'Kelas tidak ditemukan.'**
  String get classNotFound;

  /// Tooltip ikon arsipkan kelas
  ///
  /// In id, this message translates to:
  /// **'Arsipkan Kelas'**
  String get classArchiveTooltip;

  /// Tooltip ikon aktifkan kembali kelas
  ///
  /// In id, this message translates to:
  /// **'Aktifkan Kembali Kelas'**
  String get classReactivateTooltip;

  /// Snackbar kode kelas berhasil disalin
  ///
  /// In id, this message translates to:
  /// **'Kode kelas {code} disalin ke clipboard.'**
  String classCodeCopied(String code);

  /// Jumlah anggota kelas pada header
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} Anggota}}'**
  String classMemberCount(int count);

  /// Jumlah pertemuan kelas pada header
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{•  {count} Pertemuan}}'**
  String classMeetingCount(int count);

  /// Tab pertemuan kelas
  ///
  /// In id, this message translates to:
  /// **'Pertemuan'**
  String get classTabMeetings;

  /// Tab rekap nilai kelas
  ///
  /// In id, this message translates to:
  /// **'Rekap Nilai'**
  String get classTabGrades;

  /// Tab anggota kelas
  ///
  /// In id, this message translates to:
  /// **'Anggota Kelas'**
  String get classTabMembers;

  /// Deskripsi belum ada pertemuan untuk pengajar
  ///
  /// In id, this message translates to:
  /// **'Buat pertemuan baru untuk mulai mengisi materi, pretest, dan video pembelajaran.'**
  String get classEmptyMeetingOwnerDesc;

  /// Deskripsi belum ada pertemuan untuk siswa
  ///
  /// In id, this message translates to:
  /// **'Pengajar belum mempublikasikan pertemuan di kelas ini.'**
  String get classEmptyMeetingStudentDesc;

  /// Tombol buat pertemuan pada tab pertemuan kosong
  ///
  /// In id, this message translates to:
  /// **'Buat Pertemuan'**
  String get classCreateMeetingBtn;

  /// Judul banner pembatasan akses rekap nilai
  ///
  /// In id, this message translates to:
  /// **'Akses Rekap Nilai Terbatas'**
  String get classGradebookRestrictedTitle;

  /// Deskripsi pembatasan akses rekap nilai
  ///
  /// In id, this message translates to:
  /// **'Sesuai kebijakan perlindungan data akademik Farlean LMS, hanya Pengajar Pemilik Kelas dan Admin yang memiliki wewenang untuk mengakses rekapitulasi nilai mahasiswa di kelas ini.'**
  String get classGradebookRestrictedBody;

  /// Teks status kosong rekap nilai saat belum ada siswa
  ///
  /// In id, this message translates to:
  /// **'Belum ada mahasiswa di kelas ini.'**
  String get classGradebookNoStudents;

  /// Opsi dropdown rekap nilai semua pertemuan
  ///
  /// In id, this message translates to:
  /// **'Semua Pertemuan (Ringkasan)'**
  String get classGradebookAllMeetingsHint;

  /// Format judul pertemuan dengan nomor dan nama
  ///
  /// In id, this message translates to:
  /// **'Pertemuan {number}: {title}'**
  String classMeetingNumberTitle(int number, String title);

  /// Judul KPI rata-rata pretest
  ///
  /// In id, this message translates to:
  /// **'Rata-rata Pretest'**
  String get classKpiPretestAvg;

  /// Subjudul KPI jumlah pengumpulan nilai
  ///
  /// In id, this message translates to:
  /// **'{submitted} dari {total} mahasiswa'**
  String classKpiSubCount(int submitted, int total);

  /// Judul KPI rata-rata post test
  ///
  /// In id, this message translates to:
  /// **'Rata-rata Post Test'**
  String get classKpiPosttestAvg;

  /// Judul KPI total pertemuan
  ///
  /// In id, this message translates to:
  /// **'Total Pertemuan'**
  String get classKpiTotalMeetings;

  /// Subjudul KPI jumlah pertemuan bermodul kuis
  ///
  /// In id, this message translates to:
  /// **'{count} ber-modul kuis'**
  String classKpiQuizModulesCount(int count);

  /// Judul KPI total mahasiswa
  ///
  /// In id, this message translates to:
  /// **'Total Mahasiswa'**
  String get classKpiTotalStudents;

  /// Subjudul KPI mahasiswa terdaftar
  ///
  /// In id, this message translates to:
  /// **'Terdaftar di kelas ini'**
  String get classKpiEnrolledDesc;

  /// Teks informasi paginasi rekap nilai
  ///
  /// In id, this message translates to:
  /// **'Menampilkan {start}-{end} dari {total} mahasiswa'**
  String classPaginationInfo(int start, int end, int total);

  /// Status progres kuis ringkasan siswa
  ///
  /// In id, this message translates to:
  /// **'Progres Kuis: {done} dari {total} diselesaikan'**
  String classQuizProgress(int done, int total);

  /// Keterangan saat siswa belum mengerjakan kuis
  ///
  /// In id, this message translates to:
  /// **'Belum ada kuis yang dikerjakan pada pertemuan mana pun.'**
  String get classQuizNoneDone;

  /// Label saat nilai kuis belum ada
  ///
  /// In id, this message translates to:
  /// **'Belum Ada'**
  String get classScoreNotAvailable;

  /// Teks status kosong capaian belajar siswa
  ///
  /// In id, this message translates to:
  /// **'Belum ada pertemuan di kelas ini.'**
  String get classNoMeetings;

  /// Judul banner hasil capaian belajar siswa
  ///
  /// In id, this message translates to:
  /// **'Hasil Capaian Belajar Anda'**
  String get classStudentProgressTitle;

  /// Deskripsi banner hasil capaian belajar siswa
  ///
  /// In id, this message translates to:
  /// **'Menampilkan nilai resmi pretest & post test Anda pada kelas {className}.'**
  String classStudentProgressBody(String className);

  /// Teks status kosong tab anggota kelas
  ///
  /// In id, this message translates to:
  /// **'Belum ada anggota terdaftar di kelas ini.'**
  String get classNoMembers;

  /// Subjudul kartu anggota kelas dengan tipe dan status mentah
  ///
  /// In id, this message translates to:
  /// **'Tipe: {type} • Status: {status}'**
  String classMemberTypeStatus(String type, String status);

  /// Judul dialog hasil berhasil bergabung kelas
  ///
  /// In id, this message translates to:
  /// **'Berhasil Bergabung'**
  String get joinClassSuccessTitle;

  /// Judul dialog hasil menunggu persetujuan bergabung kelas
  ///
  /// In id, this message translates to:
  /// **'Menunggu Persetujuan'**
  String get joinClassPendingTitle;

  /// Badge status keanggotaan pada dialog hasil gabung kelas
  ///
  /// In id, this message translates to:
  /// **'Status: {status}'**
  String joinClassStatusPrefix(String status);

  /// Tombol buka kelas pada dialog sukses gabung kelas aktif
  ///
  /// In id, this message translates to:
  /// **'Buka Kelas'**
  String get joinClassOpenBtn;

  /// Tombol kembali ke beranda pada dialog status pending
  ///
  /// In id, this message translates to:
  /// **'Kembali ke Beranda'**
  String get joinClassBackHomeBtn;

  /// Snackbar gagal sinkronisasi data kelas setelah gabung
  ///
  /// In id, this message translates to:
  /// **'Gagal sinkronisasi data kelas: {detail}'**
  String joinClassSyncFailed(String detail);

  /// Judul AppBar layar gabung kelas
  ///
  /// In id, this message translates to:
  /// **'Gabung Kelas'**
  String get joinClassAppBarTitle;

  /// Judul besar form gabung kelas
  ///
  /// In id, this message translates to:
  /// **'Masukkan Kode Kelas'**
  String get joinClassHeading;

  /// Instruksi format dan aturan kode kelas
  ///
  /// In id, this message translates to:
  /// **'Kode kelas terdiri dari 6-12 karakter alfanumerik. Mahasiswa/Dosen otomatis aktif, sedangkan akun Umum berstatus pending.'**
  String get joinClassDescription;

  /// Label field input kode kelas
  ///
  /// In id, this message translates to:
  /// **'Kode Kelas (misal: FARLEAN1)'**
  String get joinClassCodeLabel;

  /// Tombol submit formulir gabung kelas
  ///
  /// In id, this message translates to:
  /// **'Gabung Sekarang'**
  String get joinClassSubmitBtn;

  /// Pesan error permission-denied diskusi untuk pengajar
  ///
  /// In id, this message translates to:
  /// **'Akses ditolak: Anda tidak memiliki wewenang untuk mengelola forum kelas ini.'**
  String get discussionErrorPermissionStaff;

  /// Pesan error permission-denied diskusi untuk siswa
  ///
  /// In id, this message translates to:
  /// **'Akses ditolak: Anda belum terdaftar sebagai anggota aktif di kelas ini.'**
  String get discussionErrorPermissionStudent;

  /// Pesan error gagal memuat diskusi
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat forum diskusi: {detail}'**
  String discussionErrorLoadFailed(String detail);

  /// Snackbar peringatan belum memilih kelas saat buat diskusi
  ///
  /// In id, this message translates to:
  /// **'Pilih kelas terlebih dahulu untuk membuat diskusi.'**
  String get discussionSelectClassFirst;

  /// Judul dialog buat diskusi baru
  ///
  /// In id, this message translates to:
  /// **'Buat Diskusi Baru'**
  String get discussionCreateTitle;

  /// Label field judul diskusi
  ///
  /// In id, this message translates to:
  /// **'Judul Diskusi *'**
  String get discussionTitleLabel;

  /// Hint field judul diskusi
  ///
  /// In id, this message translates to:
  /// **'Misal: Tanya materi Bab 2...'**
  String get discussionTitleHint;

  /// Validasi judul diskusi terlalu pendek
  ///
  /// In id, this message translates to:
  /// **'Judul minimal 3 karakter'**
  String get discussionTitleMinLength;

  /// Validasi judul diskusi melebihi batas
  ///
  /// In id, this message translates to:
  /// **'Judul maksimal 200 karakter'**
  String get discussionTitleMaxLength;

  /// Label field isi diskusi
  ///
  /// In id, this message translates to:
  /// **'Isi Pertanyaan / Topik Diskusi *'**
  String get discussionBodyLabel;

  /// Hint field isi diskusi
  ///
  /// In id, this message translates to:
  /// **'Tuliskan pertanyaan atau topik dengan jelas...'**
  String get discussionBodyHint;

  /// Validasi isi diskusi terlalu pendek
  ///
  /// In id, this message translates to:
  /// **'Isi diskusi minimal 3 karakter'**
  String get discussionBodyMinLength;

  /// Validasi isi diskusi melebihi batas
  ///
  /// In id, this message translates to:
  /// **'Isi diskusi maksimal 5000 karakter'**
  String get discussionBodyMaxLength;

  /// Tombol kirim topik diskusi baru
  ///
  /// In id, this message translates to:
  /// **'Kirim Diskusi'**
  String get discussionSendBtn;

  /// Judul AppBar forum diskusi
  ///
  /// In id, this message translates to:
  /// **'Forum Diskusi'**
  String get discussionForumTitle;

  /// Label tombol FAB buat diskusi
  ///
  /// In id, this message translates to:
  /// **'Buat Diskusi'**
  String get discussionCreateFab;

  /// Judul status belum memilih kelas pada forum diskusi
  ///
  /// In id, this message translates to:
  /// **'Pilih Kelas untuk Berdiskusi'**
  String get discussionNoClassTitle;

  /// Deskripsi status belum memilih kelas pada forum diskusi
  ///
  /// In id, this message translates to:
  /// **'Anda belum memilih kelas. Silakan bergabung ke kelas atau pilih kelas dari Beranda.'**
  String get discussionNoClassBody;

  /// Teks indikator loading forum diskusi
  ///
  /// In id, this message translates to:
  /// **'Memuat diskusi kelas...'**
  String get discussionLoading;

  /// Filter chip semua diskusi
  ///
  /// In id, this message translates to:
  /// **'Semua Diskusi'**
  String get discussionFilterAll;

  /// Filter chip diskusi belum dibalas
  ///
  /// In id, this message translates to:
  /// **'Belum Dibalas'**
  String get discussionFilterUnanswered;

  /// Filter chip diskusi belum dibaca
  ///
  /// In id, this message translates to:
  /// **'Belum Dibaca'**
  String get discussionFilterUnread;

  /// Judul status kosong semua diskusi
  ///
  /// In id, this message translates to:
  /// **'Belum Ada Diskusi'**
  String get discussionEmptyAllTitle;

  /// Deskripsi status kosong semua diskusi
  ///
  /// In id, this message translates to:
  /// **'Jadilah yang pertama memulai tanya jawab dan ruang kolaborasi di kelas ini.'**
  String get discussionEmptyAllDesc;

  /// Judul status kosong filter belum dibalas
  ///
  /// In id, this message translates to:
  /// **'Tidak Ada Diskusi Belum Dibalas'**
  String get discussionEmptyUnansweredTitle;

  /// Deskripsi status kosong filter belum dibalas
  ///
  /// In id, this message translates to:
  /// **'Semua topik diskusi telah memiliki balasan dari pengajar atau sesama anggota.'**
  String get discussionEmptyUnansweredDesc;

  /// Judul status kosong filter belum dibaca
  ///
  /// In id, this message translates to:
  /// **'Semua Diskusi Sudah Dibaca'**
  String get discussionEmptyUnreadTitle;

  /// Deskripsi status kosong filter belum dibaca
  ///
  /// In id, this message translates to:
  /// **'Tidak ada aktivitas atau balasan baru yang belum Anda baca pada halaman ini.'**
  String get discussionEmptyUnreadDesc;

  /// Badge jumlah balasan pada kartu diskusi
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} Balasan}}'**
  String discussionReplyCount(int count);

  /// Pesan error diskusi tidak ditemukan
  ///
  /// In id, this message translates to:
  /// **'Diskusi tidak ditemukan atau telah dihapus.'**
  String get discussionNotFound;

  /// Pesan error gagal memuat detail thread diskusi
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat detail diskusi: {detail}'**
  String discussionLoadDetailFailed(String detail);

  /// Snackbar penolakan kirim balasan pada thread arsip
  ///
  /// In id, this message translates to:
  /// **'Diskusi ini telah diarsipkan. Pengiriman balasan dinonaktifkan.'**
  String get discussionArchivedSendBlocked;

  /// Snackbar gagal mengirim balasan diskusi
  ///
  /// In id, this message translates to:
  /// **'Gagal mengirim balasan: {detail}'**
  String discussionSendReplyFailed(String detail);

  /// Judul dialog konfirmasi arsipkan thread diskusi
  ///
  /// In id, this message translates to:
  /// **'Arsipkan Diskusi?'**
  String get discussionArchiveConfirmTitle;

  /// Isi dialog konfirmasi arsipkan thread diskusi
  ///
  /// In id, this message translates to:
  /// **'Diskusi yang diarsipkan akan dikunci dari pengiriman balasan baru dan disembunyikan dari daftar anggota kelas.'**
  String get discussionArchiveConfirmBody;

  /// Snackbar sukses arsipkan thread diskusi
  ///
  /// In id, this message translates to:
  /// **'Diskusi berhasil diarsipkan.'**
  String get discussionArchiveSuccess;

  /// Snackbar gagal arsipkan diskusi
  ///
  /// In id, this message translates to:
  /// **'Gagal mengarsipkan: {detail}'**
  String discussionArchiveFailed(String detail);

  /// Judul dialog edit thread diskusi
  ///
  /// In id, this message translates to:
  /// **'Edit Diskusi'**
  String get discussionEditTitle;

  /// Label field edit judul diskusi
  ///
  /// In id, this message translates to:
  /// **'Judul Diskusi'**
  String get discussionEditTitleLabel;

  /// Label field edit isi diskusi
  ///
  /// In id, this message translates to:
  /// **'Isi Diskusi'**
  String get discussionEditBodyLabel;

  /// Snackbar gagal update diskusi
  ///
  /// In id, this message translates to:
  /// **'Gagal update: {detail}'**
  String discussionUpdateFailed(String detail);

  /// Tooltip ikon arsipkan butir balasan
  ///
  /// In id, this message translates to:
  /// **'Arsipkan Balasan'**
  String get discussionArchiveReplyTooltip;

  /// Tombol aksi balas pada butir balasan
  ///
  /// In id, this message translates to:
  /// **'Balas'**
  String get discussionReplyAction;

  /// Teks loading thread diskusi
  ///
  /// In id, this message translates to:
  /// **'Memuat thread diskusi...'**
  String get discussionThreadLoading;

  /// Judul AppBar layar detail diskusi
  ///
  /// In id, this message translates to:
  /// **'Detail Diskusi'**
  String get discussionDetailTitle;

  /// Tooltip ikon edit diskusi
  ///
  /// In id, this message translates to:
  /// **'Edit Diskusi'**
  String get discussionEditTooltip;

  /// Tooltip ikon arsipkan diskusi
  ///
  /// In id, this message translates to:
  /// **'Arsipkan Diskusi'**
  String get discussionArchiveTooltip;

  /// Tag status diskusi diarsipkan pada kartu thread
  ///
  /// In id, this message translates to:
  /// **'Status: Diarsipkan'**
  String get discussionStatusArchivedTag;

  /// Tag status thread diskusi aktif pada kartu thread
  ///
  /// In id, this message translates to:
  /// **'Thread Diskusi Aktif'**
  String get discussionStatusActiveTag;

  /// Header seksi daftar balasan
  ///
  /// In id, this message translates to:
  /// **'Balasan ({count})'**
  String discussionDetailReplyCount(int count);

  /// Teks status kosong belum ada balasan pada thread
  ///
  /// In id, this message translates to:
  /// **'Belum ada tanggapan pada diskusi ini.'**
  String get discussionNoRepliesYet;

  /// Banner konteks membalas komentar tertentu
  ///
  /// In id, this message translates to:
  /// **'Membalas @{author}: \"{snippet}\"'**
  String discussionReplyingTo(String author, String snippet);

  /// Banner kotak input balasan saat thread diarsipkan
  ///
  /// In id, this message translates to:
  /// **'Diskusi diarsipkan. Pengiriman balasan dinonaktifkan.'**
  String get discussionArchivedBanner;

  /// Hint input saat membalas komentar spesifik
  ///
  /// In id, this message translates to:
  /// **'Tulis balasan untuk @{author}...'**
  String discussionReplyToHint(String author);

  /// Hint input umum balasan diskusi
  ///
  /// In id, this message translates to:
  /// **'Tulis tanggapan atau balasan...'**
  String get discussionReplyGeneralHint;

  /// Judul dialog buat kelas baru
  ///
  /// In id, this message translates to:
  /// **'Buat Kelas Baru'**
  String get dashboardCreateClassTitle;

  /// Label input nama kelas
  ///
  /// In id, this message translates to:
  /// **'Nama Kelas'**
  String get dashboardClassNameLabel;

  /// Hint input nama kelas
  ///
  /// In id, this message translates to:
  /// **'Contoh: Pemrograman Mobile'**
  String get dashboardClassNameHint;

  /// Validasi nama kelas minimal 3 karakter
  ///
  /// In id, this message translates to:
  /// **'Nama kelas minimal 3 karakter'**
  String get dashboardClassNameMinLength;

  /// Validasi nama kelas maksimal 100 karakter
  ///
  /// In id, this message translates to:
  /// **'Nama kelas maksimal 100 karakter'**
  String get dashboardClassNameMaxLength;

  /// Label input deskripsi kelas
  ///
  /// In id, this message translates to:
  /// **'Deskripsi (Opsional)'**
  String get dashboardClassDescLabel;

  /// Hint input deskripsi kelas
  ///
  /// In id, this message translates to:
  /// **'Deskripsi singkat silabus kelas'**
  String get dashboardClassDescHint;

  /// Label input kode kelas kustom
  ///
  /// In id, this message translates to:
  /// **'Kode Kelas Khusus (Opsional)'**
  String get dashboardClassCodeLabel;

  /// Hint input kode kelas kustom
  ///
  /// In id, this message translates to:
  /// **'Kosongkan untuk kode acak 8 karakter'**
  String get dashboardClassCodeHint;

  /// Validasi panjang kode kelas
  ///
  /// In id, this message translates to:
  /// **'Kode harus 6-12 karakter'**
  String get dashboardClassCodeLength;

  /// Validasi format karakter kode kelas
  ///
  /// In id, this message translates to:
  /// **'Kode hanya huruf kapital dan angka'**
  String get dashboardClassCodeAlphanumeric;

  /// Tombol buat kelas pada dialog
  ///
  /// In id, this message translates to:
  /// **'Buat Kelas'**
  String get dashboardCreateClassBtn;

  /// Snackbar sukses buat kelas
  ///
  /// In id, this message translates to:
  /// **'Kelas berhasil dibuat.'**
  String get dashboardClassCreatedSuccess;

  /// Indikator loading profil pengguna
  ///
  /// In id, this message translates to:
  /// **'Memuat profil dan hak akses...'**
  String get dashboardLoadingProfile;

  /// Judul error sinkronisasi profil
  ///
  /// In id, this message translates to:
  /// **'Profil Belum Berhasil Dimuat'**
  String get dashboardProfileErrorTitle;

  /// Pesan error jaringan pada profil
  ///
  /// In id, this message translates to:
  /// **'Koneksi ke database gagal. Periksa jaringan internet atau emulator Anda.'**
  String get dashboardProfileErrorNetwork;

  /// Pesan error profil tidak ditemukan
  ///
  /// In id, this message translates to:
  /// **'Profil pengguna belum berhasil dimuat. Silakan tekan tombol Coba Lagi.'**
  String get dashboardProfileErrorNotFound;

  /// Pesan error permission-denied pada profil
  ///
  /// In id, this message translates to:
  /// **'Akses ditolak saat membaca profil.'**
  String get dashboardProfileErrorPermission;

  /// Pesan error profil default/fallback
  ///
  /// In id, this message translates to:
  /// **'Terjadi kendala saat menyinkronkan profil Anda dari server. Silakan coba lagi.'**
  String get dashboardProfileErrorDefault;

  /// Indikator loading daftar kelas
  ///
  /// In id, this message translates to:
  /// **'Memuat kelas Anda...'**
  String get dashboardLoadingClasses;

  /// Badge selamat datang dashboard
  ///
  /// In id, this message translates to:
  /// **'Farlean LMS • Multi-Class Active'**
  String get dashboardWelcomeBadge;

  /// Judul kartu selamat datang dashboard
  ///
  /// In id, this message translates to:
  /// **'Selamat Datang di Farlean LMS'**
  String get dashboardWelcomeTitle;

  /// Isi kartu selamat datang dashboard
  ///
  /// In id, this message translates to:
  /// **'Akses materi terstruktur, kuis pretest berpenilaian server, video pembelajaran, dan forum belajar dalam satu platform.'**
  String get dashboardWelcomeBody;

  /// Judul peringatan peran akun belum sinkron
  ///
  /// In id, this message translates to:
  /// **'Peran Akun Belum Sinkron'**
  String get dashboardRoleOutOfSyncTitle;

  /// Deskripsi peran belum sinkron dengan nilai role token dan profil
  ///
  /// In id, this message translates to:
  /// **'Token: {claimsRole} vs Profil: {profileRole}. Tekan Perbarui untuk menyelaraskan hak akses.'**
  String dashboardRoleOutOfSyncBody(String claimsRole, String profileRole);

  /// Tombol perbarui peran akun
  ///
  /// In id, this message translates to:
  /// **'Perbarui'**
  String get dashboardRefreshRoleBtn;

  /// Judul bagian kelas yang dikelola staf
  ///
  /// In id, this message translates to:
  /// **'Kelas yang Anda Kelola'**
  String get dashboardManagedClassesSection;

  /// Judul kosong kelas yang dikelola
  ///
  /// In id, this message translates to:
  /// **'Belum ada kelas yang Anda kelola.'**
  String get dashboardEmptyOwnedTitle;

  /// Deskripsi kosong kelas yang dikelola
  ///
  /// In id, this message translates to:
  /// **'Buat kelas baru untuk mulai mengunggah materi dan membuat pertemuan.'**
  String get dashboardEmptyOwnedBody;

  /// Tombol buat kelas pertama kali
  ///
  /// In id, this message translates to:
  /// **'Buat Kelas Pertama'**
  String get dashboardCreateFirstClassBtn;

  /// Judul bagian kelas yang diikuti
  ///
  /// In id, this message translates to:
  /// **'Kelas yang Anda Ikuti'**
  String get dashboardJoinedClassesSection;

  /// Tombol gabung kode kelas di header bagian
  ///
  /// In id, this message translates to:
  /// **'Gabung Kode'**
  String get dashboardJoinCodeBtn;

  /// Judul kosong kelas yang diikuti
  ///
  /// In id, this message translates to:
  /// **'Belum tergabung ke kelas pembelajaran.'**
  String get dashboardEmptyJoinedTitle;

  /// Deskripsi kosong kelas yang diikuti
  ///
  /// In id, this message translates to:
  /// **'Minta kode kelas dari Dosen/Pengajar Anda untuk bergabung ke kelas.'**
  String get dashboardEmptyJoinedBody;

  /// Snackbar kode kelas berhasil disalin
  ///
  /// In id, this message translates to:
  /// **'Kode {code} disalin.'**
  String dashboardCodeCopied(String code);

  /// Jumlah pertemuan pada kartu kelas di dashboard
  ///
  /// In id, this message translates to:
  /// **'{count, plural, other{{count} Pertemuan}}'**
  String dashboardMeetingCount(int count);

  /// Tombol kelola kelas bagi pemilik
  ///
  /// In id, this message translates to:
  /// **'Kelola Kelas'**
  String get dashboardManageClassBtn;

  /// Tombol buka kelas bagi peserta
  ///
  /// In id, this message translates to:
  /// **'Buka Kelas'**
  String get dashboardOpenClassBtn;

  /// Snackbar navigasi cerdas saat belum ada kelas dipilih
  ///
  /// In id, this message translates to:
  /// **'Pilih salah satu kelas terlebih dahulu untuk melihat pertemuan & materi.'**
  String get navSelectClassFirst;

  /// Label tab navigasi materi
  ///
  /// In id, this message translates to:
  /// **'Materi'**
  String get navMaterials;

  /// Label tab navigasi AI Tutor
  ///
  /// In id, this message translates to:
  /// **'AI Tutor'**
  String get navAiTutor;

  /// Label tab navigasi diskusi
  ///
  /// In id, this message translates to:
  /// **'Diskusi'**
  String get navDiscussion;

  /// Pesan error permission-denied manual book untuk staf
  ///
  /// In id, this message translates to:
  /// **'Akses ditolak: Anda tidak memiliki wewenang untuk melihat berkas panduan kelas ini.'**
  String get manualBookErrorPermissionStaff;

  /// Pesan error permission-denied manual book untuk siswa
  ///
  /// In id, this message translates to:
  /// **'Akses ditolak: Anda belum terdaftar sebagai anggota aktif di kelas ini.'**
  String get manualBookErrorPermissionStudent;

  /// Pesan error gagal memuat buku panduan
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat manual book: {detail}'**
  String manualBookErrorLoadFailed(String detail);

  /// Snackbar gagal membuka link PDF
  ///
  /// In id, this message translates to:
  /// **'Tidak dapat membuka tautan PDF.'**
  String get manualBookOpenPdfFailed;

  /// Snackbar error membuka berkas PDF
  ///
  /// In id, this message translates to:
  /// **'Error membuka berkas: {detail}'**
  String manualBookOpenPdfError(String detail);

  /// Peringatan pilih kelas sebelum unggah buku panduan
  ///
  /// In id, this message translates to:
  /// **'Pilih kelas yang valid terlebih dahulu untuk mengunggah buku panduan.'**
  String get manualBookSelectClassFirst;

  /// Judul dialog tambah buku panduan
  ///
  /// In id, this message translates to:
  /// **'Tambah Manual Book'**
  String get manualBookAddTitle;

  /// Label field judul panduan
  ///
  /// In id, this message translates to:
  /// **'Judul Panduan'**
  String get manualBookTitleLabel;

  /// Validasi judul panduan kosong
  ///
  /// In id, this message translates to:
  /// **'Judul wajib diisi'**
  String get manualBookTitleRequired;

  /// Label field deskripsi panduan
  ///
  /// In id, this message translates to:
  /// **'Deskripsi Singkat'**
  String get manualBookDescLabel;

  /// Label field URL berkas PDF
  ///
  /// In id, this message translates to:
  /// **'URL Berkas Cloudinary (PDF)'**
  String get manualBookUrlLabel;

  /// Validasi URL berkas kosong
  ///
  /// In id, this message translates to:
  /// **'URL berkas wajib diisi'**
  String get manualBookUrlRequired;

  /// Validasi URL berkas harus protokol https
  ///
  /// In id, this message translates to:
  /// **'URL harus diawali https://'**
  String get manualBookUrlInvalid;

  /// Label field nama berkas pdf
  ///
  /// In id, this message translates to:
  /// **'Nama Berkas (.pdf)'**
  String get manualBookFileNameLabel;

  /// Judul AppBar layar manual book
  ///
  /// In id, this message translates to:
  /// **'Buku Panduan (Manual Book)'**
  String get manualBookAppBarTitle;

  /// Instruksi saat belum memilih kelas di manual book
  ///
  /// In id, this message translates to:
  /// **'Anda belum memilih kelas. Silakan bergabung menggunakan kode kelas atau pilih kelas dari Beranda untuk mengakses Buku Panduan.'**
  String get manualBookNoClassBody;

  /// Tombol gabung kelas baru pada manual book
  ///
  /// In id, this message translates to:
  /// **'Gabung Kelas Baru'**
  String get manualBookJoinNewClassBtn;

  /// Indikator loading buku panduan
  ///
  /// In id, this message translates to:
  /// **'Memuat buku panduan...'**
  String get manualBookLoading;

  /// Judul kosong buku panduan
  ///
  /// In id, this message translates to:
  /// **'Belum Ada Buku Panduan'**
  String get manualBookEmptyTitle;

  /// Deskripsi kosong buku panduan
  ///
  /// In id, this message translates to:
  /// **'Pengajar belum menambahkan buku panduan (Manual Book) PDF untuk kelas ini.'**
  String get manualBookEmptyBody;

  /// Fallback saat deskripsi manual book kosong
  ///
  /// In id, this message translates to:
  /// **'Tidak ada deskripsi'**
  String get manualBookNoDescription;

  /// Tombol membuka dokumen PDF manual book
  ///
  /// In id, this message translates to:
  /// **'Buka Dokumen PDF'**
  String get manualBookOpenPdfBtn;

  /// Judul menu pemilihan tema tampilan
  ///
  /// In id, this message translates to:
  /// **'Tema Tampilan'**
  String get profileThemeTitle;

  /// Subjudul menu pemilihan tema tampilan
  ///
  /// In id, this message translates to:
  /// **'Atur tema terang, gelap, atau ikuti sistem'**
  String get profileThemeSubtitle;

  /// Opsi tema terang
  ///
  /// In id, this message translates to:
  /// **'Terang'**
  String get themeModeLight;

  /// Opsi tema gelap
  ///
  /// In id, this message translates to:
  /// **'Gelap'**
  String get themeModeDark;

  /// Opsi tema mengikuti sistem operasi
  ///
  /// In id, this message translates to:
  /// **'Ikuti Sistem'**
  String get themeModeSystem;

  /// Judul menu pemilihan bahasa aplikasi
  ///
  /// In id, this message translates to:
  /// **'Bahasa Aplikasi'**
  String get profileLanguageTitle;

  /// Subjudul menu pemilihan bahasa
  ///
  /// In id, this message translates to:
  /// **'Pilih bahasa antarmuka aplikasi'**
  String get profileLanguageSubtitle;

  /// Nama bahasa Indonesia
  ///
  /// In id, this message translates to:
  /// **'Bahasa Indonesia'**
  String get languageId;

  /// Nama bahasa Inggris
  ///
  /// In id, this message translates to:
  /// **'English'**
  String get languageEn;

  /// Indikator nomor soal aktif
  ///
  /// In id, this message translates to:
  /// **'Soal {current} dari {total}'**
  String quizQuestionOf(int current, int total);

  /// Bobot poin soal kuis
  ///
  /// In id, this message translates to:
  /// **'{points} Poin'**
  String quizPoints(int points);

  /// Tombol navigasi soal sebelumnya
  ///
  /// In id, this message translates to:
  /// **'Sebelumnya'**
  String get quizBtnPrev;

  /// Tombol navigasi soal selanjutnya
  ///
  /// In id, this message translates to:
  /// **'Selanjutnya'**
  String get quizBtnNext;

  /// Tombol kumpulkan jawaban kuis
  ///
  /// In id, this message translates to:
  /// **'Kumpulkan'**
  String get quizBtnSubmit;

  /// Judul layar gate akses pretest terkunci
  ///
  /// In id, this message translates to:
  /// **'Akses Pretest Terkunci'**
  String get quizGateLockedTitle;

  /// Instruksi edukatif gerbang pretest saat materi belum dibuka
  ///
  /// In id, this message translates to:
  /// **'Sesuai ketentuan alur pembelajaran Farlean LMS, Anda harus membuka dan membaca materi pembelajaran pertemuan ini terlebih dahulu sebelum diperkenankan mengerjakan pretest.\n\nJika sebelumnya Anda sudah pernah membuka materi, ketuk tombol di bawah untuk membuka kembali materi agar progres kehadiran tersinkronisasi secara resmi ke server.'**
  String get quizGateLockedDesc;

  /// Tombol membuka materi pembelajaran
  ///
  /// In id, this message translates to:
  /// **'Buka Materi Pembelajaran'**
  String get quizGateOpenMaterialBtn;

  /// Tombol kembali ke layar pertemuan
  ///
  /// In id, this message translates to:
  /// **'Kembali ke Pertemuan'**
  String get quizGateBackToMeetingBtn;

  /// Judul dialog konfirmasi pengumpulan kuis
  ///
  /// In id, this message translates to:
  /// **'Kumpulkan Jawaban?'**
  String get quizConfirmSubmitTitle;

  /// Isi dialog konfirmasi pengumpulan kuis
  ///
  /// In id, this message translates to:
  /// **'Apakah Anda yakin ingin mengumpulkan kuis ini? Pastikan seluruh soal telah Anda jawab dengan seksama.'**
  String get quizConfirmSubmitBody;

  /// Teks indikator saat kuis sedang dikirim ke server
  ///
  /// In id, this message translates to:
  /// **'Mengumpulkan...'**
  String get quizSubmitting;

  /// Judul dialog sukses penilaian kuis
  ///
  /// In id, this message translates to:
  /// **'Kuis Selesai Dinilai'**
  String get quizSubmitSuccessTitle;

  /// Isi pesan sukses penilaian kuis resmi
  ///
  /// In id, this message translates to:
  /// **'Nilai resmi Anda: {score} ({earned}/{total} poin).\nNilai terbaik Anda telah diperbarui di server.'**
  String quizSubmitSuccessBody(String score, int earned, int total);

  /// Judul dialog error koneksi kuis
  ///
  /// In id, this message translates to:
  /// **'Koneksi Terputus'**
  String get quizConnErrorTitle;

  /// Isi dialog error koneksi kuis
  ///
  /// In id, this message translates to:
  /// **'Koneksi jaringan terputus. Status penilaian kuis saat ini tidak dapat dipastikan dari server. Harap periksa koneksi internet Anda dan coba kembali.'**
  String get quizConnErrorBody;

  /// Judul dialog batas waktu kuis kedaluwarsa
  ///
  /// In id, this message translates to:
  /// **'Batas Waktu Berakhir'**
  String get quizDeadlineExpiredTitle;

  /// Isi dialog batas waktu pengerjaan kuis kedaluwarsa
  ///
  /// In id, this message translates to:
  /// **'Batas waktu pengerjaan (deadline) kuis telah berakhir. Sesi pengerjaan kuis telah dikunci oleh server.'**
  String get quizDeadlineExpiredBody;

  /// Tombol aksi mengerti pada dialog
  ///
  /// In id, this message translates to:
  /// **'Mengerti'**
  String get quizUnderstand;

  /// Pesan penolakan saat kuis berstatus draft
  ///
  /// In id, this message translates to:
  /// **'Kuis ini masih berstatus Draft dan belum dibuka oleh pengajar.'**
  String get quizDraftBlockedMessage;

  /// Label penyedia video pembelajaran
  ///
  /// In id, this message translates to:
  /// **'Penyedia: {provider}'**
  String videoProviderLabel(String provider);

  /// Label durasi pemutaran video
  ///
  /// In id, this message translates to:
  /// **'Durasi: {minutes}m {seconds}s'**
  String videoDurationLabel(int minutes, int seconds);

  /// Judul bagian video materi terintegrasi
  ///
  /// In id, this message translates to:
  /// **'Video Materi Terintegrasi'**
  String get videoIntegratedTitle;

  /// Label tautan sumber video
  ///
  /// In id, this message translates to:
  /// **'URL Sumber: {url}'**
  String videoSourceUrlLabel(String url);

  /// Catatan edukatif penyimpanan video pembelajaran
  ///
  /// In id, this message translates to:
  /// **'Video ini di-stream langsung tanpa disimpan di Firebase Storage untuk efisiensi penyimpanan sesuai arsitektur Blueprint.'**
  String get videoStorageNote;

  /// Pesan error gagal memuat data video
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat video: {error}'**
  String videoLoadFailed(String error);

  /// Banner pemberitahuan pertemuan terkunci jadwal terbit
  ///
  /// In id, this message translates to:
  /// **'Pertemuan ini dijadwalkan terbit pada {date}. Seluruh modul terkunci hingga waktu tersebut.'**
  String meetingLockedUntilPublish(String date);

  /// Judul gate layar pretest jika materi belum dibuka
  ///
  /// In id, this message translates to:
  /// **'Materi Belum Dibuka'**
  String get quizGateMateriNotOpened;

  /// Snackbar timeout autosave kuis pretest
  ///
  /// In id, this message translates to:
  /// **'Waktu pengerjaan telah habis. Jawaban Anda disimpan otomatis.'**
  String get quizTimeUpAutosaved;

  /// Snackbar timeout auto-submit kuis post test
  ///
  /// In id, this message translates to:
  /// **'Waktu pengerjaan telah habis. Jawaban dikumpulkan otomatis.'**
  String get quizTimeUpAutosubmitted;

  /// Snackbar error gagal submit kuis
  ///
  /// In id, this message translates to:
  /// **'Gagal mengumpulkan kuis: {error}'**
  String quizSubmitFailed(String error);

  /// Judul dialog penilaian kuis tertunda akibat kendala jaringan
  ///
  /// In id, this message translates to:
  /// **'Penilaian Tertunda'**
  String get quizPendingEvaluationTitle;

  /// Pesan edukatif dialog penilaian kuis tertunda
  ///
  /// In id, this message translates to:
  /// **'Koneksi ke server penilaian terputus, namun sesi kuis Anda masih aktif di server. Jawaban lokal Anda telah tersimpan otomatis. Silakan tekan tombol Kirim Kuis untuk mencoba kembali.'**
  String get quizPendingEvaluationBody;

  /// Konfirmasi submit kuis dengan jumlah soal belum dijawab
  ///
  /// In id, this message translates to:
  /// **'Terdapat {unanswered} soal yang belum Anda jawab. Jawaban yang sudah dikumpulkan tidak dapat diubah lagi.'**
  String quizConfirmUnansweredBody(int unanswered);

  /// Indikator loading persiapan kuis pretest
  ///
  /// In id, this message translates to:
  /// **'Mempersiapkan kuis pretest...'**
  String get quizPretestLoading;

  /// Pesan error fallback saat pretest gagal dimuat
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat pretest.'**
  String get quizPretestLoadFailed;

  /// Indikator loading persiapan kuis post test
  ///
  /// In id, this message translates to:
  /// **'Mempersiapkan sesi post test...'**
  String get quizPosttestLoading;

  /// Pesan error fallback saat post test tidak tersedia
  ///
  /// In id, this message translates to:
  /// **'Kuis post test tidak tersedia.'**
  String get quizPosttestUnavailable;

  /// Pesan error saat belum ada soal pada post test
  ///
  /// In id, this message translates to:
  /// **'Belum ada soal yang dikonfigurasi untuk post test ini.'**
  String get quizNoQuestionsConfigured;

  /// Pesan error gagal memuat sesi kuis post test
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat kuis post test: {error}'**
  String quizPosttestLoadFailed(String error);

  /// Label skor akhir pada dialog hasil kuis
  ///
  /// In id, this message translates to:
  /// **'Skor Akhir: {score}'**
  String quizFinalScore(String score);

  /// Rincian perolehan poin pada dialog hasil kuis
  ///
  /// In id, this message translates to:
  /// **'Poin diperoleh: {earned} dari {total} poin'**
  String quizPointsEarned(String earned, String total);

  /// Keterangan penutupan sesi pada dialog hasil pretest
  ///
  /// In id, this message translates to:
  /// **'Jawaban Anda telah tersimpan dengan aman dan sesi kuis telah dikunci.'**
  String get quizPretestAnswersLocked;

  /// Keterangan penutupan sesi pada dialog hasil post test
  ///
  /// In id, this message translates to:
  /// **'Jawaban Anda telah dikunci dan skor evaluasi pembelajaran telah tercatat di server.'**
  String get quizPosttestAnswersLocked;

  /// Pesan error saat pengguna belum memiliki sesi login aktif
  ///
  /// In id, this message translates to:
  /// **'Sesi Anda belum aktif.'**
  String get quizSessionNotActive;

  /// Pesan error saat pretest tidak ditemukan
  ///
  /// In id, this message translates to:
  /// **'Kuis pretest tidak ditemukan.'**
  String get quizNotFound;

  /// Pesan error saat post test tidak ditemukan
  ///
  /// In id, this message translates to:
  /// **'Kuis post test tidak ditemukan.'**
  String get quizPosttestNotFound;

  /// Pesan error kuis masih dalam status non-published
  ///
  /// In id, this message translates to:
  /// **'Kuis pretest masih berstatus {status} dan belum dibuka.'**
  String quizDraftBlocked(String status);

  /// Pesan error kuis tidak terhubung dengan kelas/pertemuan
  ///
  /// In id, this message translates to:
  /// **'Kuis tidak terhubung dengan kelas atau pertemuan yang valid.'**
  String get quizInvalidClassMeeting;

  /// Pesan error post test tidak memiliki class_id valid
  ///
  /// In id, this message translates to:
  /// **'Kuis post test tidak terhubung dengan kelas yang valid.'**
  String get quizInvalidClass;

  /// Pesan error saat daftar soal kuis masih kosong
  ///
  /// In id, this message translates to:
  /// **'Soal kuis belum diunggah oleh pengajar.'**
  String get quizNoQuestionsUploaded;

  /// Pesan error saat attempt sebelumnya telah expired tanpa jawaban
  ///
  /// In id, this message translates to:
  /// **'Sesi pengerjaan sebelumnya telah berakhir sebelum jawaban dikumpulkan.'**
  String get quizStaleSessionEnded;

  /// Pesan error kuota attempt kuis pretest telah habis
  ///
  /// In id, this message translates to:
  /// **'Anda telah mencapai batas maksimal percobaan ({attempts}x).'**
  String quizMaxAttemptsReached(String attempts);

  /// Pesan error kuota attempt kuis post test telah habis
  ///
  /// In id, this message translates to:
  /// **'Anda telah mencapai batas maksimal percobaan ({count}/{max}).'**
  String quizPosttestMaxAttemptsReached(String count, String max);

  /// Pesan exception generik saat inisialisasi kuis gagal
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat sesi kuis: {error}'**
  String quizLoadFailedGeneric(String error);

  /// Indikator loading saat pemutar video diinisialisasi
  ///
  /// In id, this message translates to:
  /// **'Memuat pemutar video...'**
  String get videoLoadingPlayer;

  /// Pesan error saat video pembelajaran tidak ditemukan
  ///
  /// In id, this message translates to:
  /// **'Video pembelajaran tidak ditemukan.'**
  String get videoNotFound;

  /// Pesan error saat URL video YouTube tidak valid
  ///
  /// In id, this message translates to:
  /// **'URL video YouTube tidak valid.'**
  String get videoYoutubeUrlInvalid;

  /// Pesan error gagal memutar video Cloudinary
  ///
  /// In id, this message translates to:
  /// **'Gagal memutar video Cloudinary: {error}'**
  String videoPlaybackFailed(String error);

  /// Judul error saat startup inisialisasi Firebase gagal
  ///
  /// In id, this message translates to:
  /// **'Inisialisasi Firebase Gagal'**
  String get startupFirebaseInitFailed;

  /// Judul kartu buku panduan di dashboard
  ///
  /// In id, this message translates to:
  /// **'Buku Panduan LMS'**
  String get dashboardManualBookTitle;

  /// Deskripsi kartu buku panduan di dashboard
  ///
  /// In id, this message translates to:
  /// **'Akses panduan sistem Farlean LMS untuk mahasiswa dan pengajar'**
  String get dashboardManualBookDesc;

  /// Badge admin pada buku panduan
  ///
  /// In id, this message translates to:
  /// **'Dikelola Admin'**
  String get dashboardManualBookAdminBadge;

  /// Judul panduan sistem global
  ///
  /// In id, this message translates to:
  /// **'Buku Panduan Sistem'**
  String get manualBookSystemTitle;

  /// Pesan saat buku panduan sistem kosong
  ///
  /// In id, this message translates to:
  /// **'Belum ada buku panduan sistem yang dipublikasikan oleh Administrator.'**
  String get manualBookSystemEmpty;

  /// Peringatan hak akses panduan sistem
  ///
  /// In id, this message translates to:
  /// **'Hanya Admin yang berhak mengelola buku panduan sistem global.'**
  String get manualBookOnlyAdminCanManage;

  /// Nama tab kelompok pada detail kelas
  ///
  /// In id, this message translates to:
  /// **'Kelompok'**
  String get tabGroups;

  /// Judul state kosong daftar kelompok
  ///
  /// In id, this message translates to:
  /// **'Belum Ada Kelompok'**
  String get groupsEmptyTitle;

  /// Deskripsi state kosong daftar kelompok
  ///
  /// In id, this message translates to:
  /// **'Dosen dapat membuat kelompok mahasiswa untuk kegiatan tugas dan diskusi kelompok.'**
  String get groupsEmptyDesc;

  /// Tombol buat kelompok baru
  ///
  /// In id, this message translates to:
  /// **'Buat Kelompok'**
  String get groupsCreateBtn;

  /// Judul dialog pembuatan kelompok
  ///
  /// In id, this message translates to:
  /// **'Buat Kelompok Baru'**
  String get groupsCreateTitle;

  /// Label input nama kelompok
  ///
  /// In id, this message translates to:
  /// **'Nama Kelompok'**
  String get groupsNameLabel;

  /// Hint text input nama kelompok
  ///
  /// In id, this message translates to:
  /// **'Contoh: Kelompok 1 - Pemrograman Mobile'**
  String get groupsNameHint;

  /// Validasi nama kelompok kosong
  ///
  /// In id, this message translates to:
  /// **'Nama kelompok wajib diisi'**
  String get groupsNameRequired;

  /// Judul pemilih anggota kelompok
  ///
  /// In id, this message translates to:
  /// **'Pilih Anggota ({count} terpilih)'**
  String groupsSelectMembersTitle(int count);

  /// Pesan jika tidak ada mahasiswa yang belum berkelompok
  ///
  /// In id, this message translates to:
  /// **'Semua mahasiswa aktif di kelas ini sudah memiliki kelompok.'**
  String get groupsNoAvailableMembers;

  /// Jumlah anggota dalam kelompok
  ///
  /// In id, this message translates to:
  /// **'{count, plural, =0{Belum ada anggota} =1{1 anggota} other{{count} anggota}}'**
  String groupsMemberCount(int count);

  /// Judul konfirmasi hapus kelompok
  ///
  /// In id, this message translates to:
  /// **'Hapus Kelompok?'**
  String get groupsDeleteConfirmTitle;

  /// Konfirmasi penghapusan kelompok
  ///
  /// In id, this message translates to:
  /// **'Kelompok \'{name}\' akan dihapus dan anggotanya akan kembali belum memiliki kelompok.'**
  String groupsDeleteConfirmDesc(String name);

  /// Notifikasi sukses hapus kelompok
  ///
  /// In id, this message translates to:
  /// **'Kelompok berhasil dihapus'**
  String get groupsDeleteSuccess;

  /// Notifikasi sukses buat kelompok
  ///
  /// In id, this message translates to:
  /// **'Kelompok berhasil dibuat'**
  String get groupsCreateSuccess;

  /// Label ketua kelompok
  ///
  /// In id, this message translates to:
  /// **'Ketua Kelompok'**
  String get groupsLeaderLabel;

  /// Aksi memilih ketua kelompok
  ///
  /// In id, this message translates to:
  /// **'Pilih Sebagai Ketua'**
  String get groupsSetLeader;

  /// Indikator loading data kelompok
  ///
  /// In id, this message translates to:
  /// **'Memuat data kelompok...'**
  String get groupsLoading;

  /// Judul dialog ubah kelompok
  ///
  /// In id, this message translates to:
  /// **'Ubah Kelompok'**
  String get groupsEditTitle;

  /// Notifikasi sukses ubah kelompok
  ///
  /// In id, this message translates to:
  /// **'Kelompok berhasil diperbarui'**
  String get groupsEditSuccess;

  /// Nama tab tugas kelas
  ///
  /// In id, this message translates to:
  /// **'Tugas'**
  String get tabAssignments;

  /// Jumlah tugas di kelas
  ///
  /// In id, this message translates to:
  /// **'{count, plural, =0{Belum ada tugas} =1{1 tugas} other{{count} tugas}}'**
  String assignmentCount(int count);

  /// Judul state kosong daftar tugas
  ///
  /// In id, this message translates to:
  /// **'Belum Ada Tugas'**
  String get assignmentEmptyTitle;

  /// Deskripsi state kosong daftar tugas
  ///
  /// In id, this message translates to:
  /// **'Pengajar belum memberikan tugas untuk kelas ini.'**
  String get assignmentEmptyDesc;

  /// Tombol buat tugas baru
  ///
  /// In id, this message translates to:
  /// **'Buat Tugas'**
  String get assignmentCreateBtn;

  /// Judul dialog pembuatan tugas
  ///
  /// In id, this message translates to:
  /// **'Buat Tugas Baru'**
  String get assignmentCreateTitle;

  /// Label judul tugas
  ///
  /// In id, this message translates to:
  /// **'Judul Tugas'**
  String get assignmentTitleLabel;

  /// Validasi judul tugas kosong
  ///
  /// In id, this message translates to:
  /// **'Judul tugas wajib diisi'**
  String get assignmentTitleRequired;

  /// Label petunjuk pengerjaan tugas
  ///
  /// In id, this message translates to:
  /// **'Petunjuk Pengerjaan'**
  String get assignmentInstructionsLabel;

  /// Label batas waktu tugas
  ///
  /// In id, this message translates to:
  /// **'Batas Waktu (Deadline)'**
  String get assignmentDeadlineLabel;

  /// Switch izinkan pengumpulan terlambat
  ///
  /// In id, this message translates to:
  /// **'Izinkan Pengumpulan Terlambat'**
  String get assignmentAllowLateLabel;

  /// Switch penanda tugas kelompok
  ///
  /// In id, this message translates to:
  /// **'Tugas Kelompok'**
  String get assignmentIsGroupLabel;

  /// Badge tugas individu
  ///
  /// In id, this message translates to:
  /// **'Individu'**
  String get assignmentIndividualBadge;

  /// Badge tugas kelompok
  ///
  /// In id, this message translates to:
  /// **'Kelompok'**
  String get assignmentGroupBadge;

  /// Status pengumpulan tepat waktu
  ///
  /// In id, this message translates to:
  /// **'Dikumpulkan'**
  String get assignmentStatusSubmitted;

  /// Status pengumpulan terlambat
  ///
  /// In id, this message translates to:
  /// **'Terlambat'**
  String get assignmentStatusLate;

  /// Status pengumpulan sudah dinilai
  ///
  /// In id, this message translates to:
  /// **'Sudah Dinilai'**
  String get assignmentStatusGraded;

  /// Status belum mengumpulkan
  ///
  /// In id, this message translates to:
  /// **'Belum Mengumpulkan'**
  String get assignmentStatusNotSubmitted;

  /// Tombol kumpulkan tugas
  ///
  /// In id, this message translates to:
  /// **'Kumpulkan Tugas'**
  String get assignmentSubmitBtn;

  /// Tombol kumpulkan ulang tugas
  ///
  /// In id, this message translates to:
  /// **'Kumpulkan Ulang'**
  String get assignmentResubmitBtn;

  /// Label input berkas tugas
  ///
  /// In id, this message translates to:
  /// **'Berkas Tugas (PDF, DOCX, ZIP)'**
  String get assignmentFileLabel;

  /// Pesan error gagal unggah berkas tugas
  ///
  /// In id, this message translates to:
  /// **'Gagal mengunggah berkas: {error}'**
  String assignmentUploadFailed(String error);

  /// Pesan sukses pengumpulan tugas
  ///
  /// In id, this message translates to:
  /// **'Tugas berhasil dikumpulkan!'**
  String get assignmentSubmitSuccess;

  /// Tombol buka dialog penilaian
  ///
  /// In id, this message translates to:
  /// **'Beri Nilai'**
  String get assignmentGradeBtn;

  /// Judul dialog penilaian tugas
  ///
  /// In id, this message translates to:
  /// **'Penilaian Tugas'**
  String get assignmentGradeTitle;

  /// Label input nilai
  ///
  /// In id, this message translates to:
  /// **'Nilai (0 - 100)'**
  String get assignmentScoreLabel;

  /// Label input feedback dosen
  ///
  /// In id, this message translates to:
  /// **'Catatan / Umpan Balik'**
  String get assignmentFeedbackLabel;

  /// Pesan sukses simpan nilai
  ///
  /// In id, this message translates to:
  /// **'Nilai berhasil disimpan'**
  String get assignmentGradedSuccess;

  /// Peringatan mahasiswa belum punya kelompok pada tugas kelompok
  ///
  /// In id, this message translates to:
  /// **'Anda belum tergabung dalam kelompok mana pun di kelas ini. Hubungi pengajar untuk dimasukkan ke kelompok sebelum mengumpulkan tugas kelompok.'**
  String get assignmentNoGroupWarning;

  /// Peringatan deadline kaku terkunci
  ///
  /// In id, this message translates to:
  /// **'Batas waktu pengumpulan telah berakhir dan pengajar tidak mengizinkan pengumpulan terlambat.'**
  String get assignmentDeadlinePassedLocked;

  /// Jumlah submission terkumpul
  ///
  /// In id, this message translates to:
  /// **'{count} Pengumpulan'**
  String assignmentSubmissionsCount(int count);

  /// Judul AppBar detail tugas
  ///
  /// In id, this message translates to:
  /// **'Detail Tugas'**
  String get assignmentDetailTitle;

  /// Judul konfirmasi hapus tugas
  ///
  /// In id, this message translates to:
  /// **'Hapus Tugas?'**
  String get assignmentDeleteConfirmTitle;

  /// Deskripsi konfirmasi hapus tugas
  ///
  /// In id, this message translates to:
  /// **'Tugas \'{title}\' dan seluruh pengumpulan mahasiswa akan dihapus permanen.'**
  String assignmentDeleteConfirmDesc(String title);

  /// Notifikasi sukses hapus tugas
  ///
  /// In id, this message translates to:
  /// **'Tugas berhasil dihapus'**
  String get assignmentDeleteSuccess;

  /// Tombol buka balasan diskusi ala YouTube
  ///
  /// In id, this message translates to:
  /// **'{count, plural, =1{Lihat 1 balasan} other{Lihat {count} balasan}}'**
  String discussionShowReplies(int count);

  /// Tombol sembunyikan balasan diskusi
  ///
  /// In id, this message translates to:
  /// **'Sembunyikan balasan'**
  String get discussionHideReplies;

  /// Tooltip ikon unduh materi sebagai PDF
  ///
  /// In id, this message translates to:
  /// **'Unduh Materi sebagai PDF'**
  String get materialExportPdfTooltip;

  /// Pesan loading saat render materi ke PDF
  ///
  /// In id, this message translates to:
  /// **'Menyiapkan dokumen PDF...'**
  String get materialExportingPdf;

  /// Pesan sukses ekspor materi ke PDF
  ///
  /// In id, this message translates to:
  /// **'Dokumen PDF berhasil dibuat'**
  String get materialExportPdfSuccess;

  /// Pesan gagal ekspor materi ke PDF
  ///
  /// In id, this message translates to:
  /// **'Gagal membuat PDF: {error}'**
  String materialExportPdfFailed(String error);

  /// Judul AppBar layar AI Tutor
  ///
  /// In id, this message translates to:
  /// **'AI Tutor Pintar'**
  String get aiTutorTitle;

  /// Subjudul sambutan AI Tutor
  ///
  /// In id, this message translates to:
  /// **'Asisten belajar cerdas bimbingan konsep pembelajaran'**
  String get aiTutorSubtitle;

  /// Placeholder input pesan AI Tutor
  ///
  /// In id, this message translates to:
  /// **'Tanyakan konsep materi, rumus, atau logika pemrograman...'**
  String get aiTutorHint;

  /// Pesan sambutan pembuka AI Tutor
  ///
  /// In id, this message translates to:
  /// **'Halo! Saya Farlean AI Tutor. Ada konsep materi pembelajaran yang ingin kamu diskusikan hari ini?'**
  String get aiTutorWelcome;

  /// Peringatan input pertanyaan kosong
  ///
  /// In id, this message translates to:
  /// **'Pertanyaan tidak boleh kosong'**
  String get aiTutorPromptEmpty;

  /// Peringatan penguncian AI saat ujian aktif
  ///
  /// In id, this message translates to:
  /// **'Fitur AI Tutor dinonaktifkan sementara saat Anda sedang menempuh sesi kuis/ujian.'**
  String get aiTutorExamLocked;

  /// Tombol pemicu AI pembuat draf deskripsi video
  ///
  /// In id, this message translates to:
  /// **'Bantu Buat Draf (AI)'**
  String get aiVideoDraftBtn;

  /// Pesan loading AI deskripsi video
  ///
  /// In id, this message translates to:
  /// **'Menyusun draf deskripsi dengan AI...'**
  String get aiVideoDrafting;

  /// Notifikasi sukses pembuatan draf video AI
  ///
  /// In id, this message translates to:
  /// **'Draf deskripsi berhasil dibuat! Anda dapat mengedit sebelum menyimpan.'**
  String get aiVideoDraftSuccess;

  /// Judul dialog edit video
  ///
  /// In id, this message translates to:
  /// **'Edit Video Pembelajaran'**
  String get videoEditTitle;

  /// Label field judul video
  ///
  /// In id, this message translates to:
  /// **'Judul Video'**
  String get videoTitleLabel;

  /// Label field deskripsi video
  ///
  /// In id, this message translates to:
  /// **'Deskripsi Video'**
  String get videoDescLabel;

  /// Notifikasi sukses update video
  ///
  /// In id, this message translates to:
  /// **'Informasi video berhasil diperbarui'**
  String get videoEditSuccess;

  /// Judul status pendaftaran kelas pending
  ///
  /// In id, this message translates to:
  /// **'Pendaftaran Menunggu Persetujuan'**
  String get classPendingTitle;

  /// Deskripsi status pendaftaran kelas pending
  ///
  /// In id, this message translates to:
  /// **'Permintaan Anda untuk bergabung ke kelas ini telah dikirim dan sedang menunggu konfirmasi dari Dosen Pengampu.'**
  String get classPendingBody;

  /// Tombol kembali pada status pendaftaran pending
  ///
  /// In id, this message translates to:
  /// **'Kembali ke Beranda'**
  String get classPendingBackBtn;

  /// Judul halaman pelengkapan profil onboarding
  ///
  /// In id, this message translates to:
  /// **'Lengkapi Profil Anda'**
  String get completeProfileTitle;

  /// Subjudul halaman pelengkapan profil onboarding
  ///
  /// In id, this message translates to:
  /// **'Sebelum melanjutkan, silakan periksa dan lengkapi data profil Anda.'**
  String get completeProfileSubtitle;

  /// Label field email terverifikasi onboarding
  ///
  /// In id, this message translates to:
  /// **'Alamat Email Terverifikasi'**
  String get completeProfileEmailLabel;

  /// Label badge tipe akun terdeteksi onboarding
  ///
  /// In id, this message translates to:
  /// **'Tipe Akun Terdeteksi'**
  String get completeProfileAccountType;

  /// Label input nama lengkap onboarding
  ///
  /// In id, this message translates to:
  /// **'Nama Lengkap'**
  String get completeProfileNameLabel;

  /// Peringatan validasi nama lengkap kosong
  ///
  /// In id, this message translates to:
  /// **'Nama lengkap wajib diisi'**
  String get completeProfileNameRequired;

  /// Peringatan validasi identitas NIM/NIP kosong
  ///
  /// In id, this message translates to:
  /// **'{label} wajib diisi'**
  String completeProfileIdentityRequired(String label);

  /// Placeholder input identitas NIM/NIP
  ///
  /// In id, this message translates to:
  /// **'Masukkan {label} Anda'**
  String completeProfileIdentityHint(String label);

  /// Teks checkbox persetujuan syarat dan ketentuan
  ///
  /// In id, this message translates to:
  /// **'Saya menyetujui Syarat & Ketentuan Penggunaan dan Kebijakan Privasi Farlean LMS.'**
  String get completeProfileTermsCheckbox;

  /// Peringatan belum mencentang syarat dan ketentuan
  ///
  /// In id, this message translates to:
  /// **'Anda wajib menyetujui syarat & ketentuan untuk melanjutkan.'**
  String get completeProfileTermsRequired;

  /// Tombol submit onboarding profil
  ///
  /// In id, this message translates to:
  /// **'Simpan & Lanjutkan'**
  String get completeProfileSubmitBtn;

  /// Notifikasi sukses pelengkapan profil
  ///
  /// In id, this message translates to:
  /// **'Profil berhasil dilengkapi! Selamat datang di Farlean LMS.'**
  String get completeProfileSuccess;

  /// Subjudul AppBar AI Tutor rincian sisa kuota dual-tier
  ///
  /// In id, this message translates to:
  /// **'Sisa kuota: {quota} (Sesi: {burst}, Harian: {daily})'**
  String aiTutorQuotaSubtitle(int quota, int burst, int daily);

  /// Peringatan kuota AI tercapai dengan estimasi reset
  ///
  /// In id, this message translates to:
  /// **'Batas kuota tercapai. Reset dalam {minutes} menit.'**
  String aiTutorQuotaExceeded(int minutes);
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

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

  /// Validasi protokol URL video
  ///
  /// In id, this message translates to:
  /// **'URL harus diawali http:// atau https://'**
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

  /// Validasi protokol URL gambar
  ///
  /// In id, this message translates to:
  /// **'URL harus diawali dengan http:// atau https://'**
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

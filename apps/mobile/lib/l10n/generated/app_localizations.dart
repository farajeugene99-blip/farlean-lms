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

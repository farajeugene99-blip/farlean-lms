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

  @override
  String get profileScreenTitle => 'Profil Pengguna';

  @override
  String get profileDefaultName => 'Pengguna Farlean';

  @override
  String get profileEditNameTooltip => 'Ubah Nama';

  @override
  String profileBadgeType(String type) {
    return 'Tipe: $type';
  }

  @override
  String profileBadgeRole(String role) {
    return 'Role: $role';
  }

  @override
  String get profileEditNameTitle => 'Ubah Nama Lengkap';

  @override
  String profileNameMaxLength(int max) {
    return 'Maksimal $max karakter';
  }

  @override
  String profileNameUpdateFail(String detail) {
    return 'Gagal memperbarui nama: $detail';
  }

  @override
  String get profileNameUpdated => 'Nama profil berhasil diperbarui.';

  @override
  String profileIdentityTitle(String label) {
    return 'Nomor Induk ($label)';
  }

  @override
  String get profileIdentityPrivacyNote =>
      'Data ini disimpan di sub-koleksi private/identity yang terisolasi dan hanya dapat diakses oleh Anda dan Admin. Pengajar kelas Anda melihatnya hanya melalui rekap resmi, bukan dari aplikasi.';

  @override
  String profileIdentityRequired(String label) {
    return '$label wajib diisi';
  }

  @override
  String profileIdentitySaveFail(String label, String detail) {
    return 'Gagal menyimpan $label: $detail';
  }

  @override
  String profileIdentitySaved(String label) {
    return '$label berhasil disimpan di private identity.';
  }

  @override
  String get profileIdentityNotSet => 'Belum diisi (Klik untuk menambahkan)';

  @override
  String get profileSecurityTitle => 'Keamanan & Kata Sandi';

  @override
  String get profileSecuritySubtitle =>
      'Ubah kata sandi akun untuk perangkat ini';

  @override
  String get profileCacheTitle => 'Penyimpanan & Cache';

  @override
  String get profileCacheSubtitle =>
      'Kelola memori sementara dan pilihan kelas aktif';

  @override
  String get profileEmailVerificationTitle => 'Status Verifikasi Email';

  @override
  String get profileEmailVerified => 'Email Terverifikasi';

  @override
  String get profileEmailPending => 'Menunggu Verifikasi';

  @override
  String get profileSyncTitle => 'Sinkronisasi Sesi & Peran';

  @override
  String profileSyncOutOfSync(String claimsRole, String profileRole) {
    return 'Peran belum sinkron (Token: $claimsRole vs Profil: $profileRole). Tekan perbarui.';
  }

  @override
  String get profileSyncUpToDate => 'Sesi dan hak akses token mutakhir.';

  @override
  String get profileRefreshSessionTooltip => 'Perbarui Sesi';

  @override
  String get profileSessionRefreshed =>
      'Sesi dan token hak akses berhasil diperbarui.';

  @override
  String get profileLogoutBtn => 'Keluar dari Akun';

  @override
  String get profileLoggingOut => 'Sedang Keluar...';

  @override
  String get profileLogoutConfirmTitle => 'Keluar dari Akun?';

  @override
  String get profileLogoutConfirmBody =>
      'Apakah Anda yakin ingin keluar dari sesi Farlean LMS di perangkat ini?';

  @override
  String get profileLogoutQuizWarning =>
      'Perhatian: Anda memiliki kuis yang sedang dikerjakan. Jika Anda keluar sekarang, pengerjaan kuis dapat terganggu dan jawaban yang belum tersimpan dapat hilang.';

  @override
  String get profileLogoutOfflineWarning =>
      'Tidak dapat memverifikasi status kuis karena perangkat sedang offline. Jika Anda sedang mengerjakan kuis, jawaban yang belum tersinkronisasi ke server mungkin hilang.';

  @override
  String profileLogoutFailed(String detail) {
    return 'Gagal keluar akun: $detail';
  }

  @override
  String get profileChangePasswordTitle => 'Ubah Kata Sandi';

  @override
  String profileChangePasswordNote(int min) {
    return 'Untuk keamanan akun Anda, masukkan kata sandi saat ini lalu buat kata sandi baru minimal $min karakter.';
  }

  @override
  String get profileCurrentPasswordLabel => 'Kata Sandi Saat Ini';

  @override
  String get profileCurrentPasswordRequired =>
      'Kata sandi saat ini wajib diisi';

  @override
  String profileNewPasswordLabel(int min) {
    return 'Kata Sandi Baru (Min. $min Karakter)';
  }

  @override
  String get profileNewPasswordRequired => 'Kata sandi baru wajib diisi';

  @override
  String profileNewPasswordMinError(int min) {
    return 'Kata sandi baru minimal $min karakter.';
  }

  @override
  String get profileNewPasswordSameAsCurrent =>
      'Kata sandi baru tidak boleh sama dengan kata sandi saat ini.';

  @override
  String get profileConfirmNewPasswordLabel => 'Konfirmasi Kata Sandi Baru';

  @override
  String get profileConfirmPasswordRequired =>
      'Konfirmasi kata sandi wajib diisi';

  @override
  String get profileForgotCurrentPasswordLink => 'Lupa kata sandi saat ini?';

  @override
  String get profileSavePasswordBtn => 'Simpan Sandi';

  @override
  String get profileCurrentPasswordWrong =>
      'Kata sandi saat ini yang Anda masukkan salah.';

  @override
  String profilePasswordUpdateFail(String detail) {
    return 'Gagal memperbarui kata sandi: $detail';
  }

  @override
  String get profilePwUpdated =>
      'Kata sandi berhasil diperbarui untuk akun ini.';

  @override
  String get profileCacheDesc =>
      'Kelola memori sementara gambar dan preferensi kelas aktif di perangkat ini secara aman.';

  @override
  String get profileCacheEmpty => '0 KB (belum ada gambar dimuat di memori)';

  @override
  String profileCacheStats(int count, String kb) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$kb KB ($count gambar aktif di memori)',
    );
    return '$_temp0';
  }

  @override
  String get profileCacheImageSection => 'Cache Gambar di Memori (RAM)';

  @override
  String get profileCacheImageNote =>
      'Catatan: Cache memori menampung gambar materi yang sedang dibuka. Mengosongkannya aman dan gambar akan diunduh kembali saat dibuka.';

  @override
  String get profileCacheClearBtn => 'Kosongkan Cache Gambar RAM';

  @override
  String get profileCacheCleared => 'Cache memori gambar berhasil dikosongkan.';

  @override
  String get profileClassSavedSection => 'Pilihan Kelas Aktif Tersimpan';

  @override
  String get profileClassNoneSelected => 'Belum ada kelas aktif yang dipilih';

  @override
  String get profileClassResetNote =>
      'Mereset kelas aktif akan mengarahkan Anda ke Beranda untuk memilih kembali kelas pembelajaran.';

  @override
  String get profileActiveQuizTitle => 'Kuis Sedang Dikerjakan';

  @override
  String get profileResetClassQuizBlocked =>
      'Tidak dapat mereset kelas aktif: Anda sedang memiliki kuis yang sedang dikerjakan. Selesaikan atau kumpulkan kuis terlebih dahulu sebelum mereset kelas.';

  @override
  String get profileBtnGotIt => 'Mengerti';

  @override
  String get profileOfflineTitle => 'Perangkat Offline';

  @override
  String get profileResetClassOfflineBlocked =>
      'Tidak dapat memverifikasi status kuis karena perangkat sedang offline. Untuk keamanan jawaban kuis Anda, reset kelas aktif ditunda hingga perangkat terhubung kembali.';

  @override
  String get profileResetClassConfirmTitle => 'Reset Pilihan Kelas?';

  @override
  String get profileResetClassConfirmBody =>
      'Anda akan diarahkan kembali ke Beranda untuk memilih kelas pembelajaran.';

  @override
  String get profileBtnReset => 'Reset';

  @override
  String get profileResetClassBtn => 'Reset Pilihan Kelas Aktif';

  @override
  String get profileResetClassDone => 'Pilihan kelas aktif berhasil direset.';
}

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

  @override
  String get meetingStatusDraft => 'Draf';

  @override
  String get meetingStatusScheduled => 'Terjadwal';

  @override
  String get meetingStatusPublished => 'Dipublikasikan';

  @override
  String get meetingStatusArchived => 'Diarsipkan';

  @override
  String get meetingListTitle => 'Materi & Pertemuan';

  @override
  String get meetingSyncTooltip => 'Sinkronkan Jadwal Publikasi';

  @override
  String get meetingRefreshTooltip => 'Segarkan';

  @override
  String get meetingAddFab => 'Tambah Pertemuan';

  @override
  String get meetingErrorPermissionStaff =>
      'Akses ditolak: Anda tidak memiliki wewenang untuk mengelola kelas ini.';

  @override
  String get meetingErrorPermissionStudent =>
      'Akses ditolak: Anda belum terdaftar sebagai anggota aktif di kelas ini. Pastikan Anda telah bergabung dan disetujui.';

  @override
  String get meetingErrorNetwork =>
      'Koneksi ke server bermasalah. Periksa jaringan internet atau emulator Anda.';

  @override
  String meetingErrorLoadFailed(String detail) {
    return 'Gagal memuat daftar pertemuan: $detail';
  }

  @override
  String get meetingSelectClassFirst =>
      'Pilih kelas yang valid terlebih dahulu untuk membuat pertemuan.';

  @override
  String get meetingCreateTitle => 'Buat Pertemuan Baru';

  @override
  String get meetingNumberLabel => 'Nomor Pertemuan';

  @override
  String get meetingNumberRequired => 'Nomor wajib diisi';

  @override
  String get meetingNumberMustBePositive => 'Nomor harus angka > 0';

  @override
  String get meetingTitleLabel => 'Judul Pertemuan';

  @override
  String get meetingTitleRequired => 'Judul wajib diisi';

  @override
  String get meetingSaveDraftBtn => 'Simpan Draft';

  @override
  String meetingCreateFailed(String detail) {
    return 'Gagal: $detail';
  }

  @override
  String meetingActionFailed(String detail) {
    return 'Gagal: $detail';
  }

  @override
  String meetingSyncScheduleSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count pertemuan terjadwal yang jatuh tempo berhasil dipublikasikan.',
      zero: 'Tidak ada pertemuan terjadwal yang jatuh tempo saat ini.',
    );
    return '$_temp0';
  }

  @override
  String meetingSyncFailed(String detail) {
    return 'Gagal menyinkronkan jadwal: $detail';
  }

  @override
  String get meetingNoClassTitle => 'Pilih Kelas Pembelajaran';

  @override
  String get meetingNoClassBody =>
      'Anda belum memilih kelas. Silakan bergabung menggunakan kode kelas atau pilih kelas dari Beranda untuk melihat pertemuan.';

  @override
  String get meetingJoinClassBtn => 'Gabung Kelas';

  @override
  String get meetingClassLabel => 'Kelas:';

  @override
  String get meetingLoading => 'Memuat pertemuan...';

  @override
  String get meetingEmptyTitle => 'Belum Ada Pertemuan';

  @override
  String get meetingEmptyStaffDesc =>
      'Buat pertemuan baru untuk mulai mengunggah materi, kuis pretest, dan video pembelajaran.';

  @override
  String get meetingEmptyStudentDesc =>
      'Pengajar belum mempublikasikan pertemuan pembelajaran di kelas ini.';

  @override
  String get meetingCreateFirstBtn => 'Buat Pertemuan Pertama';

  @override
  String meetingCardNumber(int number) {
    return 'Pertemuan $number';
  }

  @override
  String meetingPublishAtLabel(String when) {
    return 'Terbit: $when';
  }

  @override
  String get meetingModulePretest => 'Pretest';

  @override
  String get meetingModuleMateri => 'Materi';

  @override
  String get meetingModuleVideo => 'Video';

  @override
  String get meetingModulePosttest => 'Post Test';

  @override
  String get meetingDetailLoading => 'Memuat hub pertemuan...';

  @override
  String get meetingDetailTitle => 'Detail Pertemuan';

  @override
  String get meetingNotFound => 'Pertemuan tidak ditemukan.';

  @override
  String meetingLoadDetailFailed(String detail) {
    return 'Gagal memuat detail pertemuan: $detail';
  }

  @override
  String meetingScheduledLockedNotice(String when) {
    return 'Pertemuan ini masih berstatus Terjadwal. Konten akan dibuka pada $when.';
  }

  @override
  String get meetingScheduledFutureFallback => 'waktu jadwal mendatang';

  @override
  String get meetingPickScheduleDateTitle =>
      'Pilih Tanggal Publikasi Pertemuan';

  @override
  String get meetingPickScheduleTimeTitle => 'Pilih Jam Publikasi (WIB)';

  @override
  String get meetingScheduleMustBeFuture =>
      'Waktu publikasi terjadwal harus di waktu mendatang.';

  @override
  String meetingScheduledSuccess(String when) {
    return 'Pertemuan berhasil dijadwalkan terbit pada $when.';
  }

  @override
  String meetingScheduleFailed(String detail) {
    return 'Gagal menjadwalkan pertemuan: $detail';
  }

  @override
  String meetingChangeStatusConfirmTitle(String status) {
    return 'Ubah Status ke $status?';
  }

  @override
  String get meetingChangeStatusPublishBody =>
      'Pertemuan ini akan dapat diakses oleh seluruh anggota kelas yang aktif.';

  @override
  String get meetingChangeStatusArchiveBody =>
      'Pertemuan ini akan diarsipkan dan tidak lagi muncul sebagai sesi aktif.';

  @override
  String meetingStatusChangedSuccess(String status) {
    return 'Status berhasil diubah menjadi $status';
  }

  @override
  String get meetingEditDialogTitle => 'Edit Informasi Pertemuan';

  @override
  String get meetingDescriptionLabel => 'Deskripsi / Ringkasan';

  @override
  String get meetingEditTooltip => 'Edit Info Pertemuan';

  @override
  String get meetingDeleteTooltip => 'Hapus Pertemuan';

  @override
  String get meetingManageStatusTooltip => 'Kelola Status';

  @override
  String get meetingMenuPublishNow => 'Publikasikan Sekarang (Published)';

  @override
  String get meetingMenuSchedule => 'Jadwalkan Publikasi (Scheduled)';

  @override
  String get meetingMenuDraft => 'Jadikan Draft / Batalkan Jadwal';

  @override
  String get meetingMenuArchive => 'Arsipkan (Archived)';

  @override
  String get meetingDeleteConfirmTitle => 'Hapus Pertemuan Ini?';

  @override
  String get meetingDeleteConfirmBody =>
      'Tindakan ini akan menghapus pertemuan dari daftar kelas.';

  @override
  String get meetingDeleteAction => 'Hapus';

  @override
  String get meetingDeletedSuccess => 'Pertemuan berhasil dihapus.';

  @override
  String meetingDeleteFailed(String detail) {
    return 'Gagal menghapus: $detail';
  }

  @override
  String get meetingDefaultDescription =>
      'Satu pertemuan menghubungkan kuis pretest, materi bacaan terstruktur, video pembelajaran, dan post test evaluasi.';

  @override
  String get meetingScheduledBannerTitle => 'Pertemuan Terjadwal';

  @override
  String meetingScheduledBanner(String when) {
    return 'Dijadwalkan terbit pada $when. Publikasi berjalan saat cron/sinkronisasi berikutnya (dalam kisaran jadwal), bukan tepat-menit otomatis.';
  }

  @override
  String get meetingScheduledBannerFallback =>
      'Pertemuan disiapkan untuk jadwal publikasi mendatang.';

  @override
  String get meetingModulesTitle => 'Modul Pembelajaran';

  @override
  String get meetingModuleMaterialTitle => 'Materi Pembelajaran';

  @override
  String get meetingModuleMaterialSubActive =>
      'Materi bacaan terstruktur format Quill Delta';

  @override
  String get meetingModuleMaterialSubStaffEmpty =>
      'Materi belum dibuat. Klik untuk membuat materi baru.';

  @override
  String get meetingModuleMaterialSubStudentEmpty =>
      'Materi belum diunggah oleh pengajar';

  @override
  String get meetingModuleMaterialActionOpen => 'Buka Materi';

  @override
  String get meetingModuleMaterialActionCreate => 'Buat Materi';

  @override
  String get meetingModulePretestTitle => 'Kuis Pretest';

  @override
  String get meetingModulePretestSubActive =>
      'Uji pemahaman awal sebelum memulai materi inti';

  @override
  String get meetingModulePretestSubStaffEmpty =>
      'Pretest belum diaktifkan. Klik untuk membuat pretest.';

  @override
  String get meetingModulePretestSubStudentEmpty =>
      'Pretest belum diaktifkan untuk pertemuan ini';

  @override
  String get meetingModulePretestActionStart => 'Mulai Pretest';

  @override
  String get meetingModulePretestActionCreate => 'Buat Pretest';

  @override
  String get meetingModulePretestManageQuestions => 'Kelola Soal';

  @override
  String get meetingModulePretestBadgeNotice => 'Wajib pernah buka materi';

  @override
  String get meetingModuleVideoTitle => 'Video Pembelajaran';

  @override
  String get meetingModuleVideoSubActive =>
      'Video tutorial & demonstrasi interaktif';

  @override
  String get meetingModuleVideoSubStaffEmpty =>
      'Video belum ditautkan. Klik untuk menambahkan link video.';

  @override
  String get meetingModuleVideoSubStudentEmpty =>
      'Video belum ditautkan ke pertemuan ini';

  @override
  String get meetingModuleVideoActionWatch => 'Tonton Video';

  @override
  String get meetingModuleVideoActionAdd => 'Tambah Video';

  @override
  String get meetingModulePosttestTitle => 'Kuis Post Test';

  @override
  String get meetingModulePosttestSubActive =>
      'Evaluasi akhir capaian pembelajaran setelah memahami materi';

  @override
  String get meetingModulePosttestSubStaffEmpty =>
      'Post test belum dibuat. Klik untuk membuat post test.';

  @override
  String get meetingModulePosttestSubStudentEmpty =>
      'Post test belum diaktifkan untuk pertemuan ini';

  @override
  String get meetingModulePosttestActionStart => 'Mulai Post Test';

  @override
  String get meetingModulePosttestActionCreate => 'Buat Post Test';

  @override
  String get meetingModuleNotAvailable => 'Belum Tersedia';

  @override
  String get meetingCreatePretestTitle => 'Buat Kuis Pretest';

  @override
  String meetingPretestDefaultTitle(int number) {
    return 'Pretest Pertemuan $number';
  }

  @override
  String get meetingPretestTitleLabel => 'Judul Pretest';

  @override
  String get meetingDurationLabel => 'Durasi (Menit)';

  @override
  String get meetingDurationMustBePositive => 'Durasi harus > 0 menit';

  @override
  String get meetingSaveAndManageQuestionsBtn => 'Simpan & Kelola Soal';

  @override
  String get meetingCreatePosttestTitle => 'Buat Kuis Post Test';

  @override
  String meetingPosttestDefaultTitle(int number) {
    return 'Post Test Pertemuan $number';
  }

  @override
  String get meetingPosttestTitleLabel => 'Judul Post Test';

  @override
  String get meetingAddVideoTitle => 'Tambah Video Pembelajaran';

  @override
  String get meetingVideoProviderLabel => 'Penyedia Video';

  @override
  String get meetingVideoUrlLabel => 'URL Video';

  @override
  String get meetingVideoUrlRequired => 'URL wajib diisi';

  @override
  String get meetingVideoUrlInvalid =>
      'URL harus diawali http:// atau https://';

  @override
  String get meetingSaveVideoBtn => 'Simpan Video';

  @override
  String meetingManageQuestionsTitle(String testTitle) {
    return 'Kelola Soal $testTitle';
  }

  @override
  String meetingQuestionCountActive(int count) {
    return 'Jumlah Soal: $count soal aktif';
  }

  @override
  String get meetingAddQuestionBtn => 'Tambah Soal';

  @override
  String get meetingPublishQuizBtn => 'Publikasikan Kuis';

  @override
  String get meetingPublishMinOneQuestion =>
      'Tambahkan minimal 1 soal sebelum mempublikasikan kuis.';

  @override
  String meetingPublishFailed(String detail) {
    return 'Gagal publikasi: $detail';
  }

  @override
  String get meetingQuizPublishedSuccess =>
      'Kuis berhasil dipublikasikan! Mahasiswa sekarang dapat mengakses kuis ini.';

  @override
  String get meetingDraftNoQuestionsTitle => 'Draft, belum ada soal aktif.';

  @override
  String get meetingDraftNoQuestionsBody =>
      'Klik tombol \"Tambah Soal\" untuk membuat soal kuis pertama.';

  @override
  String meetingPointsLabel(int points) {
    return '$points poin';
  }

  @override
  String get meetingEditAction => 'Edit';

  @override
  String get meetingCannotDeleteLastPublished =>
      'Tidak dapat menghapus soal aktif terakhir pada kuis yang berstatus Published. Silakan arsipkan kuis terlebih dahulu jika ingin menonaktifkannya.';

  @override
  String get meetingDeleteQuestionConfirmTitle => 'Konfirmasi Hapus Soal';

  @override
  String meetingDeleteQuestionConfirmBody(int number) {
    return 'Apakah Anda yakin ingin menghapus Soal $number? Jika kuis sudah pernah dikerjakan siswa, soal akan diarsipkan (soft-delete) dan riwayat nilai siswa terdahulu tetap aman.';
  }

  @override
  String get meetingDeleteQuestionBtn => 'Hapus Soal';

  @override
  String get meetingAddQuestionDialogTitle => 'Tambah Soal Baru';

  @override
  String get meetingEditQuestionDialogTitle => 'Edit Soal';

  @override
  String get meetingQuestionTextLabel => 'Teks Pertanyaan *';

  @override
  String get meetingQuestionTextHint => 'Masukkan pertanyaan...';

  @override
  String get meetingQuestionTextRequired => 'Teks pertanyaan wajib diisi';

  @override
  String get meetingQuestionPointsLabel => 'Poin Soal (1 - 100) *';

  @override
  String get meetingQuestionPointsRequired => 'Poin wajib diisi';

  @override
  String get meetingQuestionPointsInvalid => 'Poin harus antara 1 - 100';

  @override
  String get meetingOptionsSectionTitle => 'Pilihan Jawaban & Kunci (A - E) *';

  @override
  String get meetingOptionsSectionSubtitle =>
      'Tentukan 5 pilihan jawaban (A sampai E) dan pilih satu radio sebagai kunci jawaban benar.';

  @override
  String meetingOptionLabelKey(String letter) {
    return 'Pilihan $letter (★ KUNCI BENAR)';
  }

  @override
  String meetingOptionLabelRegular(String letter) {
    return 'Pilihan $letter';
  }

  @override
  String meetingOptionRequired(String letter) {
    return 'Pilihan $letter tidak boleh kosong';
  }

  @override
  String get meetingLegacyOptionsTitle =>
      'Pilihan Tambahan Terarsip (Legacy - Read Only):';

  @override
  String get materialNotFound => 'Materi tidak ditemukan.';

  @override
  String get materialNotFoundOrDeleted =>
      'Materi tidak ditemukan atau telah dihapus.';

  @override
  String materialLoadFailed(String detail) {
    return 'Gagal memuat materi: $detail';
  }

  @override
  String get materialLoading => 'Memuat materi pembelajaran...';

  @override
  String get materialAppBarTitle => 'Materi';

  @override
  String get materialEditTooltip => 'Edit Materi';

  @override
  String materialFormat(String format) {
    return 'Format: $format';
  }

  @override
  String get materialRecordingProgress => 'Mencatat Progres...';

  @override
  String get materialRecordedOpened => 'Tercatat Dibuka';

  @override
  String get materialNotSyncedTapRetry =>
      'Belum Tersinkron (Ketuk untuk coba lagi)';

  @override
  String get materialEmptyPlaceholder => 'Materi kosong.';

  @override
  String get materialInsertImageTitle => 'Sisipkan Gambar (URL Cloudinary)';

  @override
  String get materialInsertImageSecurityNote =>
      'Sesuai aturan keamanan Farlean LMS, gambar harus bersumber dari URL eksternal (Cloudinary). Gambar base64 dilarang.';

  @override
  String get materialImageUrlLabel => 'URL Gambar (https://...)';

  @override
  String get materialImageUrlRequired => 'URL gambar wajib diisi';

  @override
  String get materialImageBase64Forbidden => 'Gambar base64 inline dilarang.';

  @override
  String get materialImageUrlInvalid =>
      'URL harus diawali dengan http:// atau https://';

  @override
  String get materialInsertBtn => 'Sisipkan';

  @override
  String get materialTemplateOnlyEmpty =>
      'Template hanya dapat disisipkan pada editor kosong agar konten tidak tertimpa.';

  @override
  String get materialTemplateSuccess =>
      'Template materi berhasil disisipkan. Silakan lengkapi setiap bagian.';

  @override
  String materialTemplateFailed(String detail) {
    return 'Gagal menyisipkan template: $detail';
  }

  @override
  String get materialPreviewTitle => 'Pratinjau Materi';

  @override
  String get materialDiscardConfirmTitle => 'Buang Perubahan?';

  @override
  String get materialDiscardConfirmBody =>
      'Ada perubahan materi yang belum disimpan. Keluar sekarang akan membuang perubahan tersebut.';

  @override
  String get materialKeepEditingBtn => 'Lanjutkan Mengedit';

  @override
  String get materialDiscardChangesBtn => 'Buang Perubahan';

  @override
  String get materialTitleRequired => 'Judul materi wajib diisi.';

  @override
  String materialSavedAsStatus(String status) {
    return 'Materi berhasil disimpan sebagai $status.';
  }

  @override
  String materialSaveFailed(String detail) {
    return 'Gagal menyimpan materi: $detail';
  }

  @override
  String get materialCreateTitle => 'Buat Materi Baru';

  @override
  String get materialEditTitle => 'Edit Materi';

  @override
  String get materialPreviewTooltip => 'Pratinjau Tampilan Mahasiswa';

  @override
  String get materialPublishBtn => 'Publikasikan';

  @override
  String get materialTitleLabel => 'Judul Materi Pembelajaran';

  @override
  String get materialImageBtn => 'Gambar';

  @override
  String get materialTemplateBtn => 'Template';

  @override
  String materialCharCountDeltaJson(int count) {
    return '$count karakter • Format: Delta JSON';
  }

  @override
  String get materialEmptyWarning =>
      'Materi masih kosong. Tulis konten atau sisipkan template sebelum menyimpan.';

  @override
  String get materialEditorPlaceholder =>
      'Tuliskan materi pembelajaran terstruktur di sini...';

  @override
  String classDetailLoadFailed(String detail) {
    return 'Gagal memuat detail kelas: $detail';
  }

  @override
  String get classSaveMeetingBtn => 'Simpan Pertemuan';

  @override
  String get classArchiveConfirmTitle => 'Arsipkan Kelas?';

  @override
  String get classArchiveConfirmBody =>
      'Kelas yang diarsipkan akan terkunci untuk pengeditan dan tidak lagi menerima anggota baru. Anggota lama tetap dapat membaca materi.';

  @override
  String get classArchiveBtn => 'Arsipkan';

  @override
  String get classArchiveSuccess => 'Kelas berhasil diarsipkan.';

  @override
  String classArchiveFailed(String detail) {
    return 'Gagal mengarsipkan: $detail';
  }

  @override
  String get classReactivateConfirmTitle => 'Aktifkan Kembali Kelas?';

  @override
  String get classReactivateConfirmBody =>
      'Kelas yang diaktifkan kembali akan dapat menerima anggota baru serta mengizinkan pengelolaan pertemuan dan kuis seperti semula.';

  @override
  String get classReactivateBtn => 'Aktifkan';

  @override
  String get classReactivateSuccess => 'Kelas berhasil diaktifkan kembali.';

  @override
  String classReactivateFailed(String detail) {
    return 'Gagal mengaktifkan kembali kelas: $detail';
  }

  @override
  String get classDetailLoading => 'Memuat detail kelas...';

  @override
  String get classDetailTitle => 'Detail Kelas';

  @override
  String get classNotFound => 'Kelas tidak ditemukan.';

  @override
  String get classArchiveTooltip => 'Arsipkan Kelas';

  @override
  String get classReactivateTooltip => 'Aktifkan Kembali Kelas';

  @override
  String classCodeCopied(String code) {
    return 'Kode kelas $code disalin ke clipboard.';
  }

  @override
  String classMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Anggota',
    );
    return '$_temp0';
  }

  @override
  String classMeetingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '•  $count Pertemuan',
    );
    return '$_temp0';
  }

  @override
  String get classTabMeetings => 'Pertemuan';

  @override
  String get classTabGrades => 'Rekap Nilai';

  @override
  String get classTabMembers => 'Anggota Kelas';

  @override
  String get classEmptyMeetingOwnerDesc =>
      'Buat pertemuan baru untuk mulai mengisi materi, pretest, dan video pembelajaran.';

  @override
  String get classEmptyMeetingStudentDesc =>
      'Pengajar belum mempublikasikan pertemuan di kelas ini.';

  @override
  String get classCreateMeetingBtn => 'Buat Pertemuan';

  @override
  String get classGradebookRestrictedTitle => 'Akses Rekap Nilai Terbatas';

  @override
  String get classGradebookRestrictedBody =>
      'Sesuai kebijakan perlindungan data akademik Farlean LMS, hanya Pengajar Pemilik Kelas dan Admin yang memiliki wewenang untuk mengakses rekapitulasi nilai mahasiswa di kelas ini.';

  @override
  String get classGradebookNoStudents => 'Belum ada mahasiswa di kelas ini.';

  @override
  String get classGradebookAllMeetingsHint => 'Semua Pertemuan (Ringkasan)';

  @override
  String classMeetingNumberTitle(int number, String title) {
    return 'Pertemuan $number: $title';
  }

  @override
  String get classKpiPretestAvg => 'Rata-rata Pretest';

  @override
  String classKpiSubCount(int submitted, int total) {
    return '$submitted dari $total mahasiswa';
  }

  @override
  String get classKpiPosttestAvg => 'Rata-rata Post Test';

  @override
  String get classKpiTotalMeetings => 'Total Pertemuan';

  @override
  String classKpiQuizModulesCount(int count) {
    return '$count ber-modul kuis';
  }

  @override
  String get classKpiTotalStudents => 'Total Mahasiswa';

  @override
  String get classKpiEnrolledDesc => 'Terdaftar di kelas ini';

  @override
  String classPaginationInfo(int start, int end, int total) {
    return 'Menampilkan $start-$end dari $total mahasiswa';
  }

  @override
  String classQuizProgress(int done, int total) {
    return 'Progres Kuis: $done dari $total diselesaikan';
  }

  @override
  String get classQuizNoneDone =>
      'Belum ada kuis yang dikerjakan pada pertemuan mana pun.';

  @override
  String get classScoreNotAvailable => 'Belum Ada';

  @override
  String get classNoMeetings => 'Belum ada pertemuan di kelas ini.';

  @override
  String get classStudentProgressTitle => 'Hasil Capaian Belajar Anda';

  @override
  String classStudentProgressBody(String className) {
    return 'Menampilkan nilai resmi pretest & post test Anda pada kelas $className.';
  }

  @override
  String get classNoMembers => 'Belum ada anggota terdaftar di kelas ini.';

  @override
  String classMemberTypeStatus(String type, String status) {
    return 'Tipe: $type • Status: $status';
  }

  @override
  String get joinClassSuccessTitle => 'Berhasil Bergabung';

  @override
  String get joinClassPendingTitle => 'Menunggu Persetujuan';

  @override
  String joinClassStatusPrefix(String status) {
    return 'Status: $status';
  }

  @override
  String get joinClassOpenBtn => 'Buka Kelas';

  @override
  String get joinClassBackHomeBtn => 'Kembali ke Beranda';

  @override
  String joinClassSyncFailed(String detail) {
    return 'Gagal sinkronisasi data kelas: $detail';
  }

  @override
  String get joinClassAppBarTitle => 'Gabung Kelas';

  @override
  String get joinClassHeading => 'Masukkan Kode Kelas';

  @override
  String get joinClassDescription =>
      'Kode kelas terdiri dari 6-12 karakter alfanumerik. Mahasiswa/Dosen otomatis aktif, sedangkan akun Umum berstatus pending.';

  @override
  String get joinClassCodeLabel => 'Kode Kelas (misal: FARLEAN1)';

  @override
  String get joinClassSubmitBtn => 'Gabung Sekarang';

  @override
  String get discussionErrorPermissionStaff =>
      'Akses ditolak: Anda tidak memiliki wewenang untuk mengelola forum kelas ini.';

  @override
  String get discussionErrorPermissionStudent =>
      'Akses ditolak: Anda belum terdaftar sebagai anggota aktif di kelas ini.';

  @override
  String discussionErrorLoadFailed(String detail) {
    return 'Gagal memuat forum diskusi: $detail';
  }

  @override
  String get discussionSelectClassFirst =>
      'Pilih kelas terlebih dahulu untuk membuat diskusi.';

  @override
  String get discussionCreateTitle => 'Buat Diskusi Baru';

  @override
  String get discussionTitleLabel => 'Judul Diskusi *';

  @override
  String get discussionTitleHint => 'Misal: Tanya materi Bab 2...';

  @override
  String get discussionTitleMinLength => 'Judul minimal 3 karakter';

  @override
  String get discussionTitleMaxLength => 'Judul maksimal 200 karakter';

  @override
  String get discussionBodyLabel => 'Isi Pertanyaan / Topik Diskusi *';

  @override
  String get discussionBodyHint =>
      'Tuliskan pertanyaan atau topik dengan jelas...';

  @override
  String get discussionBodyMinLength => 'Isi diskusi minimal 3 karakter';

  @override
  String get discussionBodyMaxLength => 'Isi diskusi maksimal 5000 karakter';

  @override
  String get discussionSendBtn => 'Kirim Diskusi';

  @override
  String get discussionForumTitle => 'Forum Diskusi';

  @override
  String get discussionCreateFab => 'Buat Diskusi';

  @override
  String get discussionNoClassTitle => 'Pilih Kelas untuk Berdiskusi';

  @override
  String get discussionNoClassBody =>
      'Anda belum memilih kelas. Silakan bergabung ke kelas atau pilih kelas dari Beranda.';

  @override
  String get discussionLoading => 'Memuat diskusi kelas...';

  @override
  String get discussionFilterAll => 'Semua Diskusi';

  @override
  String get discussionFilterUnanswered => 'Belum Dibalas';

  @override
  String get discussionFilterUnread => 'Belum Dibaca';

  @override
  String get discussionEmptyAllTitle => 'Belum Ada Diskusi';

  @override
  String get discussionEmptyAllDesc =>
      'Jadilah yang pertama memulai tanya jawab dan ruang kolaborasi di kelas ini.';

  @override
  String get discussionEmptyUnansweredTitle =>
      'Tidak Ada Diskusi Belum Dibalas';

  @override
  String get discussionEmptyUnansweredDesc =>
      'Semua topik diskusi telah memiliki balasan dari pengajar atau sesama anggota.';

  @override
  String get discussionEmptyUnreadTitle => 'Semua Diskusi Sudah Dibaca';

  @override
  String get discussionEmptyUnreadDesc =>
      'Tidak ada aktivitas atau balasan baru yang belum Anda baca pada halaman ini.';

  @override
  String discussionReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Balasan',
    );
    return '$_temp0';
  }

  @override
  String get discussionNotFound =>
      'Diskusi tidak ditemukan atau telah dihapus.';

  @override
  String discussionLoadDetailFailed(String detail) {
    return 'Gagal memuat detail diskusi: $detail';
  }

  @override
  String get discussionArchivedSendBlocked =>
      'Diskusi ini telah diarsipkan. Pengiriman balasan dinonaktifkan.';

  @override
  String discussionSendReplyFailed(String detail) {
    return 'Gagal mengirim balasan: $detail';
  }

  @override
  String get discussionArchiveConfirmTitle => 'Arsipkan Diskusi?';

  @override
  String get discussionArchiveConfirmBody =>
      'Diskusi yang diarsipkan akan dikunci dari pengiriman balasan baru dan disembunyikan dari daftar anggota kelas.';

  @override
  String get discussionArchiveSuccess => 'Diskusi berhasil diarsipkan.';

  @override
  String discussionArchiveFailed(String detail) {
    return 'Gagal mengarsipkan: $detail';
  }

  @override
  String get discussionEditTitle => 'Edit Diskusi';

  @override
  String get discussionEditTitleLabel => 'Judul Diskusi';

  @override
  String get discussionEditBodyLabel => 'Isi Diskusi';

  @override
  String discussionUpdateFailed(String detail) {
    return 'Gagal update: $detail';
  }

  @override
  String get discussionArchiveReplyTooltip => 'Arsipkan Balasan';

  @override
  String get discussionReplyAction => 'Balas';

  @override
  String get discussionThreadLoading => 'Memuat thread diskusi...';

  @override
  String get discussionDetailTitle => 'Detail Diskusi';

  @override
  String get discussionEditTooltip => 'Edit Diskusi';

  @override
  String get discussionArchiveTooltip => 'Arsipkan Diskusi';

  @override
  String get discussionStatusArchivedTag => 'Status: Diarsipkan';

  @override
  String get discussionStatusActiveTag => 'Thread Diskusi Aktif';

  @override
  String discussionDetailReplyCount(int count) {
    return 'Balasan ($count)';
  }

  @override
  String get discussionNoRepliesYet => 'Belum ada tanggapan pada diskusi ini.';

  @override
  String discussionReplyingTo(String author, String snippet) {
    return 'Membalas @$author: \"$snippet\"';
  }

  @override
  String get discussionArchivedBanner =>
      'Diskusi diarsipkan. Pengiriman balasan dinonaktifkan.';

  @override
  String discussionReplyToHint(String author) {
    return 'Tulis balasan untuk @$author...';
  }

  @override
  String get discussionReplyGeneralHint => 'Tulis tanggapan atau balasan...';

  @override
  String get dashboardCreateClassTitle => 'Buat Kelas Baru';

  @override
  String get dashboardClassNameLabel => 'Nama Kelas';

  @override
  String get dashboardClassNameHint => 'Contoh: Pemrograman Mobile';

  @override
  String get dashboardClassNameMinLength => 'Nama kelas minimal 3 karakter';

  @override
  String get dashboardClassNameMaxLength => 'Nama kelas maksimal 100 karakter';

  @override
  String get dashboardClassDescLabel => 'Deskripsi (Opsional)';

  @override
  String get dashboardClassDescHint => 'Deskripsi singkat silabus kelas';

  @override
  String get dashboardClassCodeLabel => 'Kode Kelas Khusus (Opsional)';

  @override
  String get dashboardClassCodeHint => 'Kosongkan untuk kode acak 8 karakter';

  @override
  String get dashboardClassCodeLength => 'Kode harus 6-12 karakter';

  @override
  String get dashboardClassCodeAlphanumeric =>
      'Kode hanya huruf kapital dan angka';

  @override
  String get dashboardCreateClassBtn => 'Buat Kelas';

  @override
  String get dashboardClassCreatedSuccess => 'Kelas berhasil dibuat.';

  @override
  String get dashboardLoadingProfile => 'Memuat profil dan hak akses...';

  @override
  String get dashboardProfileErrorTitle => 'Profil Belum Berhasil Dimuat';

  @override
  String get dashboardProfileErrorNetwork =>
      'Koneksi ke database gagal. Periksa jaringan internet atau emulator Anda.';

  @override
  String get dashboardProfileErrorNotFound =>
      'Profil pengguna belum berhasil dimuat. Silakan tekan tombol Coba Lagi.';

  @override
  String get dashboardProfileErrorPermission =>
      'Akses ditolak saat membaca profil.';

  @override
  String get dashboardProfileErrorDefault =>
      'Terjadi kendala saat menyinkronkan profil Anda dari server. Silakan coba lagi.';

  @override
  String get dashboardLoadingClasses => 'Memuat kelas Anda...';

  @override
  String get dashboardWelcomeBadge => 'Farlean LMS • Multi-Class Active';

  @override
  String get dashboardWelcomeTitle => 'Selamat Datang di Farlean LMS';

  @override
  String get dashboardWelcomeBody =>
      'Akses materi terstruktur, kuis pretest berpenilaian server, video pembelajaran, dan forum belajar dalam satu platform.';

  @override
  String get dashboardRoleOutOfSyncTitle => 'Peran Akun Belum Sinkron';

  @override
  String dashboardRoleOutOfSyncBody(String claimsRole, String profileRole) {
    return 'Token: $claimsRole vs Profil: $profileRole. Tekan Perbarui untuk menyelaraskan hak akses.';
  }

  @override
  String get dashboardRefreshRoleBtn => 'Perbarui';

  @override
  String get dashboardManagedClassesSection => 'Kelas yang Anda Kelola';

  @override
  String get dashboardEmptyOwnedTitle => 'Belum ada kelas yang Anda kelola.';

  @override
  String get dashboardEmptyOwnedBody =>
      'Buat kelas baru untuk mulai mengunggah materi dan membuat pertemuan.';

  @override
  String get dashboardCreateFirstClassBtn => 'Buat Kelas Pertama';

  @override
  String get dashboardJoinedClassesSection => 'Kelas yang Anda Ikuti';

  @override
  String get dashboardJoinCodeBtn => 'Gabung Kode';

  @override
  String get dashboardEmptyJoinedTitle =>
      'Belum tergabung ke kelas pembelajaran.';

  @override
  String get dashboardEmptyJoinedBody =>
      'Minta kode kelas dari Dosen/Pengajar Anda untuk bergabung ke kelas.';

  @override
  String dashboardCodeCopied(String code) {
    return 'Kode $code disalin.';
  }

  @override
  String dashboardMeetingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Pertemuan',
    );
    return '$_temp0';
  }

  @override
  String get dashboardManageClassBtn => 'Kelola Kelas';

  @override
  String get dashboardOpenClassBtn => 'Buka Kelas';

  @override
  String get navSelectClassFirst =>
      'Pilih salah satu kelas terlebih dahulu untuk melihat pertemuan & materi.';

  @override
  String get navMaterials => 'Materi';

  @override
  String get navAiTutor => 'AI Tutor';

  @override
  String get navDiscussion => 'Diskusi';
}

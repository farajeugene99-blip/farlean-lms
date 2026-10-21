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
  String get authBtnGoogleSignIn => 'Masuk dengan Google';

  @override
  String get authBtnGoogleSignUp => 'Daftar dengan Google';

  @override
  String get authOrDivider => 'atau';

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
  String get meetingModuleAssignmentTitle => 'Tugas Pembelajaran';

  @override
  String get meetingModuleAssignmentSubActive =>
      'Tugas pertemuan dengan tenggat dan instruksi terstruktur';

  @override
  String get meetingModuleAssignmentSubStaffEmpty =>
      'Tugas belum ditautkan. Klik untuk membuat tugas baru.';

  @override
  String get meetingModuleAssignmentSubStudentEmpty =>
      'Belum ada tugas pembelajaran untuk pertemuan ini';

  @override
  String get meetingModuleAssignmentActionOpen => 'Buka Tugas';

  @override
  String get meetingModuleAssignmentActionCreate => 'Buat Tugas';

  @override
  String get meetingModuleAssignment => 'Tugas';

  @override
  String get assignmentInstructionAttachment => 'Berkas Lampiran Petunjuk';

  @override
  String get assignmentDownloadInstruction => 'Unduh Petunjuk';

  @override
  String get assignmentViewInstruction => 'Buka Petunjuk';

  @override
  String get assignmentNoInstructionAttachment =>
      'Tidak ada berkas lampiran petunjuk';

  @override
  String get profileCacheDiskTitle => 'Berkas Sementara (Disk)';

  @override
  String get profileCacheRamTitle => 'Cache Memori (RAM)';

  @override
  String get profileCacheCleanSuccess =>
      'Cache dan berkas sementara berhasil dibersihkan';

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
  String get meetingVideoUrlInvalid => 'URL harus diawali https://';

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
  String get materialImageUrlInvalid => 'URL harus diawali dengan https://';

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
  String get materialAttachFileBtn => 'Lampirkan Berkas';

  @override
  String get materialPickImageDevice => 'Pilih dari Perangkat';

  @override
  String get materialAttachmentSuccess => 'Berkas berhasil dilampirkan';

  @override
  String get materialAttachmentsTitle => 'Berkas Lampiran Materi';

  @override
  String get materialAttachmentOpen => 'Buka Berkas';

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

  @override
  String get manualBookErrorPermissionStaff =>
      'Akses ditolak: Anda tidak memiliki wewenang untuk melihat berkas panduan kelas ini.';

  @override
  String get manualBookErrorPermissionStudent =>
      'Akses ditolak: Anda belum terdaftar sebagai anggota aktif di kelas ini.';

  @override
  String manualBookErrorLoadFailed(String detail) {
    return 'Gagal memuat manual book: $detail';
  }

  @override
  String get manualBookOpenPdfFailed => 'Tidak dapat membuka tautan PDF.';

  @override
  String manualBookOpenPdfError(String detail) {
    return 'Error membuka berkas: $detail';
  }

  @override
  String get manualBookSelectClassFirst =>
      'Pilih kelas yang valid terlebih dahulu untuk mengunggah buku panduan.';

  @override
  String get manualBookAddTitle => 'Tambah Manual Book';

  @override
  String get manualBookTitleLabel => 'Judul Panduan';

  @override
  String get manualBookTitleRequired => 'Judul wajib diisi';

  @override
  String get manualBookDescLabel => 'Deskripsi Singkat';

  @override
  String get manualBookUrlLabel => 'URL Berkas Cloudinary (PDF)';

  @override
  String get manualBookUrlRequired => 'URL berkas wajib diisi';

  @override
  String get manualBookUrlInvalid => 'URL harus diawali https://';

  @override
  String get manualBookFileNameLabel => 'Nama Berkas (.pdf)';

  @override
  String get manualBookAppBarTitle => 'Buku Panduan (Manual Book)';

  @override
  String get manualBookNoClassBody =>
      'Anda belum memilih kelas. Silakan bergabung menggunakan kode kelas atau pilih kelas dari Beranda untuk mengakses Buku Panduan.';

  @override
  String get manualBookJoinNewClassBtn => 'Gabung Kelas Baru';

  @override
  String get manualBookLoading => 'Memuat buku panduan...';

  @override
  String get manualBookEmptyTitle => 'Belum Ada Buku Panduan';

  @override
  String get manualBookEmptyBody =>
      'Pengajar belum menambahkan buku panduan (Manual Book) PDF untuk kelas ini.';

  @override
  String get manualBookNoDescription => 'Tidak ada deskripsi';

  @override
  String get manualBookOpenPdfBtn => 'Buka Dokumen PDF';

  @override
  String get profileThemeTitle => 'Tema Tampilan';

  @override
  String get profileThemeSubtitle =>
      'Atur tema terang, gelap, atau ikuti sistem';

  @override
  String get themeModeLight => 'Terang';

  @override
  String get themeModeDark => 'Gelap';

  @override
  String get themeModeSystem => 'Ikuti Sistem';

  @override
  String get profileLanguageTitle => 'Bahasa Aplikasi';

  @override
  String get profileLanguageSubtitle => 'Pilih bahasa antarmuka aplikasi';

  @override
  String get languageId => 'Bahasa Indonesia';

  @override
  String get languageEn => 'English';

  @override
  String quizQuestionOf(int current, int total) {
    return 'Soal $current dari $total';
  }

  @override
  String quizPoints(int points) {
    return '$points Poin';
  }

  @override
  String get quizBtnPrev => 'Sebelumnya';

  @override
  String get quizBtnNext => 'Selanjutnya';

  @override
  String get quizBtnSubmit => 'Kumpulkan';

  @override
  String get quizGateLockedTitle => 'Akses Pretest Terkunci';

  @override
  String get quizGateLockedDesc =>
      'Sesuai ketentuan alur pembelajaran Farlean LMS, Anda harus membuka dan membaca materi pembelajaran pertemuan ini terlebih dahulu sebelum diperkenankan mengerjakan pretest.\n\nJika sebelumnya Anda sudah pernah membuka materi, ketuk tombol di bawah untuk membuka kembali materi agar progres kehadiran tersinkronisasi secara resmi ke server.';

  @override
  String get quizGateOpenMaterialBtn => 'Buka Materi Pembelajaran';

  @override
  String get quizGateBackToMeetingBtn => 'Kembali ke Pertemuan';

  @override
  String get quizConfirmSubmitTitle => 'Kumpulkan Jawaban?';

  @override
  String get quizConfirmSubmitBody =>
      'Apakah Anda yakin ingin mengumpulkan kuis ini? Pastikan seluruh soal telah Anda jawab dengan seksama.';

  @override
  String get quizSubmitting => 'Mengumpulkan...';

  @override
  String get quizSubmitSuccessTitle => 'Kuis Selesai Dinilai';

  @override
  String quizSubmitSuccessBody(String score, int earned, int total) {
    return 'Nilai resmi Anda: $score ($earned/$total poin).\nNilai terbaik Anda telah diperbarui di server.';
  }

  @override
  String get quizConnErrorTitle => 'Koneksi Terputus';

  @override
  String get quizConnErrorBody =>
      'Koneksi jaringan terputus. Status penilaian kuis saat ini tidak dapat dipastikan dari server. Harap periksa koneksi internet Anda dan coba kembali.';

  @override
  String get quizDeadlineExpiredTitle => 'Batas Waktu Berakhir';

  @override
  String get quizDeadlineExpiredBody =>
      'Batas waktu pengerjaan (deadline) kuis telah berakhir. Sesi pengerjaan kuis telah dikunci oleh server.';

  @override
  String get quizUnderstand => 'Mengerti';

  @override
  String get quizDraftBlockedMessage =>
      'Kuis ini masih berstatus Draft dan belum dibuka oleh pengajar.';

  @override
  String videoProviderLabel(String provider) {
    return 'Penyedia: $provider';
  }

  @override
  String videoDurationLabel(int minutes, int seconds) {
    return 'Durasi: ${minutes}m ${seconds}s';
  }

  @override
  String get videoIntegratedTitle => 'Video Materi Terintegrasi';

  @override
  String videoSourceUrlLabel(String url) {
    return 'URL Sumber: $url';
  }

  @override
  String get videoStorageNote =>
      'Video ini di-stream langsung tanpa disimpan di Firebase Storage untuk efisiensi penyimpanan sesuai arsitektur Blueprint.';

  @override
  String videoLoadFailed(String error) {
    return 'Gagal memuat video: $error';
  }

  @override
  String meetingLockedUntilPublish(String date) {
    return 'Pertemuan ini dijadwalkan terbit pada $date. Seluruh modul terkunci hingga waktu tersebut.';
  }

  @override
  String get quizGateMateriNotOpened => 'Materi Belum Dibuka';

  @override
  String get quizTimeUpAutosaved =>
      'Waktu pengerjaan telah habis. Jawaban Anda disimpan otomatis.';

  @override
  String get quizTimeUpAutosubmitted =>
      'Waktu pengerjaan telah habis. Jawaban dikumpulkan otomatis.';

  @override
  String quizSubmitFailed(String error) {
    return 'Gagal mengumpulkan kuis: $error';
  }

  @override
  String get quizPendingEvaluationTitle => 'Penilaian Tertunda';

  @override
  String get quizPendingEvaluationBody =>
      'Koneksi ke server penilaian terputus, namun sesi kuis Anda masih aktif di server. Jawaban lokal Anda telah tersimpan otomatis. Silakan tekan tombol Kirim Kuis untuk mencoba kembali.';

  @override
  String quizConfirmUnansweredBody(int unanswered) {
    return 'Terdapat $unanswered soal yang belum Anda jawab. Jawaban yang sudah dikumpulkan tidak dapat diubah lagi.';
  }

  @override
  String get quizPretestLoading => 'Mempersiapkan kuis pretest...';

  @override
  String get quizPretestLoadFailed => 'Gagal memuat pretest.';

  @override
  String get quizPosttestLoading => 'Mempersiapkan sesi post test...';

  @override
  String get quizPosttestUnavailable => 'Kuis post test tidak tersedia.';

  @override
  String get quizNoQuestionsConfigured =>
      'Belum ada soal yang dikonfigurasi untuk post test ini.';

  @override
  String quizPosttestLoadFailed(String error) {
    return 'Gagal memuat kuis post test: $error';
  }

  @override
  String quizFinalScore(String score) {
    return 'Skor Akhir: $score';
  }

  @override
  String quizPointsEarned(String earned, String total) {
    return 'Poin diperoleh: $earned dari $total poin';
  }

  @override
  String get quizPretestAnswersLocked =>
      'Jawaban Anda telah tersimpan dengan aman dan sesi kuis telah dikunci.';

  @override
  String get quizPosttestAnswersLocked =>
      'Jawaban Anda telah dikunci dan skor evaluasi pembelajaran telah tercatat di server.';

  @override
  String get quizSessionNotActive => 'Sesi Anda belum aktif.';

  @override
  String get quizNotFound => 'Kuis pretest tidak ditemukan.';

  @override
  String get quizPosttestNotFound => 'Kuis post test tidak ditemukan.';

  @override
  String quizDraftBlocked(String status) {
    return 'Kuis pretest masih berstatus $status dan belum dibuka.';
  }

  @override
  String get quizInvalidClassMeeting =>
      'Kuis tidak terhubung dengan kelas atau pertemuan yang valid.';

  @override
  String get quizInvalidClass =>
      'Kuis post test tidak terhubung dengan kelas yang valid.';

  @override
  String get quizNoQuestionsUploaded =>
      'Soal kuis belum diunggah oleh pengajar.';

  @override
  String get quizStaleSessionEnded =>
      'Sesi pengerjaan sebelumnya telah berakhir sebelum jawaban dikumpulkan.';

  @override
  String quizMaxAttemptsReached(String attempts) {
    return 'Anda telah mencapai batas maksimal percobaan (${attempts}x).';
  }

  @override
  String quizPosttestMaxAttemptsReached(String count, String max) {
    return 'Anda telah mencapai batas maksimal percobaan ($count/$max).';
  }

  @override
  String quizLoadFailedGeneric(String error) {
    return 'Gagal memuat sesi kuis: $error';
  }

  @override
  String get videoLoadingPlayer => 'Memuat pemutar video...';

  @override
  String get videoNotFound => 'Video pembelajaran tidak ditemukan.';

  @override
  String get videoYoutubeUrlInvalid => 'URL video YouTube tidak valid.';

  @override
  String videoPlaybackFailed(String error) {
    return 'Gagal memutar video Cloudinary: $error';
  }

  @override
  String get startupFirebaseInitFailed => 'Inisialisasi Firebase Gagal';

  @override
  String get dashboardManualBookTitle => 'Buku Panduan LMS';

  @override
  String get dashboardManualBookDesc =>
      'Akses panduan sistem Farlean LMS untuk mahasiswa dan pengajar';

  @override
  String get dashboardManualBookAdminBadge => 'Dikelola Admin';

  @override
  String get manualBookSystemTitle => 'Buku Panduan Sistem';

  @override
  String get manualBookSystemEmpty =>
      'Belum ada buku panduan sistem yang dipublikasikan oleh Administrator.';

  @override
  String get manualBookOnlyAdminCanManage =>
      'Hanya Admin yang berhak mengelola buku panduan sistem global.';

  @override
  String get tabGroups => 'Kelompok';

  @override
  String get groupsEmptyTitle => 'Belum Ada Kelompok';

  @override
  String get groupsEmptyDesc =>
      'Dosen dapat membuat kelompok mahasiswa untuk kegiatan tugas dan diskusi kelompok.';

  @override
  String get groupsCreateBtn => 'Buat Kelompok';

  @override
  String get groupsCreateTitle => 'Buat Kelompok Baru';

  @override
  String get groupsNameLabel => 'Nama Kelompok';

  @override
  String get groupsNameHint => 'Contoh: Kelompok 1 - Pemrograman Mobile';

  @override
  String get groupsNameRequired => 'Nama kelompok wajib diisi';

  @override
  String groupsSelectMembersTitle(int count) {
    return 'Pilih Anggota ($count terpilih)';
  }

  @override
  String get groupsNoAvailableMembers =>
      'Semua mahasiswa aktif di kelas ini sudah memiliki kelompok.';

  @override
  String groupsMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count anggota',
      one: '1 anggota',
      zero: 'Belum ada anggota',
    );
    return '$_temp0';
  }

  @override
  String get groupsDeleteConfirmTitle => 'Hapus Kelompok?';

  @override
  String groupsDeleteConfirmDesc(String name) {
    return 'Kelompok \'$name\' akan dihapus dan anggotanya akan kembali belum memiliki kelompok.';
  }

  @override
  String get groupsDeleteSuccess => 'Kelompok berhasil dihapus';

  @override
  String get groupsCreateSuccess => 'Kelompok berhasil dibuat';

  @override
  String get groupsLeaderLabel => 'Ketua Kelompok';

  @override
  String get groupsSetLeader => 'Pilih Sebagai Ketua';

  @override
  String get groupsLoading => 'Memuat data kelompok...';

  @override
  String get groupsEditTitle => 'Ubah Kelompok';

  @override
  String get groupsEditSuccess => 'Kelompok berhasil diperbarui';

  @override
  String get tabAssignments => 'Tugas';

  @override
  String assignmentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tugas',
      one: '1 tugas',
      zero: 'Belum ada tugas',
    );
    return '$_temp0';
  }

  @override
  String get assignmentEmptyTitle => 'Belum Ada Tugas';

  @override
  String get assignmentEmptyDesc =>
      'Pengajar belum memberikan tugas untuk kelas ini.';

  @override
  String get assignmentCreateBtn => 'Buat Tugas';

  @override
  String get assignmentCreateTitle => 'Buat Tugas Baru';

  @override
  String get assignmentTitleLabel => 'Judul Tugas';

  @override
  String get assignmentTitleRequired => 'Judul tugas wajib diisi';

  @override
  String get assignmentInstructionsLabel => 'Petunjuk Pengerjaan';

  @override
  String get assignmentDeadlineLabel => 'Batas Waktu (Deadline)';

  @override
  String get assignmentAllowLateLabel => 'Izinkan Pengumpulan Terlambat';

  @override
  String get assignmentIsGroupLabel => 'Tugas Kelompok';

  @override
  String get assignmentIndividualBadge => 'Individu';

  @override
  String get assignmentGroupBadge => 'Kelompok';

  @override
  String get assignmentStatusSubmitted => 'Dikumpulkan';

  @override
  String get assignmentStatusLate => 'Terlambat';

  @override
  String get assignmentStatusGraded => 'Sudah Dinilai';

  @override
  String get assignmentStatusNotSubmitted => 'Belum Mengumpulkan';

  @override
  String get assignmentSubmitBtn => 'Kumpulkan Tugas';

  @override
  String get assignmentResubmitBtn => 'Kumpulkan Ulang';

  @override
  String get assignmentFileLabel => 'Berkas Tugas (PDF, DOCX, ZIP)';

  @override
  String assignmentUploadFailed(String error) {
    return 'Gagal mengunggah berkas: $error';
  }

  @override
  String get assignmentSubmitSuccess => 'Tugas berhasil dikumpulkan!';

  @override
  String get assignmentGradeBtn => 'Beri Nilai';

  @override
  String get assignmentGradeTitle => 'Penilaian Tugas';

  @override
  String get assignmentScoreLabel => 'Nilai (0 - 100)';

  @override
  String get assignmentFeedbackLabel => 'Catatan / Umpan Balik';

  @override
  String get assignmentGradedSuccess => 'Nilai berhasil disimpan';

  @override
  String get assignmentNoGroupWarning =>
      'Anda belum tergabung dalam kelompok mana pun di kelas ini. Hubungi pengajar untuk dimasukkan ke kelompok sebelum mengumpulkan tugas kelompok.';

  @override
  String get assignmentDeadlinePassedLocked =>
      'Batas waktu pengumpulan telah berakhir dan pengajar tidak mengizinkan pengumpulan terlambat.';

  @override
  String assignmentSubmissionsCount(int count) {
    return '$count Pengumpulan';
  }

  @override
  String get assignmentDetailTitle => 'Detail Tugas';

  @override
  String get assignmentDeleteConfirmTitle => 'Hapus Tugas?';

  @override
  String assignmentDeleteConfirmDesc(String title) {
    return 'Tugas \'$title\' dan seluruh pengumpulan mahasiswa akan dihapus permanen.';
  }

  @override
  String get assignmentDeleteSuccess => 'Tugas berhasil dihapus';

  @override
  String discussionShowReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lihat $count balasan',
      one: 'Lihat 1 balasan',
    );
    return '$_temp0';
  }

  @override
  String get discussionHideReplies => 'Sembunyikan balasan';

  @override
  String get materialExportPdfTooltip => 'Unduh Materi sebagai PDF';

  @override
  String get materialExportingPdf => 'Menyiapkan dokumen PDF...';

  @override
  String get materialExportPdfSuccess => 'Dokumen PDF berhasil dibuat';

  @override
  String materialExportPdfFailed(String error) {
    return 'Gagal membuat PDF: $error';
  }

  @override
  String get aiTutorTitle => 'AI Tutor Pintar';

  @override
  String get aiTutorSubtitle =>
      'Asisten belajar cerdas bimbingan konsep pembelajaran';

  @override
  String get aiTutorHint =>
      'Tanyakan konsep materi, rumus, atau logika pemrograman...';

  @override
  String get aiTutorWelcome =>
      'Halo! Saya Farlean AI Tutor. Ada konsep materi pembelajaran yang ingin kamu diskusikan hari ini?';

  @override
  String get aiTutorPromptEmpty => 'Pertanyaan tidak boleh kosong';

  @override
  String get aiTutorExamLocked =>
      'Fitur AI Tutor dinonaktifkan sementara saat Anda sedang menempuh sesi kuis/ujian.';

  @override
  String get aiVideoDraftBtn => 'Bantu Buat Draf (AI)';

  @override
  String get aiVideoDrafting => 'Menyusun draf deskripsi dengan AI...';

  @override
  String get aiVideoDraftSuccess =>
      'Draf deskripsi berhasil dibuat! Anda dapat mengedit sebelum menyimpan.';

  @override
  String get videoEditTitle => 'Edit Video Pembelajaran';

  @override
  String get videoTitleLabel => 'Judul Video';

  @override
  String get videoDescLabel => 'Deskripsi Video';

  @override
  String get videoEditSuccess => 'Informasi video berhasil diperbarui';

  @override
  String get classPendingTitle => 'Pendaftaran Menunggu Persetujuan';

  @override
  String get classPendingBody =>
      'Permintaan Anda untuk bergabung ke kelas ini telah dikirim dan sedang menunggu konfirmasi dari Dosen Pengampu.';

  @override
  String get classPendingBackBtn => 'Kembali ke Beranda';
}

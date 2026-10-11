import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_user.dart';
import '../../repositories/attempt_repository.dart';
import '../../repositories/user_repository.dart';
import '../../services/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/class_provider.dart';
import 'main_shell.dart';

class ProfileScreen extends StatefulWidget {
  final UserRepository? userRepository;
  final AttemptRepository? attemptRepository;

  const ProfileScreen({
    super.key,
    this.userRepository,
    this.attemptRepository,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final UserRepository _userRepository;
  late final AttemptRepository _attemptRepository;
  String? _nimNip;
  bool _isLoadingIdentity = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _userRepository = widget.userRepository ?? UserRepository();
    _attemptRepository = widget.attemptRepository ?? AttemptRepository();
    _loadPrivateIdentity();
  }

  Future<void> _loadPrivateIdentity() async {
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.firebaseUser?.uid;
    if (uid == null) return;

    setState(() => _isLoadingIdentity = true);
    try {
      final identity = await _userRepository.getPrivateIdentity(uid);
      if (mounted) {
        setState(() {
          _nimNip = identity;
          _isLoadingIdentity = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingIdentity = false);
    }
  }

  Future<void> _showEditNameDialog(String currentName) async {
    final controller = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Nama Lengkap'),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nama Lengkap'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Nama wajib diisi';
                if (v.trim().length > 100) return 'Maksimal 100 karakter';
                return null;
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final authProvider = context.read<AuthProvider>();
              final uid = authProvider.firebaseUser?.uid;
              if (uid == null) return;

              try {
                await _userRepository.updateName(uid, controller.text.trim());
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Gagal memperbarui nama: $e'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    ).whenComplete(() {
      controller.dispose();
    });

    if (updated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama profil berhasil diperbarui.'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  Future<void> _showEditNimDialog(String label) async {
    final controller = TextEditingController(text: _nimNip ?? '');
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Nomor Induk ($label)'),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data ini disimpan di sub-koleksi private/identity yang terisolasi dan hanya dapat diakses oleh Anda dan Admin. Pengajar kelas Anda melihatnya hanya melalui rekap resmi, bukan dari aplikasi.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: label,
                    prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return '$label wajib diisi';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final authProvider = context.read<AuthProvider>();
              final uid = authProvider.firebaseUser?.uid;
              if (uid == null) return;

              try {
                await _userRepository.setPrivateIdentity(uid, controller.text.trim());
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menyimpan $label: $e'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    ).whenComplete(() {
      controller.dispose();
    });

    if (updated == true && mounted) {
      setState(() => _nimNip = controller.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label berhasil disimpan di private identity.'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final updated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _ChangePasswordDialog(
        userEmail: context.read<AuthProvider>().firebaseUser?.email,
        onSave: ({required currentPassword, required newPassword}) {
          return context.read<AuthProvider>().changePassword(
                currentPassword: currentPassword,
                newPassword: newPassword,
              );
        },
        onResetPassword: (email) {
          return context.read<AuthProvider>().sendPasswordReset(email);
        },
      ),
    );

    if (updated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kata sandi berhasil diperbarui untuk akun ini.'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  Future<void> _showCacheManagementDialog() async {
    final classProvider = context.read<ClassProvider>();
    final selectedClass = classProvider.selectedClass;
    final selectedClassId = classProvider.selectedClassId;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final cacheBytes = PaintingBinding.instance.imageCache.currentSizeBytes;
            final cacheCount = PaintingBinding.instance.imageCache.currentSize;
            final cacheText = cacheBytes == 0
                ? '0 KB (belum ada gambar dimuat di memori)'
                : '${(cacheBytes / 1024).toStringAsFixed(1)} KB ($cacheCount gambar aktif di memori)';

            final activeClassText = selectedClass != null
                ? '${selectedClass.name} (${selectedClass.code})'
                : (selectedClassId != null && selectedClassId.isNotEmpty
                    ? 'ID: $selectedClassId'
                    : 'Belum ada kelas aktif yang dipilih');

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.storage_rounded, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Text('Penyimpanan & Cache'),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kelola memori sementara gambar dan preferensi kelas aktif di perangkat ini secara aman.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      // Bagian 1: Cache Gambar RAM
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.image_outlined, size: 16, color: AppTheme.secondary),
                                SizedBox(width: 6),
                                Text(
                                  'Cache Gambar di Memori (RAM)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              cacheText,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Catatan: Cache memori menampung gambar materi yang sedang dibuka. Mengosongkannya aman dan gambar akan diunduh kembali saat dibuka.',
                              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: cacheBytes == 0
                                  ? null
                                  : () {
                                      PaintingBinding.instance.imageCache.clear();
                                      PaintingBinding.instance.imageCache.clearLiveImages();
                                      setDialogState(() {});
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Cache memori gambar berhasil dikosongkan.'),
                                          backgroundColor: AppTheme.success,
                                        ),
                                      );
                                    },
                              icon: const Icon(Icons.cleaning_services_outlined, size: 16),
                              label: const Text('Kosongkan Cache Gambar RAM', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Bagian 2: Pilihan Kelas Aktif
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.class_outlined, size: 16, color: AppTheme.primary),
                                SizedBox(width: 6),
                                Text(
                                  'Pilihan Kelas Aktif Tersimpan',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              activeClassText,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Mereset kelas aktif akan mengarahkan Anda ke Beranda untuk memilih kembali kelas pembelajaran.',
                              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error),
                              onPressed: (selectedClassId == null || selectedClassId.isEmpty)
                                  ? null
                                  : () async {
                                      // Guard Kuis Aktif: Periksa attempt aktif terlebih dahulu
                                      final authProvider = context.read<AuthProvider>();
                                      final uid = authProvider.firebaseUser?.uid;
                                      if (uid != null && uid.isNotEmpty) {
                                        try {
                                          final hasActive = await _attemptRepository.hasActiveOngoingAttempt(userId: uid);
                                          if (hasActive) {
                                            if (dialogCtx.mounted) {
                                              await showDialog<void>(
                                                context: dialogCtx,
                                                builder: (c) => AlertDialog(
                                                  title: const Row(
                                                    children: [
                                                      Icon(Icons.warning_amber_rounded, color: AppTheme.error),
                                                      SizedBox(width: 8),
                                                      Text('Kuis Sedang Dikerjakan'),
                                                    ],
                                                  ),
                                                  content: const Text(
                                                    'Tidak dapat mereset kelas aktif: Anda sedang memiliki kuis yang sedang dikerjakan. Selesaikan atau kumpulkan kuis terlebih dahulu sebelum mereset kelas.',
                                                  ),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(c), child: const Text('Mengerti')),
                                                  ],
                                                ),
                                              );
                                            }
                                            return;
                                          }
                                        } catch (_) {
                                          // Jika pemeriksaan gagal / offline, blokir reset kelas demi keselamatan pengerjaan kuis
                                          if (dialogCtx.mounted) {
                                            await showDialog<void>(
                                              context: dialogCtx,
                                              builder: (c) => AlertDialog(
                                                title: const Row(
                                                  children: [
                                                    Icon(Icons.wifi_off_rounded, color: AppTheme.warning),
                                                    SizedBox(width: 8),
                                                    Text('Perangkat Offline'),
                                                  ],
                                                ),
                                                content: const Text(
                                                  'Tidak dapat memverifikasi status kuis karena perangkat sedang offline. Untuk keamanan jawaban kuis Anda, reset kelas aktif ditunda hingga perangkat terhubung kembali.',
                                                ),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(c), child: const Text('Mengerti')),
                                                ],
                                              ),
                                            );
                                          }
                                          return;
                                        }
                                      }

                                      // Konfirmasi reset kelas aktif
                                      if (!dialogCtx.mounted) return;
                                      final confirm = await showDialog<bool>(
                                        context: dialogCtx,
                                        builder: (c) => AlertDialog(
                                          title: const Text('Reset Pilihan Kelas?'),
                                          content: const Text('Anda akan diarahkan kembali ke Beranda untuk memilih kelas pembelajaran.'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
                                            ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Reset')),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await classProvider.selectClass(null);
                                        MainShell.activeClassId = null;
                                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                                        if (mounted) {
                                          try {
                                            context.go(AppConstants.dashboardRoute);
                                          } catch (_) {}
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Pilihan kelas aktif berhasil direset.'),
                                              backgroundColor: AppTheme.success,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              icon: const Icon(Icons.restart_alt_rounded, size: 16),
                              label: const Text('Reset Pilihan Kelas Aktif', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Tutup'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmAndSignOut() async {
    if (_isLoggingOut) return;

    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.firebaseUser?.uid;

    String? quizWarning;

    if (uid != null && uid.isNotEmpty) {
      try {
        final hasActive = await _attemptRepository.hasActiveOngoingAttempt(userId: uid);
        if (hasActive) {
          quizWarning =
              'Perhatian: Anda memiliki kuis yang sedang dikerjakan. Jika Anda keluar sekarang, pengerjaan kuis dapat terganggu dan jawaban yang belum tersimpan dapat hilang.';
        }
      } catch (e) {
        if (e is FirebaseException && e.code == 'permission-denied') {
          // Aturan rules menolak pemeriksaan, jangan tampilkan peringatan offline palsu
        } else {
          quizWarning =
              'Tidak dapat memverifikasi status kuis karena perangkat sedang offline. Jika Anda sedang mengerjakan kuis, jawaban yang belum tersinkronisasi ke server mungkin hilang.';
        }
      }
    }

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isDialogLoggingOut = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return PopScope(
              canPop: !isDialogLoggingOut,
              child: AlertDialog(
                title: Row(
                  children: [
                    Icon(
                      quizWarning != null ? Icons.warning_amber_rounded : Icons.logout_rounded,
                      color: quizWarning != null ? AppTheme.warning : AppTheme.error,
                    ),
                    const SizedBox(width: 8),
                    const Text('Keluar dari Akun?'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (quizWarning != null) ...[
                      Text(
                        quizWarning,
                        style: const TextStyle(
                          color: AppTheme.error,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const Text(
                      'Apakah Anda yakin ingin keluar dari sesi Farlean LMS di perangkat ini?',
                      style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: isDialogLoggingOut ? null : () => Navigator.pop(dialogContext, false),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                    onPressed: isDialogLoggingOut
                        ? null
                        : () {
                            setDialogState(() => isDialogLoggingOut = true);
                            Navigator.pop(dialogContext, true);
                          },
                    child: isDialogLoggingOut
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Keluar'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoggingOut = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      try {
        await context.read<ClassProvider>().clear();
      } catch (_) {}
      MainShell.activeClassId = null;
      await authProvider.signOut();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal keluar akun: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final firebaseUser = authProvider.firebaseUser;
    final appUser = authProvider.appUser;

    final displayName = appUser?.name ?? firebaseUser?.displayName ?? 'Pengguna Farlean';
    final email = firebaseUser?.email ?? appUser?.email ?? '-';
    final accountType = appUser?.accountType.value ?? 'UMUM';
    final role = appUser?.role.value ?? 'USER';
    final isVerified = firebaseUser?.emailVerified ?? false;

    final String? identityLabel;
    if (appUser == null) {
      identityLabel = null;
    } else if (appUser.accountType == AccountType.mahasiswa) {
      identityLabel = 'NIM';
    } else if (appUser.accountType == AccountType.dosen) {
      identityLabel = 'NIP';
    } else {
      identityLabel = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
            onPressed: _isLoggingOut ? null : _confirmAndSignOut,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppTheme.primary.withAlpha(30),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 40,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: 'Ubah Nama',
                        onPressed: () => _showEditNameDialog(displayName),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildBadge('Tipe: $accountType', AppTheme.primary),
                      _buildBadge('Role: $role', AppTheme.secondary),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                if (identityLabel != null) ...[
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: Text('Nomor Induk ($identityLabel)'),
                    subtitle: Text(
                      _isLoadingIdentity
                          ? 'Memuat...'
                          : (_nimNip != null && _nimNip!.isNotEmpty
                              ? _nimNip!
                              : 'Belum diisi (Klik untuk menambahkan)'),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _showEditNimDialog(identityLabel!),
                    ),
                  ),
                  const Divider(height: 1),
                ],
                if (authProvider.hasPasswordProvider) ...[
                  ListTile(
                    leading: const Icon(Icons.lock_outline_rounded),
                    title: const Text('Keamanan & Kata Sandi'),
                    subtitle: const Text('Ubah kata sandi akun untuk perangkat ini'),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                    onTap: _showChangePasswordDialog,
                  ),
                  const Divider(height: 1),
                ],
                ListTile(
                  leading: const Icon(Icons.storage_rounded),
                  title: const Text('Penyimpanan & Cache'),
                  subtitle: const Text('Kelola memori sementara dan pilihan kelas aktif'),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: _showCacheManagementDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security_rounded),
                  title: const Text('Status Verifikasi Email'),
                  subtitle: Text(isVerified ? 'Email Terverifikasi' : 'Menunggu Verifikasi'),
                  trailing: Icon(
                    isVerified ? Icons.check_circle_rounded : Icons.pending_rounded,
                    color: isVerified ? AppTheme.success : AppTheme.warning,
                    size: 20,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    authProvider.isRoleOutOfSync ? Icons.sync_problem_rounded : Icons.sync_rounded,
                    color: authProvider.isRoleOutOfSync ? AppTheme.warning : null,
                  ),
                  title: const Text('Sinkronisasi Sesi & Peran'),
                  subtitle: Text(
                    authProvider.isRoleOutOfSync
                        ? 'Peran belum sinkron (Token: ${appUser?.claimsRole?.value ?? "USER"} vs Profil: ${appUser?.role.value}). Tekan perbarui.'
                        : 'Sesi dan hak akses token mutakhir.',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Perbarui Sesi',
                    onPressed: () async {
                      await authProvider.refreshSession();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sesi dan token hak akses berhasil diperbarui.'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isLoggingOut ? null : _confirmAndSignOut,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.logout_rounded, size: 20),
            label: Text(
              _isLoggingOut ? 'Sedang Keluar...' : 'Keluar dari Akun',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  final Future<void> Function({required String currentPassword, required String newPassword}) onSave;
  final Future<void> Function(String email) onResetPassword;
  final String? userEmail;

  const _ChangePasswordDialog({
    required this.onSave,
    required this.onResetPassword,
    this.userEmail,
  });

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;
  String? _serverError;

  @override
  void dispose() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Ubah Kata Sandi'),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Untuk keamanan akun Anda, masukkan kata sandi saat ini lalu buat kata sandi baru minimal 8 karakter.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  if (_serverError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.error.withAlpha(50)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 16, color: AppTheme.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _serverError!,
                              style: const TextStyle(fontSize: 12, color: AppTheme.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrent,
                    enabled: !_isSubmitting,
                    decoration: InputDecoration(
                      labelText: 'Kata Sandi Saat Ini',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 18),
                        onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Kata sandi saat ini wajib diisi';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    enabled: !_isSubmitting,
                    decoration: InputDecoration(
                      labelText: 'Kata Sandi Baru (Min. 8 Karakter)',
                      prefixIcon: const Icon(Icons.password_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, size: 18),
                        onPressed: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Kata sandi baru wajib diisi';
                      if (v.length < 8) return 'Kata sandi baru minimal 8 karakter.';
                      if (v == _currentPasswordController.text) {
                        return 'Kata sandi baru tidak boleh sama dengan kata sandi saat ini.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    enabled: !_isSubmitting,
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Kata Sandi Baru',
                      prefixIcon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 18),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Konfirmasi kata sandi wajib diisi';
                      if (v != _newPasswordController.text) return 'Konfirmasi kata sandi tidak cocok.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  if (widget.userEmail != null && widget.userEmail!.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                                final email = widget.userEmail!;
                                await widget.onResetPassword(email);
                                if (context.mounted) Navigator.pop(context, false);
                              },
                        child: const Text('Lupa kata sandi saat ini?', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() {
                      _isSubmitting = true;
                      _serverError = null;
                    });

                    try {
                      await widget.onSave(
                        currentPassword: _currentPasswordController.text,
                        newPassword: _newPasswordController.text,
                      );
                      if (context.mounted) Navigator.pop(context, true);
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          _isSubmitting = false;
                          if (e is FirebaseAuthException) {
                            if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
                              _serverError = 'Kata sandi saat ini yang Anda masukkan salah.';
                            } else {
                              _serverError = AuthService.translateError(e);
                            }
                          } else {
                            _serverError = 'Gagal memperbarui kata sandi: $e';
                          }
                        });
                      }
                    }
                  },
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Simpan Sandi'),
          ),
        ],
      ),
    );
  }
}

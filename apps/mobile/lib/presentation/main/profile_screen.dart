import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../repositories/user_repository.dart';
import '../../services/auth_provider.dart';
import '../../services/class_provider.dart';
import 'main_shell.dart';

class ProfileScreen extends StatefulWidget {
  final UserRepository? userRepository;

  const ProfileScreen({super.key, this.userRepository});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final UserRepository _userRepository;
  String? _nimNip;
  bool _isLoadingIdentity = false;

  @override
  void initState() {
    super.initState();
    _userRepository = widget.userRepository ?? UserRepository();
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

  Future<void> _showEditNimDialog() async {
    final controller = TextEditingController(text: _nimNip ?? '');
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nomor Induk (NIM / NIP)'),
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
                  decoration: const InputDecoration(
                    labelText: 'NIM / NIP',
                    prefixIcon: Icon(Icons.badge_outlined, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'NIM/NIP wajib diisi';
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
                      content: Text('Gagal menyimpan NIM/NIP: $e'),
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
        const SnackBar(
          content: Text('NIM/NIP berhasil disimpan di private identity.'),
          backgroundColor: AppTheme.success,
        ),
      );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
            onPressed: () async {
              try {
                await context.read<ClassProvider>().clear();
              } catch (_) {}
              MainShell.activeClassId = null;
              await authProvider.signOut();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
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
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Nomor Induk (NIM / NIP)'),
                  subtitle: Text(
                    _isLoadingIdentity
                        ? 'Memuat...'
                        : (_nimNip != null ? _nimNip! : 'Belum diisi (Klik untuk menambahkan)'),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: _showEditNimDialog,
                  ),
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

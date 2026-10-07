import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/auth/role_guard.dart';
import '../../core/config/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/classroom.dart';
import '../../repositories/meeting_repository.dart';
import '../../services/auth_provider.dart';
import '../../services/class_provider.dart';
import '../common/loading_indicator.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final MeetingRepository _meetingRepository;

  @override
  void initState() {
    super.initState();
    _meetingRepository = MeetingRepository();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassProvider>().loadClasses();
    });
  }

  Future<void> _showCreateClassDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final codeController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Kelas Baru'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kelas',
                    hintText: 'Contoh: Pemrograman Mobile',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 3) {
                      return 'Nama kelas minimal 3 karakter';
                    }
                    if (v.trim().length > 100) {
                      return 'Nama kelas maksimal 100 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (Opsional)',
                    hintText: 'Deskripsi singkat silabus kelas',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Kode Kelas Khusus (Opsional)',
                    hintText: 'Kosongkan untuk kode acak 8 karakter',
                  ),
                  validator: (v) {
                    if (v != null && v.trim().isNotEmpty) {
                      final clean = v.trim().toUpperCase();
                      if (clean.length < 6 || clean.length > 12) {
                        return 'Kode harus 6-12 karakter';
                      }
                      if (!RegExp(r'^[A-Z0-9]+$').hasMatch(clean)) {
                        return 'Kode hanya huruf kapital dan angka';
                      }
                    }
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
              try {
                final classProvider = context.read<ClassProvider>();
                await classProvider.createClass(
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  customCode: codeController.text.trim().isEmpty ? null : codeController.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            child: const Text('Buat Kelas'),
          ),
        ],
      ),
    );

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kelas berhasil dibuat.'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // 1. Jika profil sedang dimuat, tampilkan loading indikator
    if (authProvider.profileStatus == ProfileStatus.loading) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Memuat profil dan hak akses...'),
      );
    }

    // 2. Jika profil gagal dimuat, tampilkan pesan error eksplisit tanpa merender role palsu
    if (authProvider.profileStatus == ProfileStatus.error) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppConstants.appName)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_off_outlined,
                  size: 56,
                  color: AppTheme.error.withAlpha(180),
                ),
                const SizedBox(height: 16),
                Text(
                  'Profil Belum Berhasil Dimuat',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  authProvider.profileErrorMessage ??
                      'Terjadi kendala saat menyinkronkan profil Anda dari server. Silakan coba lagi.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton(
                      onPressed: () => authProvider.signOut(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(110, 44),
                      ),
                      child: const Text('Keluar'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => authProvider.retryLoadSession(),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(130, 44),
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    final classProvider = context.watch<ClassProvider>();
    final isStaff = RoleGuard.isStaff(authProvider.appUser);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(AppConstants.appName),
          ],
        ),
        actions: [
          if (isStaff)
            IconButton(
              icon: const Icon(Icons.add_business_rounded),
              tooltip: 'Buat Kelas Baru',
              onPressed: _showCreateClassDialog,
            ),
          IconButton(
            icon: const Icon(Icons.key_rounded),
            tooltip: 'Gabung Kelas',
            onPressed: () => context.push(AppConstants.joinClassRoute),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: classProvider.isLoading && classProvider.allClasses.isEmpty
          ? const LoadingIndicator(message: 'Memuat kelas Anda...')
          : RefreshIndicator(
              onRefresh: () => classProvider.loadClasses(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Welcome Banner Card
                  _buildWelcomeCard(context, classProvider),
                  if (authProvider.isRoleOutOfSync) ...[
                    const SizedBox(height: 12),
                    _buildSyncWarningBanner(context, authProvider),
                  ],
                  const SizedBox(height: 20),

                  // Section: Kelas yang Dikelola (Dosen / Pengajar)
                  if (isStaff) ...[
                    Text(
                      'Kelas yang Anda Kelola',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (classProvider.ownedClasses.isEmpty)
                      _buildEmptyOwnedCard(context)
                    else
                      ...classProvider.ownedClasses.map((c) => _buildClassCard(context, c, isOwner: true)),
                    const SizedBox(height: 24),
                  ],

                  // Section: Kelas yang Diikuti (Mahasiswa / Anggota)
                  Row(
                    children: [
                      Text(
                        'Kelas yang Anda Ikuti',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      if (classProvider.joinedClasses.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => context.push(AppConstants.joinClassRoute),
                          icon: const Icon(Icons.add_link_rounded, size: 16),
                          label: const Text('Gabung Kode', style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (classProvider.joinedClasses.isEmpty)
                    _buildEmptyJoinedCard(context)
                  else
                    ...classProvider.joinedClasses.map((c) => _buildClassCard(context, c, isOwner: false)),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, ClassProvider classProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Farlean LMS • Multi-Class Active',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Selamat Datang di Farlean LMS',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Akses materi terstruktur, kuis pretest berpenilaian server, video pembelajaran, dan forum belajar dalam satu platform.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncWarningBanner(BuildContext context, AuthProvider authProvider) {
    final appUser = authProvider.appUser!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.warning.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sync_problem_rounded, color: AppTheme.warning, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Peran Akun Belum Sinkron',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.warning),
                ),
                Text(
                  'Token: ${appUser.claimsRole?.value ?? "USER"} vs Profil: ${appUser.role.value}. Tekan Perbarui untuk menyelaraskan hak akses.',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => authProvider.refreshSession(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(60, 32),
            ),
            child: const Text('Perbarui', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(BuildContext context, Classroom classroom, {required bool isOwner}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isOwner ? Icons.workspace_premium_rounded : Icons.school_outlined,
                    color: AppTheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classroom.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (classroom.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          classroom.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildStatusBadge(classroom.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (classroom.code.isNotEmpty) ...[
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: classroom.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Kode ${classroom.code} disalin.'), duration: const Duration(seconds: 1)),
                      );
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.key_rounded, size: 12, color: AppTheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            classroom.code,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.copy_rounded, size: 12, color: AppTheme.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                FutureBuilder<int>(
                  future: _meetingRepository.getMeetingCount(classroom.id, isStaff: isOwner),
                  builder: (context, snapshot) {
                    final count = snapshot.data;
                    if (count == null) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$count Pertemuan',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    );
                  },
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    final classProvider = context.read<ClassProvider>();
                    classProvider.selectClass(classroom.id);
                    context.push('/classes/${classroom.id}');
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(110, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: Text(isOwner ? 'Kelola Kelas' : 'Buka Kelas'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOwnedCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.add_business_outlined, size: 40, color: AppTheme.textSecondary.withAlpha(128)),
            const SizedBox(height: 8),
            const Text('Belum ada kelas yang Anda kelola.', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text(
              'Buat kelas baru untuk mulai mengunggah materi dan membuat pertemuan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _showCreateClassDialog,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Buat Kelas Pertama'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyJoinedCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.group_add_outlined, size: 40, color: AppTheme.textSecondary.withAlpha(128)),
            const SizedBox(height: 8),
            const Text('Belum tergabung ke kelas pembelajaran.', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text(
              'Minta kode kelas dari Dosen/Pengajar Anda untuk bergabung ke kelas.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => context.push(AppConstants.joinClassRoute),
              icon: const Icon(Icons.key_rounded, size: 16),
              label: const Text('Gabung Kelas'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isArchived = status.toLowerCase() == 'archived';
    final isPublished = status.toLowerCase() == 'published' || status.toLowerCase() == 'active';
    final color = isPublished
        ? AppTheme.success
        : (isArchived ? AppTheme.textSecondary : AppTheme.warning);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/auth/role_guard.dart';
import '../../core/config/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/content_status.dart';
import '../../models/meeting.dart';
import '../../repositories/meeting_repository.dart';
import '../../services/auth_provider.dart';
import '../common/error_view.dart';
import '../common/loading_indicator.dart';

class MeetingListScreen extends StatefulWidget {
  final String? classId;
  final MeetingRepository? meetingRepository;

  const MeetingListScreen({
    super.key,
    this.classId,
    this.meetingRepository,
  });

  @override
  State<MeetingListScreen> createState() => _MeetingListScreenState();
}

class _MeetingListScreenState extends State<MeetingListScreen> {
  late final MeetingRepository _meetingRepository;
  List<Meeting> _meetings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _meetingRepository = widget.meetingRepository ?? MeetingRepository();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    final effectiveClassId = widget.classId?.trim() ?? '';
    if (effectiveClassId.isEmpty || effectiveClassId == 'default_class') {
      if (mounted) {
        setState(() {
          _meetings = [];
          _isLoading = false;
          _errorMessage = null;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();
    final isStaff = RoleGuard.isStaff(authProvider.appUser);

    try {
      final list = await _meetingRepository.getMeetingsByClass(
        effectiveClassId,
        isStaff: isStaff,
      );
      if (mounted) {
        setState(() {
          _meetings = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        String friendlyMessage;
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('permission-denied') || errorString.contains('evaluation error')) {
          friendlyMessage = isStaff
              ? 'Akses ditolak: Anda tidak memiliki wewenang untuk mengelola kelas ini.'
              : 'Akses ditolak: Anda belum terdaftar sebagai anggota aktif di kelas ini. Pastikan Anda telah bergabung dan disetujui.';
        } else if (errorString.contains('network') || errorString.contains('unavailable')) {
          friendlyMessage = 'Koneksi ke server bermasalah. Periksa jaringan internet atau emulator Anda.';
        } else {
          friendlyMessage = 'Gagal memuat daftar pertemuan: $e';
        }

        setState(() {
          _errorMessage = friendlyMessage;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showCreateMeetingDialog() async {
    final effectiveClassId = widget.classId?.trim() ?? '';
    if (effectiveClassId.isEmpty || effectiveClassId == 'default_class') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih kelas yang valid terlebih dahulu untuk membuat pertemuan.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final titleController = TextEditingController();
    final numberController = TextEditingController(text: '${_meetings.length + 1}');
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Pertemuan Baru'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: numberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Nomor Pertemuan'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Nomor wajib diisi';
                  final num = int.tryParse(v.trim());
                  if (num == null || num <= 0) return 'Nomor harus angka > 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Judul Pertemuan'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Judul wajib diisi';
                  return null;
                },
              ),
            ],
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
                final meeting = Meeting(
                  id: '',
                  classId: effectiveClassId,
                  number: int.parse(numberController.text.trim()),
                  title: titleController.text.trim(),
                  date: DateTime.now(),
                  status: ContentStatus.draft,
                );
                await _meetingRepository.createMeeting(meeting);
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            child: const Text('Simpan Draft'),
          ),
        ],
      ),
    );

    if (created == true) {
      _loadMeetings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isStaff = RoleGuard.isStaff(authProvider.appUser);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Materi & Pertemuan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan',
            onPressed: _loadMeetings,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: isStaff
          ? FloatingActionButton.extended(
              onPressed: _showCreateMeetingDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Pertemuan'),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: _buildBody(isStaff),
    );
  }

  Widget _buildBody(bool isStaff) {
    final effectiveClassId = widget.classId?.trim() ?? '';
    if (effectiveClassId.isEmpty || effectiveClassId == 'default_class') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.class_outlined,
                size: 56,
                color: AppTheme.textSecondary.withAlpha(128),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih Kelas Pembelajaran',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Anda belum memilih kelas. Silakan bergabung menggunakan kode kelas atau pilih kelas dari Beranda untuk melihat pertemuan.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => context.push(AppConstants.joinClassRoute),
                icon: const Icon(Icons.qr_code_rounded),
                label: const Text('Gabung Kelas Baru'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const LoadingIndicator(message: 'Memuat pertemuan...');
    }

    if (_errorMessage != null) {
      return ErrorView(message: _errorMessage!, onRetry: _loadMeetings);
    }

    if (_meetings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 56,
                color: AppTheme.textSecondary.withAlpha(128),
              ),
              const SizedBox(height: 16),
              Text(
                'Belum Ada Pertemuan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                isStaff
                    ? 'Buat pertemuan baru untuk mulai mengunggah materi, kuis pretest, dan video pembelajaran.'
                    : 'Pengajar belum mempublikasikan pertemuan pembelajaran di kelas ini.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (isStaff) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _showCreateMeetingDialog,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Buat Pertemuan Pertama'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMeetings,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _meetings.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final meeting = _meetings[index];
          return _buildMeetingCard(meeting, isStaff);
        },
      ),
    );
  }

  Widget _buildMeetingCard(Meeting meeting, bool isStaff) {
    return Card(
      child: InkWell(
        onTap: () async {
          await context.push('/meetings/${meeting.id}', extra: meeting);
          _loadMeetings();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Pertemuan ${meeting.number}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isStaff) _buildStatusBadge(meeting.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                meeting.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildModuleChip(
                    Icons.quiz_outlined,
                    'Pretest',
                    meeting.pretestId != null,
                  ),
                  _buildModuleChip(
                    Icons.menu_book_rounded,
                    'Materi',
                    meeting.materiId != null,
                  ),
                  _buildModuleChip(
                    Icons.play_circle_outline_rounded,
                    'Video',
                    meeting.videoId != null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ContentStatus status) {
    Color color;
    switch (status) {
      case ContentStatus.published:
        color = AppTheme.success;
        break;
      case ContentStatus.archived:
        color = AppTheme.textSecondary;
        break;
      case ContentStatus.draft:
        color = AppTheme.warning;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Text(
        status.value,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildModuleChip(IconData icon, String label, bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable ? AppTheme.surface : AppTheme.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isAvailable ? AppTheme.border : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isAvailable ? AppTheme.primary : AppTheme.textSecondary.withAlpha(100),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isAvailable ? AppTheme.textPrimary : AppTheme.textSecondary.withAlpha(128),
              fontWeight: isAvailable ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

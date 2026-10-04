import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/auth/role_guard.dart';
import '../../core/theme/app_theme.dart';
import '../../models/content_status.dart';
import '../../models/meeting.dart';
import '../../repositories/meeting_repository.dart';
import '../../services/auth_provider.dart';
import '../common/error_view.dart';
import '../common/loading_indicator.dart';

class MeetingDetailScreen extends StatefulWidget {
  final String meetingId;
  final Meeting? initialMeeting;
  final MeetingRepository? meetingRepository;

  const MeetingDetailScreen({
    super.key,
    required this.meetingId,
    this.initialMeeting,
    this.meetingRepository,
  });

  @override
  State<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends State<MeetingDetailScreen> {
  late final MeetingRepository _meetingRepository;
  Meeting? _meeting;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _meetingRepository = widget.meetingRepository ?? MeetingRepository();
    _meeting = widget.initialMeeting;
    if (_meeting == null) {
      _loadMeetingDetail();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadMeetingDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final doc = await _meetingRepository.getMeeting(widget.meetingId);
      if (mounted) {
        setState(() {
          _meeting = doc;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat detail pertemuan: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateStatus(ContentStatus newStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ubah Status ke ${newStatus.value}?'),
        content: Text(
          newStatus == ContentStatus.published
              ? 'Pertemuan ini akan dapat diakses oleh seluruh anggota kelas yang aktif.'
              : 'Pertemuan ini akan diarsipkan dan tidak lagi muncul sebagai sesi aktif.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _meetingRepository.updateMeetingStatus(widget.meetingId, newStatus);
        setState(() {
          _meeting = _meeting?.copyWith(status: newStatus);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status berhasil diubah menjadi ${newStatus.value}'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Memuat hub pertemuan...'),
      );
    }

    if (_errorMessage != null || _meeting == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Pertemuan')),
        body: ErrorView(
          message: _errorMessage ?? 'Pertemuan tidak ditemukan.',
          onRetry: _loadMeetingDetail,
        ),
      );
    }

    final meeting = _meeting!;
    final authProvider = context.watch<AuthProvider>();
    final isStaff = RoleGuard.isStaff(authProvider.appUser);

    return Scaffold(
      appBar: AppBar(
        title: Text('Pertemuan ${meeting.number}'),
        actions: [
          if (isStaff)
            PopupMenuButton<ContentStatus>(
              tooltip: 'Kelola Status',
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: _updateStatus,
              itemBuilder: (context) => [
                if (meeting.status != ContentStatus.published)
                  const PopupMenuItem(
                    value: ContentStatus.published,
                    child: Text('Publikasikan (Published)'),
                  ),
                if (meeting.status != ContentStatus.draft)
                  const PopupMenuItem(
                    value: ContentStatus.draft,
                    child: Text('Jadikan Draft'),
                  ),
                if (meeting.status != ContentStatus.archived)
                  const PopupMenuItem(
                    value: ContentStatus.archived,
                    child: Text('Arsipkan (Archived)'),
                  ),
              ],
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
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
                          'Hub Pembelajaran',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _buildStatusBadge(meeting.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    meeting.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Satu pertemuan menghubungkan kuis pretest, materi bacaan terstruktur, dan video pembelajaran.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Modul Pembelajaran',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          // 1. Modul Materi Card (Dapat dibuka tanpa mengunci)
          _buildModuleCard(
            title: 'Materi Pembelajaran',
            subtitle: meeting.materiId != null
                ? 'Materi bacaan terstruktur format Quill Delta'
                : 'Materi belum diunggah oleh pengajar',
            icon: Icons.menu_book_rounded,
            accentColor: AppTheme.primary,
            isAvailable: meeting.materiId != null,
            actionLabel: 'Buka Materi',
            onTap: () {
              if (meeting.materiId != null) {
                context.push('/materials/${meeting.materiId}?classId=${meeting.classId}&meetingId=${meeting.id}');
              }
            },
          ),
          const SizedBox(height: 12),

          // 2. Modul Pretest Card
          _buildModuleCard(
            title: 'Kuis Pretest',
            subtitle: meeting.pretestId != null
                ? 'Uji pemahaman awal sebelum memulai materi inti'
                : 'Pretest belum diaktifkan untuk pertemuan ini',
            icon: Icons.quiz_outlined,
            accentColor: AppTheme.secondary,
            isAvailable: meeting.pretestId != null,
            actionLabel: 'Mulai Pretest',
            badgeNotice: 'Wajib pernah buka materi',
            onTap: () {
              if (meeting.pretestId != null) {
                context.push('/pretests/${meeting.pretestId}?classId=${meeting.classId}&meetingId=${meeting.id}');
              }
            },
          ),
          const SizedBox(height: 12),

          // 3. Modul Video Card
          _buildModuleCard(
            title: 'Video Pembelajaran',
            subtitle: meeting.videoId != null
                ? 'Video tutorial & demonstrasi interaktif'
                : 'Video belum ditautkan ke pertemuan ini',
            icon: Icons.play_circle_outline_rounded,
            accentColor: AppTheme.warning,
            isAvailable: meeting.videoId != null,
            actionLabel: 'Tonton Video',
            onTap: () {
              if (meeting.videoId != null) {
                context.push('/videos/${meeting.videoId}?classId=${meeting.classId}&meetingId=${meeting.id}');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isAvailable,
    required String actionLabel,
    String? badgeNotice,
    required VoidCallback onTap,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ),
                      if (badgeNotice != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeNotice,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: isAvailable ? onTap : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAvailable ? accentColor : AppTheme.border,
                      minimumSize: const Size(120, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text(
                      isAvailable ? actionLabel : 'Belum Tersedia',
                      style: TextStyle(
                        fontSize: 13,
                        color: isAvailable ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

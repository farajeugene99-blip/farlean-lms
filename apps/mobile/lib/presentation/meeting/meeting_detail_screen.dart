import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/auth/role_guard.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/content_status.dart';
import '../../models/meeting.dart';
import '../../models/posttest.dart';
import '../../models/pretest.dart';
import '../../models/question.dart';
import '../../models/video_item.dart';
import '../../repositories/meeting_repository.dart';
import '../../repositories/posttest_repository.dart';
import '../../repositories/pretest_repository.dart';
import '../../repositories/video_repository.dart';
import '../../services/auth_provider.dart';
import '../common/error_view.dart';
import '../common/loading_indicator.dart';

class MeetingDetailScreen extends StatefulWidget {
  final String meetingId;
  final Meeting? initialMeeting;
  final MeetingRepository? meetingRepository;
  final VideoRepository? videoRepository;
  final PretestRepository? pretestRepository;
  final PosttestRepository? posttestRepository;

  const MeetingDetailScreen({
    super.key,
    required this.meetingId,
    this.initialMeeting,
    this.meetingRepository,
    this.videoRepository,
    this.pretestRepository,
    this.posttestRepository,
  });

  @override
  State<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends State<MeetingDetailScreen> {
  late final MeetingRepository _meetingRepository;
  late final VideoRepository _videoRepository;
  late final PretestRepository _pretestRepository;
  late final PosttestRepository _posttestRepository;

  Meeting? _meeting;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSyncingSchedule = false;

  @override
  void initState() {
    super.initState();
    _meetingRepository = widget.meetingRepository ?? MeetingRepository();
    _videoRepository = widget.videoRepository ?? VideoRepository();
    _pretestRepository = widget.pretestRepository ?? PretestRepository();
    _posttestRepository = widget.posttestRepository ?? PosttestRepository();

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

  bool get _isScheduledLockedForStudent {
    if (_meeting == null) return false;
    final authProvider = context.read<AuthProvider>();
    final isStaff = RoleGuard.isStaff(authProvider.appUser);
    if (isStaff) return false;
    if (_meeting!.status == ContentStatus.scheduled) {
      if (_meeting!.publishAt != null && DateTime.now().isBefore(_meeting!.publishAt!)) {
        return true;
      }
    }
    return false;
  }

  void _showScheduledLockNotice() {
    final publishText = _meeting?.publishAt != null
        ? DateFormatter.formatWib(_meeting!.publishAt)
        : 'waktu jadwal mendatang';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pertemuan ini masih berstatus Terjadwal. Konten akan dibuka pada $publishText.'),
        backgroundColor: AppTheme.warning,
      ),
    );
  }

  Future<void> _showScheduleDialog() async {
    final now = DateTime.now();
    DateTime pickedDate = now.add(const Duration(days: 1));
    TimeOfDay pickedTime = const TimeOfDay(hour: 8, minute: 0);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: pickedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Pilih Tanggal Publikasi Pertemuan',
    );
    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: pickedTime,
      helpText: 'Pilih Jam Publikasi (WIB)',
    );
    if (selectedTime == null || !mounted) return;

    final scheduledDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (scheduledDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waktu publikasi terjadwal harus di waktu mendatang.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    try {
      await _meetingRepository.updateMeetingStatus(
        widget.meetingId,
        ContentStatus.scheduled,
        publishAt: scheduledDateTime,
      );
      setState(() {
        _meeting = _meeting?.copyWith(
          status: ContentStatus.scheduled,
          publishAt: scheduledDateTime,
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pertemuan berhasil dijadwalkan terbit pada ${DateFormatter.formatWib(scheduledDateTime)}.',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menjadwalkan pertemuan: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  /// Memicu promosi pertemuan terjadwal yang sudah jatuh tempo (khusus staf).
  /// Presisi jujur: promosi berjalan saat tombol/cron dipanggil, bukan tepat-menit otomatis.
  Future<void> _syncScheduledMeetings() async {
    if (_isSyncingSchedule) return;
    setState(() => _isSyncingSchedule = true);
    try {
      final promoted = await _meetingRepository.syncScheduledMeetings(
        classId: _meeting?.classId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              promoted > 0
                  ? '$promoted pertemuan terjadwal yang jatuh tempo berhasil dipublikasikan.'
                  : 'Tidak ada pertemuan terjadwal yang jatuh tempo saat ini.',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
        await _loadMeetingDetail();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyinkronkan jadwal: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncingSchedule = false);
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
          _meeting = _meeting?.copyWith(status: newStatus, clearPublishAt: true);
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

  Future<void> _showEditMeetingDialog() async {
    final meeting = _meeting;
    if (meeting == null) return;

    final titleController = TextEditingController(text: meeting.title);
    final numberController = TextEditingController(text: '${meeting.number}');
    final descController = TextEditingController(text: meeting.description ?? '');
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Informasi Pertemuan'),
        content: SizedBox(
          width: 440,
          child: Form(
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
                const SizedBox(height: 12),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Deskripsi / Ringkasan'),
                  maxLines: 2,
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
                final updatedMeeting = meeting.copyWith(
                  title: titleController.text.trim(),
                  number: int.parse(numberController.text.trim()),
                  description: descController.text.trim(),
                );
                await _meetingRepository.updateMeeting(updatedMeeting);
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    ).whenComplete(() {
      titleController.dispose();
      numberController.dispose();
      descController.dispose();
    });

    if (updated == true) {
      _loadMeetingDetail();
    }
  }

  Future<void> _showDeleteMeetingDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pertemuan Ini?'),
        content: const Text(
          'Tindakan ini akan menghapus pertemuan dari daftar kelas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _meetingRepository.deleteMeeting(widget.meetingId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pertemuan berhasil dihapus.'),
              backgroundColor: AppTheme.success,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  Future<void> _createMateriForMeeting() async {
    final meeting = _meeting;
    if (meeting == null) return;

    final result = await context.push<dynamic>(
      '/materials/new/edit?classId=${meeting.classId}&meetingId=${meeting.id}',
    );

    if (result is String && result.isNotEmpty) {
      await _meetingRepository.linkModule(meeting.id, materiId: result);
      _loadMeetingDetail();
    }
  }

  Future<void> _showAddVideoDialog() async {
    final meeting = _meeting;
    if (meeting == null) return;

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => _AddVideoDialog(
        meeting: meeting,
        videoRepository: _videoRepository,
        meetingRepository: _meetingRepository,
      ),
    );

    if (created == true) {
      _loadMeetingDetail();
    }
  }

  Future<void> _showCreatePretestDialog() async {
    final meeting = _meeting;
    if (meeting == null) return;

    final titleController = TextEditingController(text: 'Pretest Pertemuan ${meeting.number}');
    final durationController = TextEditingController(text: '15');
    final formKey = GlobalKey<FormState>();

    String? createdTestId;
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Kuis Pretest'),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Judul Pretest'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Judul wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Durasi (Menit)'),
                  validator: (v) {
                    final num = int.tryParse(v?.trim() ?? '');
                    if (num == null || num <= 0) return 'Durasi harus > 0 menit';
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
                final pretest = Pretest(
                  id: '',
                  classId: meeting.classId,
                  meetingId: meeting.id,
                  title: titleController.text.trim(),
                  duration: int.parse(durationController.text.trim()),
                  status: ContentStatus.draft,
                );
                final testId = await _pretestRepository.createPretest(pretest);
                await _meetingRepository.linkModule(meeting.id, pretestId: testId);
                createdTestId = testId;
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            child: const Text('Simpan & Kelola Soal'),
          ),
        ],
      ),
    ).whenComplete(() {
      titleController.dispose();
      durationController.dispose();
    });

    if (created == true && createdTestId != null) {
      await _loadMeetingDetail();
      if (mounted) {
        _showManageQuestionsDialog(createdTestId!, 'Pretest', true);
      }
    }
  }

  Future<void> _showCreatePosttestDialog() async {
    final meeting = _meeting;
    if (meeting == null) return;

    final titleController = TextEditingController(text: 'Post Test Pertemuan ${meeting.number}');
    final durationController = TextEditingController(text: '20');
    final formKey = GlobalKey<FormState>();

    String? createdTestId;
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Kuis Post Test'),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Judul Post Test'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Judul wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Durasi (Menit)'),
                  validator: (v) {
                    final num = int.tryParse(v?.trim() ?? '');
                    if (num == null || num <= 0) return 'Durasi harus > 0 menit';
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
                final posttest = Posttest(
                  id: '',
                  classId: meeting.classId,
                  meetingId: meeting.id,
                  title: titleController.text.trim(),
                  duration: int.parse(durationController.text.trim()),
                  status: ContentStatus.draft,
                );
                final testId = await _posttestRepository.createPosttest(posttest);
                await _meetingRepository.linkModule(meeting.id, posttestId: testId);
                createdTestId = testId;
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            child: const Text('Simpan & Kelola Soal'),
          ),
        ],
      ),
    ).whenComplete(() {
      titleController.dispose();
      durationController.dispose();
    });

    if (created == true && createdTestId != null) {
      await _loadMeetingDetail();
      if (mounted) {
        _showManageQuestionsDialog(createdTestId!, 'Post Test', false);
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
          if (isStaff) ...[
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Edit Info Pertemuan',
              onPressed: _showEditMeetingDialog,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Hapus Pertemuan',
              onPressed: _showDeleteMeetingDialog,
            ),
            IconButton(
              icon: _isSyncingSchedule
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync_rounded),
              tooltip: 'Sinkronkan Jadwal Publikasi',
              onPressed: _isSyncingSchedule ? null : _syncScheduledMeetings,
            ),
            PopupMenuButton<String>(
              tooltip: 'Kelola Status',
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (val) {
                if (val == 'publish') {
                  _updateStatus(ContentStatus.published);
                } else if (val == 'schedule') {
                  _showScheduleDialog();
                } else if (val == 'draft') {
                  _updateStatus(ContentStatus.draft);
                } else if (val == 'archive') {
                  _updateStatus(ContentStatus.archived);
                }
              },
              itemBuilder: (context) => [
                if (meeting.status != ContentStatus.published)
                  const PopupMenuItem(
                    value: 'publish',
                    child: Text('Publikasikan Sekarang (Published)'),
                  ),
                if (meeting.status != ContentStatus.scheduled)
                  const PopupMenuItem(
                    value: 'schedule',
                    child: Text('Jadwalkan Publikasi (Scheduled)'),
                  ),
                if (meeting.status != ContentStatus.draft)
                  const PopupMenuItem(
                    value: 'draft',
                    child: Text('Jadikan Draft / Batalkan Jadwal'),
                  ),
                if (meeting.status != ContentStatus.archived)
                  const PopupMenuItem(
                    value: 'archive',
                    child: Text('Arsipkan (Archived)'),
                  ),
              ],
            ),
          ],
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
                          'Pertemuan ${meeting.number}',
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
                    meeting.description != null && meeting.description!.isNotEmpty
                        ? meeting.description!
                        : 'Satu pertemuan menghubungkan kuis pretest, materi bacaan terstruktur, video pembelajaran, dan post test evaluasi.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (meeting.status == ContentStatus.scheduled) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withAlpha(60)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 20, color: Colors.blue),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pertemuan Terjadwal',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  meeting.publishAt != null
                                      ? 'Dijadwalkan terbit pada ${DateFormatter.formatWib(meeting.publishAt)}. Publikasi berjalan saat cron/sinkronisasi berikutnya (dalam kisaran jadwal), bukan tepat-menit otomatis.'
                                      : 'Pertemuan disiapkan untuk jadwal publikasi mendatang.',
                                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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

          // 1. Modul Materi Card
          _buildModuleCard(
            title: 'Materi Pembelajaran',
            subtitle: meeting.materiId != null
                ? 'Materi bacaan terstruktur format Quill Delta'
                : (isStaff ? 'Materi belum dibuat. Klik untuk membuat materi baru.' : 'Materi belum diunggah oleh pengajar'),
            icon: Icons.menu_book_rounded,
            accentColor: AppTheme.primary,
            isAvailable: meeting.materiId != null || isStaff,
            actionLabel: meeting.materiId != null ? 'Buka Materi' : 'Buat Materi',
            onTap: () async {
              if (_isScheduledLockedForStudent) {
                _showScheduledLockNotice();
                return;
              }
              if (meeting.materiId != null) {
                await context.push('/materials/${meeting.materiId}?classId=${meeting.classId}&meetingId=${meeting.id}');
                if (mounted) _loadMeetingDetail();
              } else if (isStaff) {
                _createMateriForMeeting();
              }
            },
          ),
          const SizedBox(height: 12),

          // 2. Modul Pretest Card
          _buildModuleCard(
            title: 'Kuis Pretest',
            subtitle: meeting.pretestId != null
                ? 'Uji pemahaman awal sebelum memulai materi inti'
                : (isStaff ? 'Pretest belum diaktifkan. Klik untuk membuat pretest.' : 'Pretest belum diaktifkan untuk pertemuan ini'),
            icon: Icons.quiz_outlined,
            accentColor: AppTheme.secondary,
            isAvailable: meeting.pretestId != null || isStaff,
            actionLabel: meeting.pretestId != null ? 'Mulai Pretest' : 'Buat Pretest',
            secondaryActionLabel: (isStaff && meeting.pretestId != null) ? 'Kelola Soal' : null,
            badgeNotice: meeting.pretestId != null ? 'Wajib pernah buka materi' : null,
            onTap: () async {
              if (_isScheduledLockedForStudent) {
                _showScheduledLockNotice();
                return;
              }
              if (meeting.pretestId != null) {
                await context.push('/pretests/${meeting.pretestId}?classId=${meeting.classId}&meetingId=${meeting.id}');
                if (mounted) _loadMeetingDetail();
              } else if (isStaff) {
                _showCreatePretestDialog();
              }
            },
            onSecondaryTap: (isStaff && meeting.pretestId != null)
                ? () => _showManageQuestionsDialog(meeting.pretestId!, 'Pretest', true)
                : null,
          ),
          const SizedBox(height: 12),

          // 3. Modul Video Card
          _buildModuleCard(
            title: 'Video Pembelajaran',
            subtitle: meeting.videoId != null
                ? 'Video tutorial & demonstrasi interaktif'
                : (isStaff ? 'Video belum ditautkan. Klik untuk menambahkan link video.' : 'Video belum ditautkan ke pertemuan ini'),
            icon: Icons.play_circle_outline_rounded,
            accentColor: AppTheme.warning,
            isAvailable: meeting.videoId != null || isStaff,
            actionLabel: meeting.videoId != null ? 'Tonton Video' : 'Tambah Video',
            onTap: () async {
              if (_isScheduledLockedForStudent) {
                _showScheduledLockNotice();
                return;
              }
              if (meeting.videoId != null) {
                await context.push('/videos/${meeting.videoId}?classId=${meeting.classId}&meetingId=${meeting.id}');
                if (mounted) _loadMeetingDetail();
              } else if (isStaff) {
                _showAddVideoDialog();
              }
            },
          ),
          const SizedBox(height: 12),

          // 4. Modul Post Test Card
          _buildModuleCard(
            title: 'Kuis Post Test',
            subtitle: meeting.posttestId != null
                ? 'Evaluasi akhir capaian pembelajaran setelah memahami materi'
                : (isStaff ? 'Post test belum dibuat. Klik untuk membuat post test.' : 'Post test belum diaktifkan untuk pertemuan ini'),
            icon: Icons.assignment_turned_in_rounded,
            accentColor: Colors.deepPurple,
            isAvailable: meeting.posttestId != null || isStaff,
            actionLabel: meeting.posttestId != null ? 'Mulai Post Test' : 'Buat Post Test',
            secondaryActionLabel: (isStaff && meeting.posttestId != null) ? 'Kelola Soal' : null,
            onTap: () async {
              if (_isScheduledLockedForStudent) {
                _showScheduledLockNotice();
                return;
              }
              if (meeting.posttestId != null) {
                await context.push('/posttests/${meeting.posttestId}?classId=${meeting.classId}&meetingId=${meeting.id}');
                if (mounted) _loadMeetingDetail();
              } else if (isStaff) {
                _showCreatePosttestDialog();
              }
            },
            onSecondaryTap: (isStaff && meeting.posttestId != null)
                ? () => _showManageQuestionsDialog(meeting.posttestId!, 'Post Test', false)
                : null,
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
    String? secondaryActionLabel,
    String? badgeNotice,
    required VoidCallback onTap,
    VoidCallback? onSecondaryTap,
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
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
                      if (secondaryActionLabel != null && onSecondaryTap != null)
                        OutlinedButton.icon(
                          icon: const Icon(Icons.edit_note_rounded, size: 16),
                          label: Text(secondaryActionLabel),
                          onPressed: onSecondaryTap,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: accentColor,
                            side: BorderSide(color: accentColor.withAlpha(120)),
                            minimumSize: const Size(110, 38),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Menampilkan dialog daftar soal dan manajemen soal untuk Staff / Guru
  Future<void> _showManageQuestionsDialog(String testId, String testTitle, bool isPretest) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _ManageQuestionsSheet(
        testId: testId,
        testTitle: testTitle,
        isPretest: isPretest,
        pretestRepository: _pretestRepository,
        posttestRepository: _posttestRepository,
        onStatusChanged: _loadMeetingDetail,
      ),
    );
  }

  Widget _buildStatusBadge(ContentStatus status) {
    Color color;
    switch (status) {
      case ContentStatus.published:
        color = AppTheme.success;
        break;
      case ContentStatus.scheduled:
        color = Colors.blue;
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

class _AddVideoDialog extends StatefulWidget {
  final Meeting meeting;
  final VideoRepository videoRepository;
  final MeetingRepository meetingRepository;

  const _AddVideoDialog({
    required this.meeting,
    required this.videoRepository,
    required this.meetingRepository,
  });

  @override
  State<_AddVideoDialog> createState() => _AddVideoDialogState();
}

class _AddVideoDialogState extends State<_AddVideoDialog> {
  late final TextEditingController _urlController;
  VideoProvider _selectedProvider = VideoProvider.youtube;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final videoItem = VideoItem(
        id: '',
        meetingId: widget.meeting.id,
        classId: widget.meeting.classId,
        url: _urlController.text.trim(),
        provider: _selectedProvider,
      );
      final videoId = await widget.videoRepository.createVideo(videoItem);
      await widget.meetingRepository.linkModule(widget.meeting.id, videoId: videoId);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Video Pembelajaran'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<VideoProvider>(
              isExpanded: true,
              initialValue: _selectedProvider,
              decoration: const InputDecoration(
                labelText: 'Penyedia Video',
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                  value: VideoProvider.youtube,
                  child: Text(
                    'YouTube Video',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                DropdownMenuItem(
                  value: VideoProvider.cloudinary,
                  child: Text(
                    'Cloudinary (MP4/URL)',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedProvider = val);
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'URL Video',
                hintText: _selectedProvider == VideoProvider.youtube
                    ? 'https://www.youtube.com/watch?v=...'
                    : 'https://res.cloudinary.com/...',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'URL wajib diisi';
                if (!v.startsWith('http://') && !v.startsWith('https://')) {
                  return 'URL harus diawali http:// atau https://';
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
        onPressed: _isSaving ? null : () => Navigator.pop(context, false),
        child: const Text('Batal'),
      ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Simpan Video'),
        ),
      ],
    );
  }
}

class _ManageQuestionsSheet extends StatefulWidget {
  final String testId;
  final String testTitle;
  final bool isPretest;
  final PretestRepository pretestRepository;
  final PosttestRepository posttestRepository;
  final VoidCallback? onStatusChanged;

  const _ManageQuestionsSheet({
    required this.testId,
    required this.testTitle,
    required this.isPretest,
    required this.pretestRepository,
    required this.posttestRepository,
    this.onStatusChanged,
  });

  @override
  State<_ManageQuestionsSheet> createState() => _ManageQuestionsSheetState();
}

class _ManageQuestionsSheetState extends State<_ManageQuestionsSheet> {
  late Future<List<Question>> _questionsFuture;
  ContentStatus? _status;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _reloadQuestions();
    _loadStatus();
  }

  void _reloadQuestions() {
    setState(() {
      _questionsFuture = widget.isPretest
          ? widget.pretestRepository.getQuestions(widget.testId)
          : widget.posttestRepository.getQuestions(widget.testId);
    });
  }

  Future<void> _loadStatus() async {
    try {
      if (widget.isPretest) {
        final pretest = await widget.pretestRepository.getPretest(widget.testId);
        if (mounted) setState(() => _status = pretest?.status);
      } else {
        final posttest = await widget.posttestRepository.getPosttest(widget.testId);
        if (mounted) setState(() => _status = posttest?.status);
      }
    } catch (_) {}
  }

  Future<void> _publish(List<Question> questions) async {
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambahkan minimal 1 soal sebelum mempublikasikan kuis.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _isPublishing = true);
    try {
      if (widget.isPretest) {
        await widget.pretestRepository.updatePretestStatus(widget.testId, ContentStatus.published);
      } else {
        await widget.posttestRepository.updatePosttestStatus(widget.testId, ContentStatus.published);
      }
      if (mounted) {
        setState(() {
          _status = ContentStatus.published;
          _isPublishing = false;
        });
        widget.onStatusChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kuis berhasil dipublikasikan! Mahasiswa sekarang dapat mengakses kuis ini.'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPublishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal publikasi: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _openEditor(Question? existing) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlgCtx) => _QuestionEditorDialog(
        testId: widget.testId,
        existing: existing,
        isPretest: widget.isPretest,
        pretestRepository: widget.pretestRepository,
        posttestRepository: widget.posttestRepository,
        onSaved: _reloadQuestions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return FutureBuilder<List<Question>>(
          future: _questionsFuture,
          builder: (context, snapshot) {
            final questions = snapshot.data ?? [];
            final isLoading = snapshot.connectionState == ConnectionState.waiting;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Top Title Bar
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(
                                  'Kelola Soal ${widget.testTitle}',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_status != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (_status == ContentStatus.published ? AppTheme.success : AppTheme.warning).withAlpha(25),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: (_status == ContentStatus.published ? AppTheme.success : AppTheme.warning).withAlpha(80),
                                      ),
                                    ),
                                    child: Text(
                                      _status == ContentStatus.draft ? 'DRAFT' : _status!.value.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _status == ContentStatus.published ? AppTheme.success : AppTheme.warning,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Jumlah Soal: ${questions.length} soal aktif',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Tutup',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Action Buttons Row (Responsive Wrap)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Tambah Soal'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onPressed: () => _openEditor(null),
                      ),
                      if (_status == ContentStatus.draft)
                        ElevatedButton.icon(
                          icon: _isPublishing
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.publish_rounded, size: 16),
                          label: const Text('Publikasikan Kuis'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          onPressed: _isPublishing ? null : () => _publish(questions),
                        ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (isLoading)
                    const Expanded(child: Center(child: CircularProgressIndicator()))
                  else if (questions.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.quiz_outlined, size: 48, color: AppTheme.textSecondary.withAlpha(100)),
                            const SizedBox(height: 12),
                            const Text(
                              'Draft, belum ada soal aktif.',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Klik tombol "Tambah Soal" untuk membuat soal kuis pertama.',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final sortedQuestions = List<Question>.from(questions);
                          sortedQuestions.sort((a, b) => a.id.compareTo(b.id));

                          return ListView.separated(
                            controller: scrollController,
                            itemCount: sortedQuestions.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final q = sortedQuestions[idx];
                              return Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppTheme.border),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: AppTheme.primary.withAlpha(30),
                                        child: Text(
                                          '${idx + 1}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          q.text,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.background,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: AppTheme.border),
                                        ),
                                        child: Text(
                                          '${q.points} poin',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 32),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: q.options.asMap().entries.map((opt) {
                                        final label = String.fromCharCode(65 + opt.key);
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: AppTheme.background,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppTheme.border),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primary.withAlpha(20),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  label,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.primary,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  opt.value,
                                                  style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.edit_outlined, size: 16),
                                        label: const Text('Edit'),
                                        onPressed: () => _openEditor(q),
                                      ),
                                      TextButton.icon(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.error),
                                        label: const Text('Hapus', style: TextStyle(color: AppTheme.error)),
                                        onPressed: () async {
                                          final messenger = ScaffoldMessenger.of(context);
                                          if (_status == ContentStatus.published && sortedQuestions.length <= 1) {
                                            messenger.showSnackBar(
                                              const SnackBar(
                                                content: Text('Tidak dapat menghapus soal aktif terakhir pada kuis yang berstatus Published. Silakan arsipkan kuis terlebih dahulu jika ingin menonaktifkannya.'),
                                                backgroundColor: AppTheme.error,
                                              ),
                                            );
                                            return;
                                          }

                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (dCtx) => AlertDialog(
                                              title: const Text('Konfirmasi Hapus Soal'),
                                              content: Text(
                                                'Apakah Anda yakin ingin menghapus Soal ${idx + 1}? Jika kuis sudah pernah dikerjakan siswa, soal akan diarsipkan (soft-delete) dan riwayat nilai siswa terdahulu tetap aman.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(dCtx, false),
                                                  child: const Text('Batal'),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                                                  onPressed: () => Navigator.pop(dCtx, true),
                                                  child: const Text('Hapus Soal'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true && mounted) {
                                            try {
                                              if (widget.isPretest) {
                                                await widget.pretestRepository.deleteQuestion(testId: widget.testId, qid: q.id);
                                              } else {
                                                await widget.posttestRepository.deleteQuestion(testId: widget.testId, qid: q.id);
                                              }
                                              _reloadQuestions();
                                            } catch (e) {
                                              messenger.showSnackBar(
                                                SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: AppTheme.error),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _QuestionEditorDialog extends StatefulWidget {
  final String testId;
  final Question? existing;
  final bool isPretest;
  final PretestRepository pretestRepository;
  final PosttestRepository posttestRepository;
  final VoidCallback onSaved;

  const _QuestionEditorDialog({
    required this.testId,
    required this.existing,
    required this.isPretest,
    required this.pretestRepository,
    required this.posttestRepository,
    required this.onSaved,
  });

  @override
  State<_QuestionEditorDialog> createState() => _QuestionEditorDialogState();
}

class _QuestionEditorDialogState extends State<_QuestionEditorDialog> {
  late final TextEditingController _textController;
  late final TextEditingController _pointsController;
  late final List<TextEditingController> _optionControllers;
  List<String> _legacyExtraOptions = const [];
  int _selectedCorrectIndex = 0;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.existing?.text ?? '');
    _pointsController = TextEditingController(text: '${widget.existing?.points ?? 10}');

    final existingOpts = widget.existing?.options ?? [];
    // Selalu tepat 5 controller untuk pilihan A, B, C, D, E
    _optionControllers = List.generate(5, (index) {
      final initialText = index < existingOpts.length ? existingOpts[index] : '';
      return TextEditingController(text: initialText);
    });

    if (existingOpts.length > 5) {
      _legacyExtraOptions = existingOpts.sublist(5);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _pointsController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    setState(() => _isSaving = true);

    final optionsList = [
      ..._optionControllers.map((c) => c.text.trim()),
      ..._legacyExtraOptions,
    ];
    final points = int.parse(_pointsController.text.trim());

    final question = Question(
      id: widget.existing?.id ?? '',
      text: _textController.text.trim(),
      options: optionsList,
      points: points,
      tag: 'general',
    );

    try {
      if (widget.isPretest) {
        await widget.pretestRepository.saveQuestionAndKey(
          testId: widget.testId,
          question: question,
          correctOptionIndex: _selectedCorrectIndex,
        );
      } else {
        await widget.posttestRepository.saveQuestionAndKey(
          testId: widget.testId,
          question: question,
          correctOptionIndex: _selectedCorrectIndex,
        );
      }
      if (mounted) Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Tambah Soal Baru' : 'Edit Soal'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    labelText: 'Teks Pertanyaan *',
                    hintText: 'Masukkan pertanyaan...',
                  ),
                  maxLines: 3,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Teks pertanyaan wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pointsController,
                  decoration: const InputDecoration(
                    labelText: 'Poin Soal (1 - 100) *',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Poin wajib diisi';
                    final parsed = int.tryParse(v.trim());
                    if (parsed == null || parsed < 1 || parsed > 100) return 'Poin harus antara 1 - 100';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilihan Jawaban & Kunci (A - E) *',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tentukan 5 pilihan jawaban (A sampai E) dan pilih satu radio sebagai kunci jawaban benar.',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._optionControllers.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final ctrl = entry.value;
                  final label = String.fromCharCode(65 + idx);
                  final isKey = _selectedCorrectIndex == idx;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isKey ? AppTheme.success.withAlpha(15) : AppTheme.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isKey ? AppTheme.success.withAlpha(120) : AppTheme.border,
                          width: isKey ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          // ignore: deprecated_member_use
                          Radio<int>(
                            value: idx,
                            // ignore: deprecated_member_use
                            groupValue: _selectedCorrectIndex,
                            // ignore: deprecated_member_use
                            onChanged: (val) {
                              setState(() {
                                _selectedCorrectIndex = val ?? 0;
                              });
                            },
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: ctrl,
                              decoration: InputDecoration(
                                labelText: isKey ? 'Pilihan $label (★ KUNCI BENAR)' : 'Pilihan $label',
                                labelStyle: TextStyle(
                                  color: isKey ? AppTheme.success : AppTheme.textSecondary,
                                  fontWeight: isKey ? FontWeight.bold : FontWeight.normal,
                                ),
                                isDense: true,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Pilihan $label tidak boleh kosong' : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (_legacyExtraOptions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pilihan Tambahan Terarsip (Legacy - Read Only):',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        ..._legacyExtraOptions.asMap().entries.map((e) {
                          final label = String.fromCharCode(70 + e.key); // F, G, ...
                          return Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '$label. ${e.value}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Simpan'),
        ),
      ],
    );
  }
}

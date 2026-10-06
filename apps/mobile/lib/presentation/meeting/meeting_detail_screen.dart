import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/auth/role_guard.dart';
import '../../core/theme/app_theme.dart';
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
              const SizedBox(height: 12),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Deskripsi / Ringkasan'),
                maxLines: 2,
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
    );

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

    final urlController = TextEditingController();
    VideoProvider selectedProvider = VideoProvider.youtube;
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Tambah Video Pembelajaran'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<VideoProvider>(
                  initialValue: selectedProvider,
                  decoration: const InputDecoration(labelText: 'Penyedia Video'),
                  items: const [
                    DropdownMenuItem(
                      value: VideoProvider.youtube,
                      child: Text('YouTube Video'),
                    ),
                    DropdownMenuItem(
                      value: VideoProvider.cloudinary,
                      child: Text('Cloudinary MP4 / Direct URL'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedProvider = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: urlController,
                  decoration: InputDecoration(
                    labelText: 'URL Video',
                    hintText: selectedProvider == VideoProvider.youtube
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final videoItem = VideoItem(
                    id: '',
                    meetingId: meeting.id,
                    classId: meeting.classId,
                    url: urlController.text.trim(),
                    provider: selectedProvider,
                  );
                  final videoId = await _videoRepository.createVideo(videoItem);
                  await _meetingRepository.linkModule(meeting.id, videoId: videoId);
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.error),
                    );
                  }
                }
              },
              child: const Text('Simpan Video'),
            ),
          ],
        ),
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
    final qTextController = TextEditingController(text: 'Pertanyaan konsep dasar');
    final optAController = TextEditingController(text: 'Jawaban Benar');
    final optBController = TextEditingController(text: 'Jawaban Salah');
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Kuis Pretest'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Judul Pretest'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Judul wajib diisi' : null,
                ),
                const SizedBox(height: 10),
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
                const Divider(height: 24),
                const Text('Soal Pertama (Pilihan Ganda):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: qTextController,
                  decoration: const InputDecoration(labelText: 'Teks Soal'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Soal wajib diisi' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: optAController,
                  decoration: const InputDecoration(labelText: 'Pilihan A (Kunci Benar)'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Pilihan A wajib diisi' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: optBController,
                  decoration: const InputDecoration(labelText: 'Pilihan B'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Pilihan B wajib diisi' : null,
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
                  status: ContentStatus.published,
                );
                final testId = await _pretestRepository.createPretest(pretest);

                final question = Question(
                  id: '',
                  text: qTextController.text.trim(),
                  options: [optAController.text.trim(), optBController.text.trim()],
                  points: 100,
                  tag: 'dasar',
                );
                await _pretestRepository.saveQuestionAndKey(
                  testId: testId,
                  question: question,
                  correctOptionIndex: 0,
                  explanation: 'Opsi A merupakan jawaban yang benar.',
                );

                await _meetingRepository.linkModule(meeting.id, pretestId: testId);
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            child: const Text('Simpan Pretest'),
          ),
        ],
      ),
    );

    if (created == true) {
      _loadMeetingDetail();
    }
  }

  Future<void> _showCreatePosttestDialog() async {
    final meeting = _meeting;
    if (meeting == null) return;

    final titleController = TextEditingController(text: 'Post Test Pertemuan ${meeting.number}');
    final durationController = TextEditingController(text: '20');
    final qTextController = TextEditingController(text: 'Pertanyaan evaluasi pemahaman');
    final optAController = TextEditingController(text: 'Jawaban Benar');
    final optBController = TextEditingController(text: 'Jawaban Salah');
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Kuis Post Test'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Judul Post Test'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Judul wajib diisi' : null,
                ),
                const SizedBox(height: 10),
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
                const Divider(height: 24),
                const Text('Soal Pertama (Pilihan Ganda):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: qTextController,
                  decoration: const InputDecoration(labelText: 'Teks Soal'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Soal wajib diisi' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: optAController,
                  decoration: const InputDecoration(labelText: 'Pilihan A (Kunci Benar)'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Pilihan A wajib diisi' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: optBController,
                  decoration: const InputDecoration(labelText: 'Pilihan B'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Pilihan B wajib diisi' : null,
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
                  status: ContentStatus.published,
                );
                final testId = await _posttestRepository.createPosttest(posttest);

                final question = Question(
                  id: '',
                  text: qTextController.text.trim(),
                  options: [optAController.text.trim(), optBController.text.trim()],
                  points: 100,
                  tag: 'evaluasi',
                );
                await _posttestRepository.saveQuestionAndKey(
                  testId: testId,
                  question: question,
                  correctOptionIndex: 0,
                  explanation: 'Opsi A merupakan jawaban evaluasi yang tepat.',
                );

                await _meetingRepository.linkModule(meeting.id, posttestId: testId);
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            child: const Text('Simpan Post Test'),
          ),
        ],
      ),
    );

    if (created == true) {
      _loadMeetingDetail();
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
            onTap: () {
              if (meeting.materiId != null) {
                context.push('/materials/${meeting.materiId}?classId=${meeting.classId}&meetingId=${meeting.id}');
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
            badgeNotice: meeting.pretestId != null ? 'Wajib pernah buka materi' : null,
            onTap: () {
              if (meeting.pretestId != null) {
                context.push('/pretests/${meeting.pretestId}?classId=${meeting.classId}&meetingId=${meeting.id}');
              } else if (isStaff) {
                _showCreatePretestDialog();
              }
            },
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
            onTap: () {
              if (meeting.videoId != null) {
                context.push('/videos/${meeting.videoId}?classId=${meeting.classId}&meetingId=${meeting.id}');
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
            onTap: () {
              if (meeting.posttestId != null) {
                context.push('/posttests/${meeting.posttestId}?classId=${meeting.classId}&meetingId=${meeting.id}');
              } else if (isStaff) {
                _showCreatePosttestDialog();
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

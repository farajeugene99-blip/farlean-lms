import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/auth/role_guard.dart';
import '../../core/theme/app_theme.dart';
import '../../models/class_member.dart';
import '../../models/classroom.dart';
import '../../models/content_status.dart';
import '../../models/meeting.dart';
import '../../repositories/class_repository.dart';
import '../../repositories/meeting_repository.dart';
import '../../services/auth_provider.dart';
import '../../services/class_provider.dart';
import '../common/error_view.dart';
import '../common/loading_indicator.dart';

class ClassDetailScreen extends StatefulWidget {
  final String classId;
  final ClassRepository? classRepository;
  final MeetingRepository? meetingRepository;

  const ClassDetailScreen({
    super.key,
    required this.classId,
    this.classRepository,
    this.meetingRepository,
  });

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen>
    with SingleTickerProviderStateMixin {
  late final ClassRepository _classRepository;
  late final MeetingRepository _meetingRepository;
  late final TabController _tabController;

  Classroom? _classroom;
  List<Meeting> _meetings = [];
  List<ClassMember> _members = [];
  Map<String, double> _classPretestScores = {};
  Map<String, double> _classPosttestScores = {};
  Map<String, double> _studentPersonalScores = {};
  String? _selectedMeetingId;
  int _gradebookPage = 0;
  static const int _pageSize = 50;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _classRepository = widget.classRepository ?? ClassRepository();
    _meetingRepository = widget.meetingRepository ?? MeetingRepository();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();
    final isStaff = RoleGuard.isStaff(authProvider.appUser);
    final uid = authProvider.firebaseUser?.uid ?? '';

    try {
      final classroom = await _classRepository.getClass(widget.classId);
      final meetings = await _meetingRepository.getMeetingsByClass(
        widget.classId,
        isStaff: isStaff,
      );
      final members = await _classRepository.getClassMembers(widget.classId);

      Map<String, double> preScores = {};
      Map<String, double> postScores = {};
      Map<String, double> personalScores = {};

      if (isStaff) {
        preScores = await _classRepository.getClassPretestScores(widget.classId);
        postScores = await _classRepository.getClassPosttestScores(widget.classId);
      } else if (uid.isNotEmpty) {
        personalScores = await _classRepository.getStudentScores(classId: widget.classId, uid: uid);
      }

      if (mounted) {
        setState(() {
          _classroom = classroom;
          _meetings = meetings;
          _members = members;
          _classPretestScores = preScores;
          _classPosttestScores = postScores;
          _studentPersonalScores = personalScores;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat detail kelas: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showCreateMeetingDialog() async {
    final titleController = TextEditingController();
    final numberController = TextEditingController(text: '${_meetings.length + 1}');
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Pertemuan Baru'),
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
                final meeting = Meeting(
                  id: '',
                  classId: widget.classId,
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
            child: const Text('Simpan Pertemuan'),
          ),
        ],
      ),
    ).whenComplete(() {
      titleController.dispose();
      numberController.dispose();
    });

    if (created == true) {
      _loadAllData();
    }
  }

  Future<void> _confirmArchiveClass() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Arsipkan Kelas?'),
        content: const Text(
          'Kelas yang diarsipkan akan terkunci untuk pengeditan dan tidak lagi menerima anggota baru. Anggota lama tetap dapat membaca materi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Arsipkan'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final classProvider = context.read<ClassProvider>();
        await classProvider.archiveClass(widget.classId);
        setState(() {
          _classroom = _classroom?.copyWith(status: 'Archived');
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kelas berhasil diarsipkan.'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengarsipkan: $e'), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  Future<void> _confirmReactivateClass() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aktifkan Kembali Kelas?'),
        content: const Text(
          'Kelas yang diaktifkan kembali akan dapat menerima anggota baru serta mengizinkan pengelolaan pertemuan dan kuis seperti semula.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aktifkan'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final classProvider = context.read<ClassProvider>();
        await classProvider.reactivateClass(widget.classId);
        setState(() {
          _classroom = _classroom?.copyWith(status: 'Active');
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kelas berhasil diaktifkan kembali.'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengaktifkan kembali kelas: $e'), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Memuat detail kelas...'),
      );
    }

    if (_errorMessage != null || _classroom == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Kelas')),
        body: ErrorView(
          message: _errorMessage ?? 'Kelas tidak ditemukan.',
          onRetry: _loadAllData,
        ),
      );
    }

    final classroom = _classroom!;
    final authProvider = context.watch<AuthProvider>();
    final isStaff = RoleGuard.isStaff(authProvider.appUser);
    final isOwner = isStaff && classroom.teacherId == authProvider.firebaseUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(classroom.name),
        actions: [
          if (isOwner && classroom.isActive)
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              tooltip: 'Arsipkan Kelas',
              onPressed: _confirmArchiveClass,
            ),
          if (isOwner && !classroom.isActive)
            IconButton(
              icon: const Icon(Icons.unarchive_outlined),
              tooltip: 'Aktifkan Kembali Kelas',
              onPressed: _confirmReactivateClass,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan',
            onPressed: _loadAllData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: isOwner && classroom.isActive
          ? FloatingActionButton.extended(
              onPressed: _showCreateMeetingDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Pertemuan'),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: Column(
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        classroom.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    _buildStatusBadge(classroom.status),
                  ],
                ),
                if (classroom.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    classroom.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: classroom.code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Kode kelas ${classroom.code} disalin ke clipboard.'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primary.withAlpha(40)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.key_rounded, size: 14, color: AppTheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              classroom.code,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.copy_rounded, size: 14, color: AppTheme.primary),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_members.length} Anggota',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•  ${_meetings.length} Pertemuan',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.calendar_month_rounded), text: 'Pertemuan'),
              Tab(icon: Icon(Icons.analytics_outlined), text: 'Rekap Nilai'),
              Tab(icon: Icon(Icons.people_alt_rounded), text: 'Anggota Kelas'),
            ],
          ),

          // Tab View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMeetingsTab(isOwner),
                _buildGradebookTab(isOwner, isStaff),
                _buildMembersTab(isStaff),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingsTab(bool isOwner) {
    if (_meetings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_month_outlined, size: 48, color: AppTheme.textSecondary.withAlpha(128)),
              const SizedBox(height: 12),
              Text('Belum Ada Pertemuan', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                isOwner
                    ? 'Buat pertemuan baru untuk mulai mengisi materi, pretest, dan video pembelajaran.'
                    : 'Pengajar belum mempublikasikan pertemuan di kelas ini.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (isOwner && _classroom?.isActive == true) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _showCreateMeetingDialog,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Buat Pertemuan'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _meetings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final meeting = _meetings[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primary.withAlpha(25),
              child: Text(
                '${meeting.number}',
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(meeting.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Row(
              children: [
                _buildModuleIcon(Icons.quiz_outlined, meeting.pretestId != null),
                const SizedBox(width: 8),
                _buildModuleIcon(Icons.menu_book_rounded, meeting.materiId != null),
                const SizedBox(width: 8),
                _buildModuleIcon(Icons.play_circle_outline_rounded, meeting.videoId != null),
              ],
            ),
            trailing: _buildStatusBadge(meeting.status.value),
            onTap: () async {
              await context.push('/meetings/${meeting.id}', extra: meeting);
              _loadAllData();
            },
          ),
        );
      },
    );
  }

  Widget _buildGradebookTab(bool isOwner, bool isStaff) {
    if (!isOwner && !isStaff) {
      return _buildStudentPersonalGradebook();
    }
    return _buildTeacherGradebook();
  }

  Widget _buildTeacherGradebook() {
    if (_members.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.analytics_outlined, size: 48, color: AppTheme.textSecondary.withAlpha(128)),
              const SizedBox(height: 12),
              const Text('Belum ada mahasiswa di kelas ini.', style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }

    Meeting? selectedMeeting;
    if (_selectedMeetingId != null) {
      for (final m in _meetings) {
        if (m.id == _selectedMeetingId) {
          selectedMeeting = m;
          break;
        }
      }
    }

    int preSubmittedCount = 0;
    double preTotalScore = 0;
    int postSubmittedCount = 0;
    double postTotalScore = 0;

    for (final member in _members) {
      if (selectedMeeting != null) {
        if (selectedMeeting.pretestId != null) {
          final s = _classPretestScores['${selectedMeeting.pretestId}_${member.uid}'];
          if (s != null) {
            preSubmittedCount++;
            preTotalScore += s;
          }
        }
        if (selectedMeeting.posttestId != null) {
          final s = _classPosttestScores['${selectedMeeting.posttestId}_${member.uid}'];
          if (s != null) {
            postSubmittedCount++;
            postTotalScore += s;
          }
        }
      }
    }

    final preAvg = preSubmittedCount > 0 ? (preTotalScore / preSubmittedCount).toStringAsFixed(1) : '-';
    final postAvg = postSubmittedCount > 0 ? (postTotalScore / postSubmittedCount).toStringAsFixed(1) : '-';

    final totalStudents = _members.length;
    final totalPages = (totalStudents / _pageSize).ceil();
    final safePage = _gradebookPage.clamp(0, totalPages > 0 ? totalPages - 1 : 0);
    final startIndex = safePage * _pageSize;
    final pagedMembers = _members.skip(startIndex).take(_pageSize).toList();
    final endIndex = (startIndex + pagedMembers.length);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedMeetingId,
              isExpanded: true,
              hint: const Text('Semua Pertemuan (Ringkasan)', style: TextStyle(fontSize: 13)),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Semua Pertemuan (Ringkasan)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                ..._meetings.map((m) => DropdownMenuItem<String?>(
                      value: m.id,
                      child: Text('Pertemuan ${m.number}: ${m.title}', style: const TextStyle(fontSize: 13)),
                    )),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedMeetingId = val;
                  _gradebookPage = 0;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 14),

        if (selectedMeeting != null) ...[
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  title: 'Rata-rata Pretest',
                  value: preAvg,
                  subtitle: '$preSubmittedCount dari $totalStudents mahasiswa',
                  color: AppTheme.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKpiCard(
                  title: 'Rata-rata Post Test',
                  value: postAvg,
                  subtitle: '$postSubmittedCount dari $totalStudents mahasiswa',
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border.withAlpha(100)),
          ),
          child: Row(
            children: [
              Text(
                'Menampilkan ${totalStudents > 0 ? startIndex + 1 : 0}-$endIndex dari $totalStudents mahasiswa',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: safePage > 0 ? () => setState(() => _gradebookPage = safePage - 1) : null,
              ),
              const SizedBox(width: 8),
              Text(
                '${safePage + 1}/$totalPages',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: safePage < totalPages - 1 ? () => setState(() => _gradebookPage = safePage + 1) : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        ...pagedMembers.map((member) {
          double? preScore;
          double? postScore;
          if (selectedMeeting != null) {
            if (selectedMeeting.pretestId != null) {
              preScore = _classPretestScores['${selectedMeeting.pretestId}_${member.uid}'];
            }
            if (selectedMeeting.posttestId != null) {
              postScore = _classPosttestScores['${selectedMeeting.posttestId}_${member.uid}'];
            }
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: AppTheme.border.withAlpha(100)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.primary.withAlpha(20),
                        child: Text(
                          member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primary),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          member.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Text(
                          member.accountType.name,
                          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (selectedMeeting != null)
                    Row(
                      children: [
                        Expanded(
                          child: _buildScoreChip(
                            label: 'Pretest',
                            hasModule: selectedMeeting.pretestId != null,
                            score: preScore,
                            accentColor: AppTheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildScoreChip(
                            label: 'Post Test',
                            hasModule: selectedMeeting.posttestId != null,
                            score: postScore,
                            accentColor: Colors.deepPurple,
                          ),
                        ),
                      ],
                    )
                  else
                    const Text(
                      'Pilih pertemuan spesifik di atas untuk melihat rincian skor mahasiswa.',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildKpiCard({required String title, required String value, required String subtitle, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildScoreChip({required String label, required bool hasModule, required double? score, required Color accentColor}) {
    if (!hasModule) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text('$label: -', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      );
    }
    final isDone = score != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDone ? accentColor.withAlpha(20) : AppTheme.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isDone ? accentColor.withAlpha(50) : AppTheme.warning.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isDone ? Icons.check_circle_outline_rounded : Icons.pending_outlined, size: 12, color: isDone ? accentColor : AppTheme.warning),
          const SizedBox(width: 4),
          Text(
            isDone ? '$label: ${score.toStringAsFixed(1)}' : '$label: Belum Ada',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDone ? accentColor : AppTheme.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentPersonalGradebook() {
    if (_meetings.isEmpty) {
      return const Center(
        child: Text('Belum ada pertemuan di kelas ini.', style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.primary.withAlpha(30)),
          ),
          child: Row(
            children: [
              const Icon(Icons.school_outlined, size: 24, color: AppTheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hasil Capaian Belajar Anda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary)),
                    Text('Menampilkan nilai resmi pretest & post test Anda pada kelas ${_classroom?.name ?? ""}.', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ..._meetings.map((meeting) {
          final preScore = meeting.pretestId != null ? _studentPersonalScores['pre_${meeting.pretestId}'] : null;
          final postScore = meeting.posttestId != null ? _studentPersonalScores['post_${meeting.posttestId}'] : null;

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: AppTheme.border.withAlpha(100)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pertemuan ${meeting.number}: ${meeting.title}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildScoreChip(
                          label: 'Pretest',
                          hasModule: meeting.pretestId != null,
                          score: preScore,
                          accentColor: AppTheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildScoreChip(
                          label: 'Post Test',
                          hasModule: meeting.posttestId != null,
                          score: postScore,
                          accentColor: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMembersTab(bool isStaff) {
    if (_members.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Belum ada anggota terdaftar di kelas ini.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _members.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final member = _members[index];
        final showNim = isStaff && member.nim != null && member.nim!.trim().isNotEmpty;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.primary.withAlpha(20),
            child: Text(
              member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?',
              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(member.displayName, style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: isStaff
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tipe: ${member.accountType} • Status: ${member.status.value}'),
                    if (showNim)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'NIM: ${member.nim}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                  ],
                )
              : null,
          trailing: isStaff ? _buildMemberStatusBadge(member.status) : null,
        );
      },
    );
  }

  Widget _buildModuleIcon(IconData icon, bool active) {
    return Icon(
      icon,
      size: 16,
      color: active ? AppTheme.primary : AppTheme.textSecondary.withAlpha(80),
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

  Widget _buildMemberStatusBadge(MemberStatus status) {
    Color color;
    switch (status) {
      case MemberStatus.active:
        color = AppTheme.success;
        break;
      case MemberStatus.pending:
        color = AppTheme.warning;
        break;
      case MemberStatus.removed:
        color = AppTheme.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.value.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

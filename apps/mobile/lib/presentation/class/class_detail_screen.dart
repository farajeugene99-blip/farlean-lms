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
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _classRepository = widget.classRepository ?? ClassRepository();
    _meetingRepository = widget.meetingRepository ?? MeetingRepository();
    _tabController = TabController(length: 2, vsync: this);
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

    try {
      final classroom = await _classRepository.getClass(widget.classId);
      final meetings = await _meetingRepository.getMeetingsByClass(
        widget.classId,
        isStaff: isStaff,
      );
      final members = await _classRepository.getClassMembers(widget.classId);

      if (mounted) {
        setState(() {
          _classroom = classroom;
          _meetings = meetings;
          _members = members;
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
            child: const Text('Simpan Draft'),
          ),
        ],
      ),
    );

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
              Tab(icon: Icon(Icons.people_alt_rounded), text: 'Anggota Kelas'),
            ],
          ),

          // Tab View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMeetingsTab(isOwner),
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
              ? Text('Tipe: ${member.accountType} • Status: ${member.status.value}')
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

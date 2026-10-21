import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/auth/role_guard.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/app_user.dart';
import '../../models/assignment.dart';
import '../../models/assignment_submission.dart';
import '../../models/class_group.dart';
import '../../models/class_member.dart';
import '../../models/classroom.dart';
import '../../models/content_status.dart';
import '../../models/meeting.dart';
import '../../repositories/assignment_repository.dart';
import '../../repositories/class_repository.dart';
import '../../repositories/group_repository.dart';
import '../../repositories/meeting_repository.dart';
import '../../services/auth_provider.dart';
import '../../services/class_provider.dart';
import '../common/error_view.dart';
import '../common/loading_indicator.dart';
import '../meeting/create_meeting_dialog.dart';
import 'create_assignment_dialog.dart';
import 'group_form_dialog.dart';

class ClassDetailScreen extends StatefulWidget {
  final String classId;
  final ClassRepository? classRepository;
  final MeetingRepository? meetingRepository;
  final GroupRepository? groupRepository;
  final AssignmentRepository? assignmentRepository;

  const ClassDetailScreen({
    super.key,
    required this.classId,
    this.classRepository,
    this.meetingRepository,
    this.groupRepository,
    this.assignmentRepository,
  });

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen>
    with SingleTickerProviderStateMixin {
  late final ClassRepository _classRepository;
  late final MeetingRepository _meetingRepository;
  late final GroupRepository _groupRepository;
  late final AssignmentRepository _assignmentRepository;
  late final TabController _tabController;

  Classroom? _classroom;
  List<Meeting> _meetings = [];
  List<ClassMember> _members = [];
  List<ClassGroup> _groups = [];
  List<Assignment> _assignments = [];
  Map<String, AssignmentSubmission> _classSubmissions = {};
  Map<String, double> _classPretestScores = {};
  Map<String, double> _classPosttestScores = {};
  Map<String, double> _studentPersonalScores = {};
  String? _selectedMeetingId;
  int _gradebookPage = 0;
  static const int _pageSize = 50;
  int _memberSubTab = 0;
  int _meetingsSubTab = 0;

  bool _isLoading = true;
  String? _errorMessage;
  bool _isPendingMember = false;

  @override
  void initState() {
    super.initState();
    _classRepository = widget.classRepository ?? ClassRepository();
    _meetingRepository = widget.meetingRepository ?? MeetingRepository();
    _groupRepository = widget.groupRepository ?? GroupRepository();
    _assignmentRepository = widget.assignmentRepository ?? AssignmentRepository();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData({bool isSoftRefresh = false}) async {
    if (!isSoftRefresh && _classroom == null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _isPendingMember = false;
      });
    }

    final authProvider = context.read<AuthProvider>();
    final isStaff = RoleGuard.isStaff(authProvider.appUser);
    final isAdmin = RoleGuard.canAccessAdmin(authProvider.appUser);
    final uid = authProvider.firebaseUser?.uid ?? '';

    try {
      Classroom? classroom = _classroom;
      try {
        classroom ??= await _classRepository.getClass(widget.classId);
      } catch (e) {
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('permission-denied') && uid.isNotEmpty) {
          final myMember = await _classRepository.getMyMembership(widget.classId, uid);
          if (myMember?.status == MemberStatus.pending) {
            if (mounted) {
              setState(() {
                _isPendingMember = true;
                _isLoading = false;
              });
            }
            return;
          }
        }
        rethrow;
      }

      if (classroom == null) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          setState(() {
            _errorMessage = l10n.classNotFound;
            _isLoading = false;
          });
        }
        return;
      }

      // Hitung otorisasi lokal: hanya pemilik kelas yang dianggap Guru pengajar di kelas ini
      final isClassTeacher = (classroom.teacherId == uid && isStaff) || isAdmin;

      // Subkoleksi diisolasi per blok try-catch agar kegagalan parsial
      // tidak membatalkan render kelas utama (Masalah B)
      List<Meeting> meetings = _meetings;
      try {
        meetings = await _meetingRepository.getMeetingsByClass(
          widget.classId,
          isStaff: isClassTeacher,
        );
      } catch (e) {
        debugPrint('Catatan getMeetingsByClass di ClassDetail: $e');
      }

      List<ClassMember> members = _members;
      try {
        members = await _classRepository.getClassMembers(widget.classId);
      } catch (e) {
        debugPrint('Catatan getClassMembers di ClassDetail: $e');
      }

      List<ClassGroup> groups = _groups;
      try {
        groups = await _groupRepository.getGroups(widget.classId);
      } catch (e) {
        debugPrint('Catatan getGroups di ClassDetail: $e');
      }

      List<Assignment> assignments = _assignments;
      try {
        assignments = await _assignmentRepository.getAssignmentsByClass(widget.classId);
      } catch (e) {
        debugPrint('Catatan getAssignmentsByClass di ClassDetail: $e');
      }

      Map<String, AssignmentSubmission> submissionsMap = _classSubmissions;
      if (isClassTeacher && assignments.isNotEmpty) {
        try {
          final subLists = await Future.wait(
            assignments.map((a) => _assignmentRepository.getAllSubmissions(classId: widget.classId, assignmentId: a.id)),
          );
          final Map<String, AssignmentSubmission> freshMap = {};
          for (int i = 0; i < assignments.length; i++) {
            final a = assignments[i];
            for (final s in subLists[i]) {
              freshMap['${a.id}_${s.id}'] = s;
            }
          }
          submissionsMap = freshMap;
        } catch (e) {
          debugPrint('Catatan prefetch submissions di ClassDetail: $e');
        }
      }

      Map<String, double> preScores = {};
      Map<String, double> postScores = {};
      Map<String, double> personalScores = {};

      if (isClassTeacher) {
        try {
          preScores = await _classRepository.getClassPretestScores(widget.classId);
          postScores = await _classRepository.getClassPosttestScores(widget.classId);
        } catch (e) {
          debugPrint('Catatan getClassScores di ClassDetail: $e');
        }
      } else if (uid.isNotEmpty) {
        try {
          personalScores = await _classRepository.getStudentScores(classId: widget.classId, uid: uid);
        } catch (e) {
          debugPrint('Catatan getStudentScores di ClassDetail: $e');
        }
      }

      if (mounted) {
        setState(() {
          _classroom = classroom;
          _meetings = meetings;
          _members = members;
          _groups = groups;
          _assignments = assignments;
          _classSubmissions = submissionsMap;
          _classPretestScores = preScores;
          _classPosttestScores = postScores;
          _studentPersonalScores = personalScores;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          if (_classroom == null) {
            _errorMessage = l10n.classDetailLoadFailed(e.toString());
          }
          _isLoading = false;
        });
        if (_classroom != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.classDetailLoadFailed(e.toString())), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  Future<void> _showCreateMeetingDialog() async {
    final l10n = AppLocalizations.of(context);
    final outerMessenger = ScaffoldMessenger.of(context);

    final formData = await showDialog<MeetingFormData>(
      context: context,
      builder: (ctx) => CreateMeetingDialog(
        initialNumber: _meetings.length + 1,
        submitButtonText: l10n.classSaveMeetingBtn,
      ),
    );

    if (formData != null && mounted) {
      try {
        final meeting = Meeting(
          id: '',
          classId: widget.classId,
          number: formData.number,
          title: formData.title,
          date: DateTime.now(),
          status: ContentStatus.draft,
        );
        await _meetingRepository.createMeeting(meeting);
        if (mounted) {
          _loadAllData();
        }
      } catch (e) {
        outerMessenger.showSnackBar(
          SnackBar(content: Text(l10n.meetingActionFailed(e.toString())), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _confirmArchiveClass() async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.classArchiveConfirmTitle),
        content: Text(
          l10n.classArchiveConfirmBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.btnCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.classArchiveBtn),
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
            SnackBar(
              content: Text(l10n.classArchiveSuccess),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.classArchiveFailed(e.toString())), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  Future<void> _confirmReactivateClass() async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.classReactivateConfirmTitle),
        content: Text(
          l10n.classReactivateConfirmBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.btnCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.classReactivateBtn),
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
            SnackBar(
              content: Text(l10n.classReactivateSuccess),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.classReactivateFailed(e.toString())), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        body: LoadingIndicator(message: l10n.classDetailLoading),
      );
    }

    if (_isPendingMember) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.classDetailTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.hourglass_top_rounded, size: 48, color: AppTheme.warning),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.classPendingTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.classPendingBody,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.textSecondaryColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(l10n.classPendingBackBtn),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null || _classroom == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.classDetailTitle)),
        body: ErrorView(
          message: _errorMessage ?? l10n.classNotFound,
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
              tooltip: l10n.classArchiveTooltip,
              onPressed: _confirmArchiveClass,
            ),
          if (isOwner && !classroom.isActive)
            IconButton(
              icon: const Icon(Icons.unarchive_outlined),
              tooltip: l10n.classReactivateTooltip,
              onPressed: _confirmReactivateClass,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.meetingRefreshTooltip,
            onPressed: _loadAllData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: isOwner && classroom.isActive
          ? FloatingActionButton.extended(
              onPressed: _showCreateMeetingDialog,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.meetingAddFab),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: Column(
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            color: context.surfaceColor,
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
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: classroom.code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.classCodeCopied(classroom.code)),
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          l10n.classMemberCount(_members.length),
                          style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                        ),
                        Text(
                          l10n.classMeetingCount(_meetings.length),
                          style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(icon: const Icon(Icons.calendar_month_rounded), text: l10n.classTabMeetings),
              Tab(icon: const Icon(Icons.analytics_outlined), text: l10n.classTabGrades),
              Tab(icon: const Icon(Icons.people_alt_rounded), text: l10n.classTabMembers),
            ],
          ),

          // Tab View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMeetingsTab(isOwner),
                _buildGradebookTab(isOwner, isStaff),
                _buildMembersTab(isOwner, isStaff),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingsTab(bool isOwner) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<int>(
                  segments: [
                    ButtonSegment<int>(
                      value: 0,
                      label: Text('${_meetings.length} ${l10n.classTabMeetings}'),
                      icon: const Icon(Icons.calendar_month_rounded, size: 16),
                    ),
                    ButtonSegment<int>(
                      value: 1,
                      label: Text(l10n.assignmentCount(_assignments.length)),
                      icon: const Icon(Icons.assignment_rounded, size: 16),
                    ),
                  ],
                  selected: {_meetingsSubTab},
                  onSelectionChanged: (set) {
                    setState(() => _meetingsSubTab = set.first);
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _meetingsSubTab == 1
              ? _buildAssignmentsList(isOwner)
              : _buildMeetingsList(isOwner),
        ),
      ],
    );
  }

  Widget _buildMeetingsList(bool isOwner) {
    final l10n = AppLocalizations.of(context);
    if (_meetings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_month_outlined, size: 48, color: context.textSecondaryColor.withAlpha(128)),
              const SizedBox(height: 12),
              Text(l10n.meetingEmptyTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                isOwner
                    ? l10n.classEmptyMeetingOwnerDesc
                    : l10n.classEmptyMeetingStudentDesc,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (isOwner && _classroom?.isActive == true) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _showCreateMeetingDialog,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.classCreateMeetingBtn),
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
            subtitle: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildModuleIcon(Icons.quiz_outlined, meeting.pretestId != null),
                _buildModuleIcon(Icons.menu_book_rounded, meeting.materiId != null),
                _buildModuleIcon(Icons.play_circle_outline_rounded, meeting.videoId != null),
                _buildModuleIcon(Icons.assignment_turned_in_rounded, meeting.posttestId != null),
                _buildModuleIcon(Icons.task_alt_rounded, meeting.assignmentId != null),
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

  // ============================================================================
  // SUBTAB TUGAS (FITUR D)
  // ============================================================================

  Widget _buildAssignmentsList(bool isOwner) {
    final l10n = AppLocalizations.of(context);

    if (_assignments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assignment_outlined, size: 48, color: context.textSecondaryColor.withAlpha(128)),
              const SizedBox(height: 12),
              Text(l10n.assignmentEmptyTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                l10n.assignmentEmptyDesc,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (isOwner && _classroom?.isActive == true) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _showCreateAssignmentDialog,
                  icon: const Icon(Icons.add_task_rounded),
                  label: Text(l10n.assignmentCreateBtn),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _assignments.length + (isOwner && _classroom?.isActive == true ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (isOwner && _classroom?.isActive == true && index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Text(
                  '${_assignments.length} ${l10n.tabAssignments}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: context.textSecondaryColor),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showCreateAssignmentDialog,
                  icon: const Icon(Icons.add_task_rounded, size: 16),
                  label: Text(l10n.assignmentCreateBtn),
                  style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ],
            ),
          );
        }

        final assignmentIndex = (isOwner && _classroom?.isActive == true) ? index - 1 : index;
        final assignment = _assignments[assignmentIndex];
        final deadlineStr = DateFormatter.formatWib(assignment.deadline);
        final isPast = DateTime.now().isAfter(assignment.deadline);

        return Card(
          elevation: 0.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: context.borderColor)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: (assignment.isGroupAssignment ? AppTheme.secondary : AppTheme.primary).withAlpha(25),
              child: Icon(
                assignment.isGroupAssignment ? Icons.groups_rounded : Icons.person_rounded,
                color: assignment.isGroupAssignment ? AppTheme.secondary : AppTheme.primary,
                size: 20,
              ),
            ),
            title: Text(assignment.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.event_outlined, size: 14, color: context.textSecondaryColor),
                    const SizedBox(width: 4),
                    Text(
                      deadlineStr,
                      style: TextStyle(fontSize: 11, color: isPast ? AppTheme.error : context.textSecondaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (assignment.isGroupAssignment ? AppTheme.secondary : AppTheme.primary).withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        assignment.isGroupAssignment ? l10n.assignmentGroupBadge : l10n.assignmentIndividualBadge,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: assignment.isGroupAssignment ? AppTheme.secondary : AppTheme.primary),
                      ),
                    ),
                    if (isPast)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.error.withAlpha(20), borderRadius: BorderRadius.circular(4)),
                        child: Text(l10n.assignmentStatusLate.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.error)),
                      ),
                  ],
                ),
              ],
            ),
            trailing: isOwner
                ? PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: context.textSecondaryColor, size: 20),
                    onSelected: (val) {
                      if (val == 'edit') _showEditAssignmentDialog(assignment);
                      if (val == 'delete') _confirmDeleteAssignment(assignment);
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Ubah Tugas'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 18),
                            const SizedBox(width: 8),
                            Text(l10n.meetingDeleteAction, style: const TextStyle(color: AppTheme.error)),
                          ],
                        ),
                      ),
                    ],
                  )
                : const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: () async {
              await context.push('/assignments/${assignment.id}?classId=${widget.classId}', extra: assignment);
              _loadAllData();
            },
          ),
        );
      },
    );
  }

  Future<void> _showCreateAssignmentDialog() async {
    final formData = await showDialog<AssignmentFormData>(
      context: context,
      builder: (ctx) => CreateAssignmentDialog(classId: widget.classId),
    );

    if (formData != null && mounted) {
      try {
        final newAssignment = Assignment(
          id: '',
          classId: widget.classId,
          title: formData.title,
          instructions: formData.instructions,
          deadline: formData.deadline,
          isGroupAssignment: formData.isGroup,
          allowLateSubmission: formData.allowLate,
          meetingId: formData.meetingId,
          attachmentUrl: formData.attachmentUrl,
          attachmentFileName: formData.attachmentFileName,
          attachmentFileSize: formData.attachmentFileSize,
        );
        await _assignmentRepository.createAssignment(newAssignment);
        if (mounted) {
          _loadAllData(isSoftRefresh: true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  Future<void> _showEditAssignmentDialog(Assignment assignment) async {
    final hasSubmissions = await _assignmentRepository.hasSubmissions(widget.classId, assignment.id);
    if (!mounted) return;

    final formData = await showDialog<AssignmentFormData>(
      context: context,
      builder: (ctx) => AssignmentFormDialog(
        initialAssignment: assignment,
        hasSubmissions: hasSubmissions,
        classId: widget.classId,
      ),
    );

    if (formData != null && mounted) {
      try {
        final updated = assignment.copyWith(
          title: formData.title,
          instructions: formData.instructions,
          deadline: formData.deadline,
          allowLateSubmission: formData.allowLate,
          isGroupAssignment: formData.isGroup,
          meetingId: formData.meetingId,
          clearMeetingId: formData.meetingId == null,
          attachmentUrl: formData.attachmentUrl,
          attachmentFileName: formData.attachmentFileName,
          attachmentFileSize: formData.attachmentFileSize,
          clearAttachment: formData.attachmentUrl == null,
        );
        await _assignmentRepository.updateAssignment(updated, previousMeetingId: assignment.meetingId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tugas berhasil diperbarui.'), backgroundColor: AppTheme.success),
          );
          _loadAllData(isSoftRefresh: true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  Future<void> _confirmDeleteAssignment(Assignment assignment) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.assignmentDeleteConfirmTitle),
        content: Text(l10n.assignmentDeleteConfirmDesc(assignment.title)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.btnCancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.meetingDeleteAction),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _assignmentRepository.deleteAssignment(widget.classId, assignment.id, meetingId: assignment.meetingId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.assignmentDeleteSuccess), backgroundColor: AppTheme.success),
          );
          _loadAllData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  Widget _buildGradebookTab(bool isOwner, bool isStaff) {
    final l10n = AppLocalizations.of(context);
    if (!isOwner && isStaff) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_person_outlined, size: 48, color: AppTheme.warning),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.classGradebookRestrictedTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.classGradebookRestrictedBody,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textSecondaryColor, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }
    if (!isOwner && !isStaff) {
      return _buildStudentPersonalGradebook();
    }
    return _buildTeacherGradebook();
  }

  Widget _buildTeacherGradebook() {
    final l10n = AppLocalizations.of(context);
    final studentMembers = _members.where((m) =>
        m.accountType == AccountType.mahasiswa &&
        m.status == MemberStatus.active
    ).toList();

    if (studentMembers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.analytics_outlined, size: 48, color: context.textSecondaryColor.withAlpha(128)),
              const SizedBox(height: 12),
              Text(l10n.classGradebookNoStudents, style: TextStyle(color: context.textSecondaryColor)),
            ],
          ),
        ),
      );
    }

    Meeting? selectedMeeting;
    Assignment? selectedAssignment;

    if (_selectedMeetingId != null) {
      if (_selectedMeetingId!.startsWith('assignment_')) {
        final assignId = _selectedMeetingId!.replaceFirst('assignment_', '');
        for (final a in _assignments) {
          if (a.id == assignId) {
            selectedAssignment = a;
            break;
          }
        }
      } else {
        for (final m in _meetings) {
          if (m.id == _selectedMeetingId) {
            selectedMeeting = m;
            break;
          }
        }
      }
    }

    int preSubmittedCount = 0;
    double preTotalScore = 0;
    int postSubmittedCount = 0;
    double postTotalScore = 0;

    int assignSubmittedCount = 0;
    int assignGradedCount = 0;
    double assignTotalScore = 0;

    for (final member in studentMembers) {
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
      } else if (selectedAssignment != null) {
        AssignmentSubmission? sub;
        if (selectedAssignment.isGroupAssignment) {
          if (member.groupId != null && member.groupId!.isNotEmpty) {
            sub = _classSubmissions['${selectedAssignment.id}_group_${member.groupId}'];
          }
        } else {
          sub = _classSubmissions['${selectedAssignment.id}_${member.uid}'];
        }

        if (sub != null) {
          assignSubmittedCount++;
          if (sub.status == SubmissionStatus.graded && sub.score != null) {
            assignGradedCount++;
            assignTotalScore += sub.score!;
          }
        }
      }
    }

    final preAvg = preSubmittedCount > 0 ? (preTotalScore / preSubmittedCount).toStringAsFixed(1) : '-';
    final postAvg = postSubmittedCount > 0 ? (postTotalScore / postSubmittedCount).toStringAsFixed(1) : '-';
    final assignAvg = assignGradedCount > 0 ? (assignTotalScore / assignGradedCount).toStringAsFixed(1) : '-';

    final totalStudents = studentMembers.length;
    final totalPages = (totalStudents / _pageSize).ceil();
    final safePage = _gradebookPage.clamp(0, totalPages > 0 ? totalPages - 1 : 0);
    final startIndex = safePage * _pageSize;
    final pagedMembers = studentMembers.skip(startIndex).take(_pageSize).toList();
    final endIndex = (startIndex + pagedMembers.length);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedMeetingId,
              isExpanded: true,
              hint: Text(l10n.classGradebookAllMeetingsHint, style: const TextStyle(fontSize: 13)),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.classGradebookAllMeetingsHint, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                ..._meetings.map((m) => DropdownMenuItem<String?>(
                      value: m.id,
                      child: Text(l10n.classMeetingNumberTitle(m.number, m.title), style: const TextStyle(fontSize: 13)),
                    )),
                ..._assignments.map((a) => DropdownMenuItem<String?>(
                      value: 'assignment_${a.id}',
                      child: Text(
                        '${a.isGroupAssignment ? "[Kelompok] " : "[Tugas] "}${a.title}',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
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
                  title: l10n.classKpiPretestAvg,
                  value: preAvg,
                  subtitle: l10n.classKpiSubCount(preSubmittedCount, totalStudents),
                  color: AppTheme.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKpiCard(
                  title: l10n.classKpiPosttestAvg,
                  value: postAvg,
                  subtitle: l10n.classKpiSubCount(postSubmittedCount, totalStudents),
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ] else if (selectedAssignment != null) ...[
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  title: 'Rata-rata Nilai Tugas',
                  value: assignAvg,
                  subtitle: '$assignGradedCount dari $totalStudents mahasiswa dinilai',
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKpiCard(
                  title: 'Terkumpul',
                  value: '$assignSubmittedCount',
                  subtitle: '$assignSubmittedCount dari $totalStudents telah mengumpulkan',
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  title: l10n.classKpiTotalMeetings,
                  value: '${_meetings.length}',
                  subtitle: l10n.classKpiQuizModulesCount(_meetings.where((m) => m.pretestId != null || m.posttestId != null).length),
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKpiCard(
                  title: l10n.classKpiTotalStudents,
                  value: '$totalStudents',
                  subtitle: l10n.classKpiEnrolledDesc,
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.borderColor.withAlpha(100)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.classPaginationInfo(totalStudents > 0 ? startIndex + 1 : 0, endIndex, totalStudents),
                  style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
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
              side: BorderSide(color: context.borderColor.withAlpha(100)),
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
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Text(
                          member.accountType.name,
                          style: TextStyle(fontSize: 10, color: context.textSecondaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (selectedAssignment != null)
                    _buildAssignmentStatusChip(assignment: selectedAssignment, student: member)
                  else if (selectedMeeting != null)
                    Row(
                      children: [
                        Expanded(
                          child: _buildScoreChip(
                            label: l10n.meetingModulePretest,
                            hasModule: selectedMeeting.pretestId != null,
                            score: preScore,
                            accentColor: AppTheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildScoreChip(
                            label: l10n.meetingModulePosttest,
                            hasModule: selectedMeeting.posttestId != null,
                            score: postScore,
                            accentColor: Colors.deepPurple,
                          ),
                        ),
                      ],
                    )
                  else
                    Builder(
                      builder: (context) {
                        int doneCount = 0;
                        int totalModules = 0;
                        final List<Widget> summaryChips = [];

                        for (final m in _meetings) {
                          if (m.pretestId != null) {
                            totalModules++;
                            final s = _classPretestScores['${m.pretestId}_${member.uid}'];
                            if (s != null) {
                              doneCount++;
                              summaryChips.add(_buildMiniSummaryChip('P${m.number} Pre', s, AppTheme.secondary));
                            }
                          }
                          if (m.posttestId != null) {
                            totalModules++;
                            final s = _classPosttestScores['${m.posttestId}_${member.uid}'];
                            if (s != null) {
                              doneCount++;
                              summaryChips.add(_buildMiniSummaryChip('P${m.number} Post', s, Colors.deepPurple));
                            }
                          }
                        }

                        // Ringkasan tugas
                        for (final a in _assignments) {
                          AssignmentSubmission? sub;
                          if (a.isGroupAssignment) {
                            if (member.groupId != null && member.groupId!.isNotEmpty) {
                              sub = _classSubmissions['${a.id}_group_${member.groupId}'];
                            }
                          } else {
                            sub = _classSubmissions['${a.id}_${member.uid}'];
                          }
                          if (sub != null && sub.score != null) {
                            summaryChips.add(_buildMiniSummaryChip(a.title.length > 8 ? '${a.title.substring(0, 8)}..' : a.title, sub.score!, AppTheme.primary));
                          }
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.assignment_turned_in_outlined, size: 14, color: AppTheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.classQuizProgress(doneCount, totalModules),
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimaryColor),
                                ),
                              ],
                            ),
                            if (summaryChips.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: summaryChips,
                              ),
                            ] else if (totalModules > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                l10n.classQuizNoneDone,
                                style: const TextStyle(fontSize: 11, color: AppTheme.warning),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAssignmentStatusChip({
    required Assignment assignment,
    required ClassMember student,
  }) {
    AssignmentSubmission? sub;
    if (assignment.isGroupAssignment) {
      if (student.groupId == null || student.groupId!.isEmpty) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: context.borderColor),
          ),
          child: const Text('Belum ada kelompok', style: TextStyle(fontSize: 11, color: Colors.grey)),
        );
      }
      sub = _classSubmissions['${assignment.id}_group_${student.groupId}'];
    } else {
      sub = _classSubmissions['${assignment.id}_${student.uid}'];
    }

    if (sub == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: context.borderColor),
        ),
        child: const Text('Belum Mengerjakan (-)', style: TextStyle(fontSize: 11, color: Colors.grey)),
      );
    }

    if (sub.status == SubmissionStatus.graded) {
      final isLate = (sub.submittedAt != null && sub.submittedAt!.isAfter(assignment.deadline));
      final label = isLate
          ? 'DINILAI (TERLAMBAT): ${sub.score!.toStringAsFixed(0)}'
          : 'DINILAI: ${sub.score!.toStringAsFixed(0)}';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.success.withAlpha(20),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isLate ? AppTheme.warning : AppTheme.success.withAlpha(50)),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isLate ? AppTheme.warning : AppTheme.success)),
      );
    }

    if (sub.status == SubmissionStatus.late) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.warning.withAlpha(20),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.warning.withAlpha(50)),
        ),
        child: const Text('TERLAMBAT (Menunggu Nilai)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.warning)),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.primary.withAlpha(50)),
      ),
      child: const Text('DIKUMPULKAN (Menunggu Nilai)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
    );
  }

  Widget _buildMiniSummaryChip(String label, double score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        '$label: ${score.toStringAsFixed(1)}',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
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
          Text(subtitle, style: TextStyle(fontSize: 10, color: context.textSecondaryColor)),
        ],
      ),
    );
  }

  Widget _buildScoreChip({required String label, required bool hasModule, required double? score, required Color accentColor}) {
    final l10n = AppLocalizations.of(context);
    if (!hasModule) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '$label: -',
          style: TextStyle(fontSize: 10, color: context.textSecondaryColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    final isDone = score != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: isDone ? accentColor.withAlpha(20) : AppTheme.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isDone ? accentColor.withAlpha(50) : AppTheme.warning.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDone ? Icons.check_circle_outline_rounded : Icons.pending_outlined,
            size: 12,
            color: isDone ? accentColor : AppTheme.warning,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              isDone ? '$label: ${score.toStringAsFixed(1)}' : '$label: ${l10n.classScoreNotAvailable}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDone ? accentColor : AppTheme.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentPersonalGradebook() {
    final l10n = AppLocalizations.of(context);
    if (_meetings.isEmpty) {
      return Center(
        child: Text(l10n.classNoMeetings, style: TextStyle(color: context.textSecondaryColor)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.primaryColor.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.primaryColor.withAlpha(30)),
          ),
          child: Row(
            children: [
              Icon(Icons.school_outlined, size: 24, color: context.primaryColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.classStudentProgressTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.primaryColor)),
                    Text(l10n.classStudentProgressBody(_classroom?.name ?? ''), style: TextStyle(fontSize: 11, color: context.textSecondaryColor)),
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
              side: BorderSide(color: context.borderColor.withAlpha(100)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.classMeetingNumberTitle(meeting.number, meeting.title), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildScoreChip(
                          label: l10n.meetingModulePretest,
                          hasModule: meeting.pretestId != null,
                          score: preScore,
                          accentColor: AppTheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildScoreChip(
                          label: l10n.meetingModulePosttest,
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

  Widget _buildMembersTab(bool isOwner, bool isStaff) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<int>(
                  segments: [
                    ButtonSegment<int>(
                      value: 0,
                      label: Text(l10n.classMemberCount(_members.length)),
                      icon: const Icon(Icons.person_rounded, size: 16),
                    ),
                    ButtonSegment<int>(
                      value: 1,
                      label: Text('${_groups.length} ${l10n.tabGroups}'),
                      icon: const Icon(Icons.groups_rounded, size: 16),
                    ),
                  ],
                  selected: {_memberSubTab},
                  onSelectionChanged: (set) {
                    setState(() => _memberSubTab = set.first);
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _memberSubTab == 1
              ? _buildGroupsTab(isOwner, isStaff)
              : _buildMembersList(isStaff),
        ),
      ],
    );
  }

  Widget _buildMembersList(bool isStaff) {
    final l10n = AppLocalizations.of(context);
    if (_members.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            l10n.classNoMembers,
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
        final String identityPrefix;
        if (member.accountType == AccountType.dosen) {
          identityPrefix = 'NIP';
        } else if (member.accountType == AccountType.mahasiswa) {
          identityPrefix = 'NIM';
        } else {
          identityPrefix = '';
        }

        final showIdentity = isStaff &&
            identityPrefix.isNotEmpty &&
            member.nim != null &&
            member.nim!.trim().isNotEmpty;

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
                    Text(l10n.classMemberTypeStatus(member.accountType.name, member.status.value)),
                    if (showIdentity)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '$identityPrefix: ${member.nim}',
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
      color: active ? context.primaryColor : context.textSecondaryColor.withAlpha(80),
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

  // ============================================================================
  // TAB KELOMPOK (FITUR E)
  // ============================================================================

  Widget _buildGroupsTab(bool isOwner, bool isStaff) {
    final l10n = AppLocalizations.of(context);

    if (_groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.groups_outlined,
                size: 56,
                color: context.textSecondaryColor.withAlpha(128),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.groupsEmptyTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.groupsEmptyDesc,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textSecondaryColor),
              ),
              if (isOwner) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _showCreateGroupDialog,
                  icon: const Icon(Icons.group_add_rounded),
                  label: Text(l10n.groupsCreateBtn),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isOwner)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text(
                    '${_groups.length} ${l10n.tabGroups}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: context.textSecondaryColor,
                        ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _showCreateGroupDialog,
                    icon: const Icon(Icons.group_add_rounded, size: 18),
                    label: Text(l10n.groupsCreateBtn),
                    style: ElevatedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
          ..._groups.map((group) => _buildGroupCard(group, isOwner)),
        ],
      ),
    );
  }

  Widget _buildGroupCard(ClassGroup group, bool isOwner) {
    final l10n = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: context.borderColor),
      ),
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
                  child: const Icon(Icons.groups_rounded, color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.groupsMemberCount(group.memberUids.length),
                        style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                      ),
                    ],
                  ),
                ),
                if (isOwner) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: l10n.meetingEditAction,
                    onPressed: () => _showEditGroupDialog(group),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
                    tooltip: l10n.meetingDeleteAction,
                    onPressed: () => _confirmDeleteGroup(group),
                  ),
                ],
              ],
            ),
            if (group.memberUids.isNotEmpty) ...[
              const Divider(height: 20),
              ...group.memberUids.map((uid) {
                final name = group.memberNames[uid] ?? 'Mahasiswa';
                final isLeader = uid == group.leaderUid;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: isLeader ? AppTheme.warning.withAlpha(30) : context.borderColor,
                        child: Icon(
                          isLeader ? Icons.star_rounded : Icons.person_rounded,
                          size: 14,
                          color: isLeader ? AppTheme.warning : context.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isLeader ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isLeader)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l10n.groupsLeaderLabel,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.warning),
                          ),
                        ),
                      if (isOwner && !isLeader)
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded, size: 16, color: context.textSecondaryColor),
                          onSelected: (val) {
                            if (val == 'leader') {
                              _setGroupLeader(group, uid);
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'leader',
                              child: Text(l10n.groupsSetLeader, style: const TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateGroupDialog() async {
    final l10n = AppLocalizations.of(context);
    List<ClassMember> availableMembers = [];
    try {
      availableMembers = await _groupRepository.getAvailableMembers(widget.classId);
    } catch (_) {
      availableMembers = [];
    }
    if (!mounted) return;

    final result = await showDialog<GroupDialogResult>(
      context: context,
      builder: (ctx) => GroupFormDialog(
        pool: availableMembers,
        initialSelected: const {},
        isEdit: false,
        existingGroupCount: _groups.length,
        classId: widget.classId,
      ),
    );

    if (result != null && mounted) {
      try {
        if (result.isRandom && result.randomGroups != null) {
          await _groupRepository.createRandomizedGroups(
            classId: widget.classId,
            groups: result.randomGroups!,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${result.randomGroups!.length} kelompok berhasil dibentuk secara acak.'),
                backgroundColor: AppTheme.success,
              ),
            );
            _loadAllData(isSoftRefresh: true);
          }
        } else if (result.manualGroup != null) {
          final formData = result.manualGroup!;
          await _groupRepository.createGroup(
            classId: widget.classId,
            name: formData.name,
            members: formData.selectedMembers,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.groupsCreateSuccess), backgroundColor: AppTheme.success),
            );
            _loadAllData(isSoftRefresh: true);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  Future<void> _showEditGroupDialog(ClassGroup group) async {
    final l10n = AppLocalizations.of(context);
    final currentMembers = _members.where((m) => group.memberUids.contains(m.uid)).toList();
    List<ClassMember> pool = [];

    try {
      final available = await _groupRepository.getAvailableMembers(widget.classId);
      final currentUids = currentMembers.map((m) => m.uid).toSet();
      final extraAvailable = available.where((m) => !currentUids.contains(m.uid)).toList();
      pool = [...currentMembers, ...extraAvailable];
    } catch (_) {
      pool = List.from(currentMembers);
    }
    if (!mounted) return;

    final result = await showDialog<GroupDialogResult>(
      context: context,
      builder: (ctx) => GroupFormDialog(
        initialName: group.name,
        pool: pool,
        initialSelected: currentMembers.toSet(),
        isEdit: true,
        classId: widget.classId,
      ),
    );

    if (result != null && result.manualGroup != null && mounted) {
      final formData = result.manualGroup!;
      try {
        final initialUids = group.memberUids.toSet();
        final currentSelectedUids = formData.selectedMembers.map((m) => m.uid).toSet();

        final newMembers = formData.selectedMembers.where((m) => !initialUids.contains(m.uid)).toList();
        final removedUids = initialUids.where((uid) => !currentSelectedUids.contains(uid)).toList();

        String? newLeader = group.leaderUid;
        if (newLeader != null && !currentSelectedUids.contains(newLeader)) {
          newLeader = formData.selectedMembers.isNotEmpty ? formData.selectedMembers.first.uid : null;
        }

        await _groupRepository.updateGroup(
          classId: widget.classId,
          groupId: group.id,
          name: formData.name,
          leaderUid: newLeader,
          newMembers: newMembers,
          removedMemberUids: removedUids,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.groupsEditSuccess), backgroundColor: AppTheme.success),
          );
          _loadAllData(isSoftRefresh: true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  Future<void> _confirmDeleteGroup(ClassGroup group) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.groupsDeleteConfirmTitle),
        content: Text(l10n.groupsDeleteConfirmDesc(group.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.btnCancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.meetingDeleteAction),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _groupRepository.deleteGroup(
          classId: widget.classId,
          groupId: group.id,
          memberUids: group.memberUids,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.groupsDeleteSuccess), backgroundColor: AppTheme.success),
          );
          _loadAllData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  Future<void> _setGroupLeader(ClassGroup group, String leaderUid) async {
    try {
      await _groupRepository.updateGroup(
        classId: widget.classId,
        groupId: group.id,
        name: group.name,
        leaderUid: leaderUid,
        newMembers: [],
        removedMemberUids: [],
      );
      _loadAllData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    }
  }
}

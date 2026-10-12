import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/auth/role_guard.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/app_user.dart';
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
        final l10n = AppLocalizations.of(context);
        setState(() {
          _errorMessage = l10n.classDetailLoadFailed(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showCreateMeetingDialog() async {
    final l10n = AppLocalizations.of(context);
    final titleController = TextEditingController();
    final numberController = TextEditingController(text: '${_meetings.length + 1}');
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.meetingCreateTitle),
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
                  decoration: InputDecoration(labelText: l10n.meetingNumberLabel),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return l10n.meetingNumberRequired;
                    final num = int.tryParse(v.trim());
                    if (num == null || num <= 0) return l10n.meetingNumberMustBePositive;
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: l10n.meetingTitleLabel),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return l10n.meetingTitleRequired;
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
            child: Text(l10n.btnCancel),
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
                    SnackBar(content: Text(l10n.meetingActionFailed(e.toString())), backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            child: Text(l10n.classSaveMeetingBtn),
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
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        Text(
                          l10n.classMeetingCount(_meetings.length),
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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
                _buildMembersTab(isStaff),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingsTab(bool isOwner) {
    final l10n = AppLocalizations.of(context);
    if (_meetings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_month_outlined, size: 48, color: AppTheme.textSecondary.withAlpha(128)),
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
                style: const TextStyle(color: AppTheme.textSecondary, height: 1.4),
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
    if (_members.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.analytics_outlined, size: 48, color: AppTheme.textSecondary.withAlpha(128)),
              const SizedBox(height: 12),
              Text(l10n.classGradebookNoStudents, style: const TextStyle(color: AppTheme.textSecondary)),
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
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border.withAlpha(100)),
          ),
          child: Row(
            children: [
              Text(
                l10n.classPaginationInfo(totalStudents > 0 ? startIndex + 1 : 0, endIndex, totalStudents),
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

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.assignment_turned_in_outlined, size: 14, color: AppTheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.classQuizProgress(doneCount, totalModules),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
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
          Text(subtitle, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildScoreChip({required String label, required bool hasModule, required double? score, required Color accentColor}) {
    final l10n = AppLocalizations.of(context);
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
            isDone ? '$label: ${score.toStringAsFixed(1)}' : '$label: ${l10n.classScoreNotAvailable}',
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
    final l10n = AppLocalizations.of(context);
    if (_meetings.isEmpty) {
      return Center(
        child: Text(l10n.classNoMeetings, style: const TextStyle(color: AppTheme.textSecondary)),
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
                    Text(l10n.classStudentProgressTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary)),
                    Text(l10n.classStudentProgressBody(_classroom?.name ?? ''), style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
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

  Widget _buildMembersTab(bool isStaff) {
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

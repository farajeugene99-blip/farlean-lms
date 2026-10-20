import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/auth/role_guard.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/assignment.dart';
import '../../models/assignment_submission.dart';
import '../../models/class_group.dart';
import '../../models/class_member.dart';
import '../../repositories/assignment_repository.dart';
import '../../repositories/class_repository.dart';
import '../../repositories/group_repository.dart';
import '../../services/auth_provider.dart';
import '../common/error_view.dart';
import '../common/loading_indicator.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final String assignmentId;
  final String classId;
  final Assignment? initialAssignment;
  final AssignmentRepository? assignmentRepository;
  final ClassRepository? classRepository;
  final GroupRepository? groupRepository;

  const AssignmentDetailScreen({
    super.key,
    required this.assignmentId,
    required this.classId,
    this.initialAssignment,
    this.assignmentRepository,
    this.classRepository,
    this.groupRepository,
  });

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  late final AssignmentRepository _assignmentRepository;
  late final ClassRepository _classRepository;
  late final GroupRepository _groupRepository;

  Assignment? _assignment;
  AssignmentSubmission? _mySubmission;
  List<AssignmentSubmission> _allSubmissions = [];
  ClassMember? _myMemberDoc;
  ClassGroup? _myGroupDoc;

  bool _isLoading = true;
  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _assignmentRepository = widget.assignmentRepository ?? AssignmentRepository();
    _classRepository = widget.classRepository ?? ClassRepository();
    _groupRepository = widget.groupRepository ?? GroupRepository();
    _assignment = widget.initialAssignment;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();
    final isStaff = RoleGuard.isStaff(authProvider.appUser);
    final uid = authProvider.firebaseUser?.uid ?? '';

    try {
      Assignment? assignment = _assignment;
      assignment ??= await _assignmentRepository.getAssignment(widget.classId, widget.assignmentId);

      if (assignment == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Tugas tidak ditemukan.';
            _isLoading = false;
          });
        }
        return;
      }

      AssignmentSubmission? mySub;
      List<AssignmentSubmission> allSubs = [];
      ClassMember? memberDoc;
      ClassGroup? groupDoc;

      if (isStaff) {
        allSubs = await _assignmentRepository.getAllSubmissions(
          classId: widget.classId,
          assignmentId: widget.assignmentId,
        );
      } else if (uid.isNotEmpty) {
        final members = await _classRepository.getClassMembers(widget.classId);
        memberDoc = members.cast<ClassMember?>().firstWhere((m) => m?.uid == uid, orElse: () => null);

        if (assignment.isGroupAssignment) {
          final groupId = memberDoc?.groupId;
          if (groupId != null && groupId.isNotEmpty) {
            final groups = await _groupRepository.getGroups(widget.classId);
            groupDoc = groups.cast<ClassGroup?>().firstWhere((g) => g?.id == groupId, orElse: () => null);
            mySub = await _assignmentRepository.getSubmission(
              classId: widget.classId,
              assignmentId: widget.assignmentId,
              submissionId: 'group_$groupId',
            );
          }
        } else {
          mySub = await _assignmentRepository.getSubmission(
            classId: widget.classId,
            assignmentId: widget.assignmentId,
            submissionId: uid,
          );
        }
      }

      if (mounted) {
        setState(() {
          _assignment = assignment;
          _mySubmission = mySub;
          _allSubmissions = allSubs;
          _myMemberDoc = memberDoc;
          _myGroupDoc = groupDoc;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openFile(String url) async {
    final l10n = AppLocalizations.of(context);
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.manualBookOpenPdfFailed), backgroundColor: AppTheme.error),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.manualBookOpenPdfError(e.toString())), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _showSubmitDialog({bool isResubmit = false}) async {
    final l10n = AppLocalizations.of(context);
    final assignment = _assignment;
    if (assignment == null) return;

    final urlController = TextEditingController(text: isResubmit ? _mySubmission?.fileUrl : '');
    final nameController = TextEditingController(text: isResubmit ? _mySubmission?.fileName : 'tugas_${assignment.isGroupAssignment ? "kelompok" : "mandiri"}.pdf');
    final noteController = TextEditingController(text: isResubmit ? _mySubmission?.note ?? '' : '');
    final formKey = GlobalKey<FormState>();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isResubmit ? l10n.assignmentResubmitBtn : l10n.assignmentSubmitBtn),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: urlController,
                    decoration: InputDecoration(
                      labelText: l10n.manualBookUrlLabel,
                      hintText: 'https://res.cloudinary.com/...',
                      prefixIcon: const Icon(Icons.link_rounded, size: 20),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return l10n.manualBookUrlRequired;
                      if (!v.trim().startsWith('https://')) return l10n.manualBookUrlInvalid;
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: l10n.assignmentFileLabel,
                      prefixIcon: const Icon(Icons.description_outlined, size: 20),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Nama berkas wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: l10n.assignmentFeedbackLabel,
                      hintText: 'Catatan tambahan (opsional)',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.btnCancel)),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx, true);
            },
            child: Text(l10n.btnSave),
          ),
        ],
      ),
    );

    if (submitted != true || !mounted) return;

    setState(() => _isSubmitting = true);
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.firebaseUser?.uid ?? '';
    final name = authProvider.appUser?.name ?? 'Mahasiswa';

    try {
      final now = DateTime.now();
      final isLate = now.isAfter(assignment.deadline);
      final status = isLate ? SubmissionStatus.late : SubmissionStatus.submitted;

      final submissionId = assignment.isGroupAssignment
          ? 'group_${_myMemberDoc?.groupId}'
          : uid;

      final sub = AssignmentSubmission(
        id: submissionId,
        assignmentId: assignment.id,
        classId: widget.classId,
        isGroup: assignment.isGroupAssignment,
        studentUid: assignment.isGroupAssignment ? null : uid,
        studentName: assignment.isGroupAssignment ? null : name,
        groupId: assignment.isGroupAssignment ? _myMemberDoc?.groupId : null,
        groupName: assignment.isGroupAssignment ? _myGroupDoc?.name : null,
        contributorIds: assignment.isGroupAssignment ? (_myGroupDoc?.memberUids ?? [uid]) : [uid],
        submittedByUid: uid,
        submittedByName: name,
        fileUrl: urlController.text.trim(),
        fileName: nameController.text.trim(),
        fileSize: 1048576, // default 1 MB placeholder
        note: noteController.text.trim(),
        status: status,
      );

      await _assignmentRepository.submitAssignment(sub);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.assignmentSubmitSuccess), backgroundColor: AppTheme.success),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.assignmentUploadFailed(e.toString())), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showGradeDialog(AssignmentSubmission submission) async {
    final l10n = AppLocalizations.of(context);
    final scoreController = TextEditingController(text: submission.score?.toStringAsFixed(0) ?? '');
    final feedbackController = TextEditingController(text: submission.feedback ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.assignmentGradeTitle),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: scoreController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.assignmentScoreLabel,
                    prefixIcon: const Icon(Icons.star_outline_rounded, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Nilai wajib diisi';
                    final numVal = double.tryParse(v.trim());
                    if (numVal == null || numVal < 0 || numVal > 100) {
                      return 'Masukkan angka 0 - 100';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: feedbackController,
                  decoration: InputDecoration(
                    labelText: l10n.assignmentFeedbackLabel,
                    hintText: 'Umpan balik untuk mahasiswa/kelompok',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.btnCancel)),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx, true);
            },
            child: Text(l10n.btnSave),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) return;

    final authProvider = context.read<AuthProvider>();
    final graderUid = authProvider.firebaseUser?.uid ?? '';

    try {
      final scoreVal = double.parse(scoreController.text.trim());
      await _assignmentRepository.gradeSubmission(
        classId: widget.classId,
        assignmentId: widget.assignmentId,
        submissionId: submission.id,
        score: scoreVal,
        feedback: feedbackController.text.trim(),
        graderUid: graderUid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.assignmentGradedSuccess), backgroundColor: AppTheme.success),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.assignmentDetailTitle)),
        body: const LoadingIndicator(message: 'Memuat detail tugas...'),
      );
    }

    if (_errorMessage != null || _assignment == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.assignmentDetailTitle)),
        body: ErrorView(message: _errorMessage ?? 'Tugas tidak ditemukan', onRetry: _loadData),
      );
    }

    final assignment = _assignment!;
    final authProvider = context.watch<AuthProvider>();
    final isStaff = RoleGuard.isStaff(authProvider.appUser);
    final isPastDeadline = DateTime.now().isAfter(assignment.deadline);
    final deadlineLocked = isPastDeadline && !assignment.allowLateSubmission;
    final isNoGroupInGroupAssignment = !isStaff && assignment.isGroupAssignment && (_myMemberDoc?.groupId == null || _myMemberDoc!.groupId!.isEmpty);

    return Scaffold(
      appBar: AppBar(
        title: Text(assignment.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.meetingRefreshTooltip,
            onPressed: _loadData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header Card
            _buildHeaderCard(assignment, isPastDeadline),
            const SizedBox(height: 16),

            // Petunjuk Pengerjaan
            if (assignment.instructions.isNotEmpty) ...[
              Text(l10n.assignmentInstructionsLabel, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: context.borderColor)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(assignment.instructions, style: TextStyle(fontSize: 13, height: 1.4, color: context.textPrimaryColor)),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Student View
            if (!isStaff) ...[
              if (isNoGroupInGroupAssignment)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.warning.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.assignmentNoGroupWarning,
                          style: const TextStyle(fontSize: 12, height: 1.4, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                )
              else if (deadlineLocked && _mySubmission == null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.error.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_clock_rounded, color: AppTheme.error, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.assignmentDeadlinePassedLocked,
                          style: const TextStyle(fontSize: 12, height: 1.4, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                if (_mySubmission != null)
                  _buildMySubmissionCard(_mySubmission!)
                else
                  _buildEmptySubmissionCard(),
              ],
            ],

            // Teacher View: Submissions List
            if (isStaff) ...[
              Row(
                children: [
                  Text(
                    l10n.assignmentSubmissionsCount(_allSubmissions.length),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_allSubmissions.isEmpty)
                Card(
                  elevation: 0.5,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Belum ada mahasiswa yang mengumpulkan tugas ini.',
                        style: TextStyle(fontSize: 13, color: context.textSecondaryColor),
                      ),
                    ),
                  ),
                )
              else
                ..._allSubmissions.map((sub) => _buildTeacherSubmissionCard(sub)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Assignment assignment, bool isPastDeadline) {
    final l10n = AppLocalizations.of(context);
    final deadlineStr = DateFormatter.formatWib(assignment.deadline);

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: context.borderColor)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (assignment.isGroupAssignment ? AppTheme.secondary : AppTheme.primary).withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    assignment.isGroupAssignment ? l10n.assignmentGroupBadge : l10n.assignmentIndividualBadge,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: assignment.isGroupAssignment ? AppTheme.secondary : AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isPastDeadline)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      l10n.assignmentStatusLate.toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.error),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(assignment.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.event_outlined, size: 16, color: context.textSecondaryColor),
                const SizedBox(width: 6),
                Text(
                  '${l10n.assignmentDeadlineLabel}: $deadlineStr',
                  style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMySubmissionCard(AssignmentSubmission submission) {
    final l10n = AppLocalizations.of(context);
    final isGraded = submission.status == SubmissionStatus.graded;
    Color statusColor = AppTheme.primary;
    String statusText = l10n.assignmentStatusSubmitted;

    if (submission.status == SubmissionStatus.late) {
      statusColor = AppTheme.warning;
      statusText = l10n.assignmentStatusLate;
    } else if (isGraded) {
      statusColor = AppTheme.success;
      statusText = l10n.assignmentStatusGraded;
    }

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: context.borderColor)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                  child: Text(statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                ),
                const Spacer(),
                if (submission.score != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.success.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      '${submission.score!.toStringAsFixed(0)} / 100',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.success),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.red.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 24),
              ),
              title: Text(submission.fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text(submission.fileUrl, style: TextStyle(fontSize: 11, color: context.textSecondaryColor), maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.open_in_new_rounded, size: 20),
                onPressed: () => _openFile(submission.fileUrl),
              ),
            ),
            if (submission.feedback != null && submission.feedback!.isNotEmpty) ...[
              const Divider(height: 20),
              Text(
                '${l10n.assignmentFeedbackLabel}:',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                submission.feedback!,
                style: TextStyle(fontSize: 13, color: context.textPrimaryColor),
              ),
            ],
            if (!isGraded && !_assignment!.isPastDeadline || (!isGraded && _assignment!.allowLateSubmission)) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : () => _showSubmitDialog(isResubmit: true),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(l10n.assignmentResubmitBtn),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySubmissionCard() {
    final l10n = AppLocalizations.of(context);
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: context.borderColor)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.upload_file_rounded, size: 48, color: context.textSecondaryColor.withAlpha(128)),
            const SizedBox(height: 12),
            Text(l10n.assignmentStatusNotSubmitted, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            Text('Unggah berkas tugas Anda sebelum batas waktu.', style: TextStyle(fontSize: 12, color: context.textSecondaryColor)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : () => _showSubmitDialog(isResubmit: false),
              icon: const Icon(Icons.upload_rounded),
              label: Text(l10n.assignmentSubmitBtn),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherSubmissionCard(AssignmentSubmission sub) {
    final l10n = AppLocalizations.of(context);
    final displayName = sub.isGroup ? (sub.groupName ?? 'Kelompok') : sub.submittedByName;
    final isGraded = sub.status == SubmissionStatus.graded;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: context.borderColor)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                        'Dikirim oleh: ${sub.submittedByName} • ${sub.fileName}',
                        style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                      ),
                    ],
                  ),
                ),
                if (sub.score != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppTheme.success.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                    child: Text('${sub.score!.toStringAsFixed(0)} / 100', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.success)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openFile(sub.fileUrl),
                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                  label: const Text('Buka Berkas', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showGradeDialog(sub),
                  icon: const Icon(Icons.grade_rounded, size: 14),
                  label: Text(isGraded ? 'Ubah Nilai' : l10n.assignmentGradeBtn, style: const TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/auth/role_guard.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/assignment.dart';
import '../../models/content_status.dart';
import '../../models/meeting.dart';
import '../../models/posttest.dart';
import '../../models/pretest.dart';
import '../../models/question.dart';
import '../../models/video_item.dart';
import '../../repositories/assignment_repository.dart';
import '../../repositories/meeting_repository.dart';
import '../../repositories/posttest_repository.dart';
import '../../repositories/pretest_repository.dart';
import '../../repositories/video_repository.dart';
import '../../services/auth_provider.dart';
import '../ai/ai_tutor_screen.dart';
import '../class/create_assignment_dialog.dart';
import '../common/error_view.dart';
import '../common/loading_indicator.dart';
import 'meeting_status_localization.dart';

class MeetingDetailScreen extends StatefulWidget {
  final String meetingId;
  final Meeting? initialMeeting;
  final MeetingRepository? meetingRepository;
  final VideoRepository? videoRepository;
  final PretestRepository? pretestRepository;
  final PosttestRepository? posttestRepository;
  final AssignmentRepository? assignmentRepository;

  const MeetingDetailScreen({
    super.key,
    required this.meetingId,
    this.initialMeeting,
    this.meetingRepository,
    this.videoRepository,
    this.pretestRepository,
    this.posttestRepository,
    this.assignmentRepository,
  });

  @override
  State<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends State<MeetingDetailScreen> {
  late final MeetingRepository _meetingRepository;
  late final VideoRepository _videoRepository;
  late final PretestRepository _pretestRepository;
  late final PosttestRepository _posttestRepository;
  late final AssignmentRepository _assignmentRepository;

  Meeting? _meeting;
  Assignment? _linkedAssignment;
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
    _assignmentRepository = widget.assignmentRepository ?? AssignmentRepository();

    _meeting = widget.initialMeeting;
    if (_meeting == null) {
      _loadMeetingDetail();
    } else {
      _isLoading = false;
      _loadLinkedAssignmentOnly();
    }
  }

  Future<void> _loadLinkedAssignmentOnly() async {
    final meeting = _meeting;
    if (meeting == null) return;
    try {
      Assignment? linkedAssign;
      if (meeting.assignmentId != null && meeting.assignmentId!.isNotEmpty) {
        try {
          linkedAssign = await _assignmentRepository.getAssignment(meeting.classId, meeting.assignmentId!);
        } catch (_) {}
      }
      if (linkedAssign == null) {
        try {
          linkedAssign = await _assignmentRepository.getAssignmentByMeeting(meeting.classId, meeting.id);
        } catch (_) {}
      }
      if (mounted && linkedAssign != null) {
        setState(() {
          _linkedAssignment = linkedAssign;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadMeetingDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final doc = await _meetingRepository.getMeeting(widget.meetingId);
      Assignment? linkedAssign;
      if (doc != null) {
        if (doc.assignmentId != null && doc.assignmentId!.isNotEmpty) {
          try {
            linkedAssign = await _assignmentRepository.getAssignment(doc.classId, doc.assignmentId!);
          } catch (_) {
            linkedAssign = null;
          }
        }
        if (linkedAssign == null) {
          try {
            linkedAssign = await _assignmentRepository.getAssignmentByMeeting(doc.classId, doc.id);
          } catch (_) {
            linkedAssign = null;
          }
        }
      }

      if (mounted) {
        setState(() {
          _meeting = doc;
          _linkedAssignment = linkedAssign;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _errorMessage = l10n.meetingLoadDetailFailed(e.toString());
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
    final l10n = AppLocalizations.of(context);
    final publishText = _meeting?.publishAt != null
        ? DateFormatter.formatWib(_meeting!.publishAt)
        : l10n.meetingScheduledFutureFallback;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.meetingScheduledLockedNotice(publishText)),
        backgroundColor: AppTheme.warning,
      ),
    );
  }

  Future<void> _showScheduleDialog() async {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    DateTime pickedDate = now.add(const Duration(days: 1));
    TimeOfDay pickedTime = const TimeOfDay(hour: 8, minute: 0);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: pickedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: l10n.meetingPickScheduleDateTitle,
    );
    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: pickedTime,
      helpText: l10n.meetingPickScheduleTimeTitle,
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.meetingScheduleMustBeFuture),
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
              l10n.meetingScheduledSuccess(DateFormatter.formatWib(scheduledDateTime)),
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.meetingScheduleFailed(e.toString())), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  /// Memicu promosi pertemuan terjadwal yang sudah jatuh tempo (khusus staf).
  /// Presisi jujur: promosi berjalan saat tombol/cron dipanggil, bukan tepat-menit otomatis.
  Future<void> _syncScheduledMeetings() async {
    if (_isSyncingSchedule) return;
    setState(() => _isSyncingSchedule = true);
    final l10n = AppLocalizations.of(context);
    try {
      final promoted = await _meetingRepository.syncScheduledMeetings(
        classId: _meeting?.classId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.meetingSyncScheduleSuccess(promoted)),
            backgroundColor: AppTheme.success,
          ),
        );
        await _loadMeetingDetail();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.meetingSyncFailed(e.toString())), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncingSchedule = false);
    }
  }

  Future<void> _updateStatus(ContentStatus newStatus) async {
    final l10n = AppLocalizations.of(context);
    final statusLabel = MeetingStatusLocalization.label(newStatus, l10n);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.meetingChangeStatusConfirmTitle(statusLabel)),
        content: Text(
          newStatus == ContentStatus.published
              ? l10n.meetingChangeStatusPublishBody
              : l10n.meetingChangeStatusArchiveBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.btnCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.btnConfirm),
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
              content: Text(l10n.meetingStatusChangedSuccess(statusLabel)),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.meetingActionFailed(e.toString())), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  Future<void> _showEditMeetingDialog() async {
    final meeting = _meeting;
    if (meeting == null) return;
    final l10n = AppLocalizations.of(context);

    final titleController = TextEditingController(text: meeting.title);
    final numberController = TextEditingController(text: '${meeting.number}');
    final descController = TextEditingController(text: meeting.description ?? '');
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.meetingEditDialogTitle),
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
                const SizedBox(height: 12),
                TextFormField(
                  controller: descController,
                  decoration: InputDecoration(labelText: l10n.meetingDescriptionLabel),
                  maxLines: 2,
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
                    SnackBar(content: Text(l10n.meetingActionFailed(e.toString())), backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            child: Text(l10n.btnSave),
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
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.meetingDeleteConfirmTitle),
        content: Text(
          l10n.meetingDeleteConfirmBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.btnCancel),
          ),
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
        await _meetingRepository.deleteMeeting(widget.meetingId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.meetingDeletedSuccess),
              backgroundColor: AppTheme.success,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.meetingDeleteFailed(e.toString())), backgroundColor: AppTheme.error),
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
    final l10n = AppLocalizations.of(context);

    final titleController = TextEditingController(text: l10n.meetingPretestDefaultTitle(meeting.number));
    final durationController = TextEditingController(text: '15');
    final formKey = GlobalKey<FormState>();

    String? createdTestId;
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.meetingCreatePretestTitle),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: l10n.meetingPretestTitleLabel),
                  validator: (v) => v == null || v.trim().isEmpty ? l10n.meetingTitleRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.meetingDurationLabel),
                  validator: (v) {
                    final num = int.tryParse(v?.trim() ?? '');
                    if (num == null || num <= 0) return l10n.meetingDurationMustBePositive;
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
                    SnackBar(content: Text(l10n.meetingActionFailed(e.toString())), backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            child: Text(l10n.meetingSaveAndManageQuestionsBtn),
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
    final l10n = AppLocalizations.of(context);

    final titleController = TextEditingController(text: l10n.meetingPosttestDefaultTitle(meeting.number));
    final durationController = TextEditingController(text: '20');
    final formKey = GlobalKey<FormState>();

    String? createdTestId;
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.meetingCreatePosttestTitle),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: l10n.meetingPosttestTitleLabel),
                  validator: (v) => v == null || v.trim().isEmpty ? l10n.meetingTitleRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.meetingDurationLabel),
                  validator: (v) {
                    final num = int.tryParse(v?.trim() ?? '');
                    if (num == null || num <= 0) return l10n.meetingDurationMustBePositive;
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
                    SnackBar(content: Text(l10n.meetingActionFailed(e.toString())), backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            child: Text(l10n.meetingSaveAndManageQuestionsBtn),
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

  Future<void> _showCreateAssignmentForMeeting() async {
    final meeting = _meeting;
    if (meeting == null) return;

    final formData = await showDialog<AssignmentFormData>(
      context: context,
      builder: (ctx) => AssignmentFormDialog(
        preselectedMeetingId: meeting.id,
        classId: meeting.classId,
      ),
    );

    if (formData != null && mounted) {
      try {
        final newAssignment = Assignment(
          id: '',
          classId: meeting.classId,
          meetingId: meeting.id,
          title: formData.title,
          instructions: formData.instructions,
          deadline: formData.deadline,
          isGroupAssignment: formData.isGroup,
          allowLateSubmission: formData.allowLate,
          attachmentUrl: formData.attachmentUrl,
          attachmentFileName: formData.attachmentFileName,
          attachmentFileSize: formData.attachmentFileSize,
        );
        final newId = await _assignmentRepository.createAssignment(newAssignment);
        setState(() {
          _meeting = _meeting?.copyWith(assignmentId: newId);
        });
        await _loadMeetingDetail();
      } catch (e) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.meetingActionFailed(e.toString())), backgroundColor: AppTheme.error),
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
        body: LoadingIndicator(message: l10n.meetingDetailLoading),
      );
    }

    if (_errorMessage != null || _meeting == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.meetingDetailTitle)),
        body: ErrorView(
          message: _errorMessage ?? l10n.meetingNotFound,
          onRetry: _loadMeetingDetail,
        ),
      );
    }

    final meeting = _meeting!;
    final authProvider = context.watch<AuthProvider>();
    final isStaff = RoleGuard.isStaff(authProvider.appUser);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.meetingCardNumber(meeting.number)),
        actions: [
          if (!_isScheduledLockedForStudent)
            IconButton(
              icon: const Icon(Icons.auto_awesome_rounded),
              tooltip: l10n.aiTutorTitle,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AiTutorScreen(
                      classId: meeting.classId,
                      meetingId: meeting.id,
                      materiId: meeting.materiId,
                      materiTitle: meeting.title,
                      initialPrompt: 'Bisa berikan ringkasan materi untuk pertemuan "${meeting.title}"?',
                    ),
                  ),
                );
              },
            ),
          if (isStaff) ...[
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: l10n.meetingEditTooltip,
              onPressed: _showEditMeetingDialog,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: l10n.meetingDeleteTooltip,
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
              tooltip: l10n.meetingSyncTooltip,
              onPressed: _isSyncingSchedule ? null : _syncScheduledMeetings,
            ),
            PopupMenuButton<String>(
              tooltip: l10n.meetingManageStatusTooltip,
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
                  PopupMenuItem(
                    value: 'publish',
                    child: Text(l10n.meetingMenuPublishNow),
                  ),
                if (meeting.status != ContentStatus.scheduled)
                  PopupMenuItem(
                    value: 'schedule',
                    child: Text(l10n.meetingMenuSchedule),
                  ),
                if (meeting.status != ContentStatus.draft)
                  PopupMenuItem(
                    value: 'draft',
                    child: Text(l10n.meetingMenuDraft),
                  ),
                if (meeting.status != ContentStatus.archived)
                  PopupMenuItem(
                    value: 'archive',
                    child: Text(l10n.meetingMenuArchive),
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
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l10n.meetingCardNumber(meeting.number),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      _buildStatusBadge(meeting.status, l10n),
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
                        : l10n.meetingDefaultDescription,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (meeting.status == ContentStatus.scheduled) ...[
                    const SizedBox(height: 12),
                    () {
                      final schedColor = context.isDarkMode ? const Color(0xFF60A5FA) : Colors.blue;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: schedColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: schedColor.withAlpha(60)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.schedule_rounded, size: 20, color: schedColor),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.meetingScheduledBannerTitle,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: schedColor),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    meeting.publishAt != null
                                        ? l10n.meetingScheduledBanner(DateFormatter.formatWib(meeting.publishAt))
                                        : l10n.meetingScheduledBannerFallback,
                                    style: TextStyle(fontSize: 12, color: schedColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }(),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            l10n.meetingModulesTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          // 1. Modul Materi Card
          _buildModuleCard(
            title: l10n.meetingModuleMaterialTitle,
            subtitle: meeting.materiId != null
                ? l10n.meetingModuleMaterialSubActive
                : (isStaff ? l10n.meetingModuleMaterialSubStaffEmpty : l10n.meetingModuleMaterialSubStudentEmpty),
            icon: Icons.menu_book_rounded,
            accentColor: AppTheme.primary,
            isAvailable: meeting.materiId != null || isStaff,
            actionLabel: meeting.materiId != null ? l10n.meetingModuleMaterialActionOpen : l10n.meetingModuleMaterialActionCreate,
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
            title: l10n.meetingModulePretestTitle,
            subtitle: meeting.pretestId != null
                ? l10n.meetingModulePretestSubActive
                : (isStaff ? l10n.meetingModulePretestSubStaffEmpty : l10n.meetingModulePretestSubStudentEmpty),
            icon: Icons.quiz_outlined,
            accentColor: AppTheme.secondary,
            isAvailable: meeting.pretestId != null || isStaff,
            actionLabel: meeting.pretestId != null ? l10n.meetingModulePretestActionStart : l10n.meetingModulePretestActionCreate,
            secondaryActionLabel: (isStaff && meeting.pretestId != null) ? l10n.meetingModulePretestManageQuestions : null,
            badgeNotice: meeting.pretestId != null ? l10n.meetingModulePretestBadgeNotice : null,
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
            title: l10n.meetingModuleVideoTitle,
            subtitle: meeting.videoId != null
                ? l10n.meetingModuleVideoSubActive
                : (isStaff ? l10n.meetingModuleVideoSubStaffEmpty : l10n.meetingModuleVideoSubStudentEmpty),
            icon: Icons.play_circle_outline_rounded,
            accentColor: AppTheme.warning,
            isAvailable: meeting.videoId != null || isStaff,
            actionLabel: meeting.videoId != null ? l10n.meetingModuleVideoActionWatch : l10n.meetingModuleVideoActionAdd,
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
            title: l10n.meetingModulePosttestTitle,
            subtitle: meeting.posttestId != null
                ? l10n.meetingModulePosttestSubActive
                : (isStaff ? l10n.meetingModulePosttestSubStaffEmpty : l10n.meetingModulePosttestSubStudentEmpty),
            icon: Icons.assignment_turned_in_rounded,
            accentColor: context.isDarkMode ? const Color(0xFFC084FC) : Colors.deepPurple,
            isAvailable: meeting.posttestId != null || isStaff,
            actionLabel: meeting.posttestId != null ? l10n.meetingModulePosttestActionStart : l10n.meetingModulePosttestActionCreate,
            secondaryActionLabel: (isStaff && meeting.posttestId != null) ? l10n.meetingModulePretestManageQuestions : null,
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
          const SizedBox(height: 12),

          // 5. Modul Tugas Pembelajaran Card
          _buildModuleCard(
            title: l10n.meetingModuleAssignmentTitle,
            subtitle: _linkedAssignment != null
                ? (_linkedAssignment!.isGroupAssignment
                    ? '${l10n.assignmentGroupBadge} • ${DateFormatter.formatWib(_linkedAssignment!.deadline)}'
                    : '${l10n.assignmentIndividualBadge} • ${DateFormatter.formatWib(_linkedAssignment!.deadline)}')
                : (isStaff ? l10n.meetingModuleAssignmentSubStaffEmpty : l10n.meetingModuleAssignmentSubStudentEmpty),
            icon: Icons.task_alt_rounded,
            accentColor: Colors.teal,
            isAvailable: _linkedAssignment != null || isStaff,
            actionLabel: _linkedAssignment != null ? l10n.meetingModuleAssignmentActionOpen : l10n.meetingModuleAssignmentActionCreate,
            onTap: () async {
              if (_isScheduledLockedForStudent) {
                _showScheduledLockNotice();
                return;
              }
              if (_linkedAssignment != null) {
                await context.push('/assignments/${_linkedAssignment!.id}?classId=${meeting.classId}', extra: _linkedAssignment);
                if (mounted) _loadMeetingDetail();
              } else if (isStaff) {
                _showCreateAssignmentForMeeting();
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
    String? secondaryActionLabel,
    String? badgeNotice,
    required VoidCallback onTap,
    VoidCallback? onSecondaryTap,
  }) {
    final l10n = AppLocalizations.of(context);

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
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      if (badgeNotice != null)
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
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: context.textSecondaryColor),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: isAvailable ? onTap : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAvailable ? accentColor : context.borderColor,
                          minimumSize: const Size(120, 38),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Text(
                          isAvailable ? actionLabel : l10n.meetingModuleNotAvailable,
                          style: TextStyle(
                            fontSize: 13,
                            color: isAvailable ? Colors.white : context.textSecondaryColor,
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

  Widget _buildStatusBadge(ContentStatus status, AppLocalizations l10n) {
    Color color;
    switch (status) {
      case ContentStatus.published:
        color = AppTheme.success;
        break;
      case ContentStatus.scheduled:
        color = context.isDarkMode ? const Color(0xFF60A5FA) : Colors.blue;
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
        MeetingStatusLocalization.label(status, l10n),
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
    final l10n = AppLocalizations.of(context);
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
          SnackBar(content: Text(l10n.meetingActionFailed(e.toString())), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.meetingAddVideoTitle),
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
                decoration: InputDecoration(
                  labelText: l10n.meetingVideoProviderLabel,
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
                  labelText: l10n.meetingVideoUrlLabel,
                  hintText: _selectedProvider == VideoProvider.youtube
                      ? 'https://www.youtube.com/watch?v=...'
                      : 'https://res.cloudinary.com/...',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l10n.meetingVideoUrlRequired;
                  if (!v.trim().startsWith('https://')) {
                    return l10n.meetingVideoUrlInvalid;
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
          child: Text(l10n.btnCancel),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.meetingSaveVideoBtn),
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
    final l10n = AppLocalizations.of(context);
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.meetingPublishMinOneQuestion),
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
          SnackBar(
            content: Text(l10n.meetingQuizPublishedSuccess),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPublishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.meetingPublishFailed(e.toString())), backgroundColor: AppTheme.error),
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
    final l10n = AppLocalizations.of(context);

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
                                  l10n.meetingManageQuestionsTitle(widget.testTitle),
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
                                      MeetingStatusLocalization.labelUpperCase(_status, l10n),
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
                              l10n.meetingQuestionCountActive(questions.length),
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
                        tooltip: l10n.btnClose,
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
                        label: Text(l10n.meetingAddQuestionBtn),
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
                          label: Text(l10n.meetingPublishQuizBtn),
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
                            Icon(Icons.quiz_outlined, size: 48, color: context.textSecondaryColor.withAlpha(100)),
                            const SizedBox(height: 12),
                            Text(
                              l10n.meetingDraftNoQuestionsTitle,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.meetingDraftNoQuestionsBody,
                              style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
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
                                  side: BorderSide(color: context.borderColor),
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
                                              color: context.backgroundColor,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: context.borderColor),
                                            ),
                                            child: Text(
                                              l10n.meetingPointsLabel(q.points),
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
                                                color: context.backgroundColor,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: context.borderColor),
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
                                                      style: TextStyle(fontSize: 12, color: context.textPrimaryColor),
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
                                            label: Text(l10n.meetingEditAction),
                                            onPressed: () => _openEditor(q),
                                          ),
                                          TextButton.icon(
                                            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.error),
                                            label: Text(l10n.meetingDeleteAction, style: const TextStyle(color: AppTheme.error)),
                                            onPressed: () async {
                                              final messenger = ScaffoldMessenger.of(context);
                                              if (_status == ContentStatus.published && sortedQuestions.length <= 1) {
                                                messenger.showSnackBar(
                                                  SnackBar(
                                                    content: Text(l10n.meetingCannotDeleteLastPublished),
                                                    backgroundColor: AppTheme.error,
                                                  ),
                                                );
                                                return;
                                              }

                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (dCtx) => AlertDialog(
                                                  title: Text(l10n.meetingDeleteQuestionConfirmTitle),
                                                  content: Text(
                                                    l10n.meetingDeleteQuestionConfirmBody(idx + 1),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(dCtx, false),
                                                      child: Text(l10n.btnCancel),
                                                    ),
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                                                      onPressed: () => Navigator.pop(dCtx, true),
                                                      child: Text(l10n.meetingDeleteQuestionBtn),
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
                                                    SnackBar(content: Text(l10n.meetingDeleteFailed(e.toString())), backgroundColor: AppTheme.error),
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
    final l10n = AppLocalizations.of(context);

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
          SnackBar(content: Text(l10n.meetingActionFailed(e.toString())), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(widget.existing == null ? l10n.meetingAddQuestionDialogTitle : l10n.meetingEditQuestionDialogTitle),
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
                  decoration: InputDecoration(
                    labelText: l10n.meetingQuestionTextLabel,
                    hintText: l10n.meetingQuestionTextHint,
                  ),
                  maxLines: 3,
                  validator: (v) => v == null || v.trim().isEmpty ? l10n.meetingQuestionTextRequired : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pointsController,
                  decoration: InputDecoration(
                    labelText: l10n.meetingQuestionPointsLabel,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return l10n.meetingQuestionPointsRequired;
                    final parsed = int.tryParse(v.trim());
                    if (parsed == null || parsed < 1 || parsed > 100) return l10n.meetingQuestionPointsInvalid;
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.meetingOptionsSectionTitle,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.meetingOptionsSectionSubtitle,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
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
                        color: isKey ? AppTheme.success.withAlpha(20) : context.backgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isKey ? AppTheme.success.withAlpha(120) : context.borderColor,
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
                                labelText: isKey ? l10n.meetingOptionLabelKey(label) : l10n.meetingOptionLabelRegular(label),
                                labelStyle: TextStyle(
                                  color: isKey ? AppTheme.success : context.textSecondaryColor,
                                  fontWeight: isKey ? FontWeight.bold : FontWeight.normal,
                                ),
                                isDense: true,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? l10n.meetingOptionRequired(label) : null,
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
                      color: context.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.meetingLegacyOptionsTitle,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.textSecondaryColor),
                        ),
                        const SizedBox(height: 4),
                        ..._legacyExtraOptions.asMap().entries.map((e) {
                          final label = String.fromCharCode(70 + e.key); // F, G, ...
                          return Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '$label. ${e.value}',
                              style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
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
          child: Text(l10n.btnCancel),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.btnSave),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/auth/role_guard.dart';
import '../../core/config/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/content_status.dart';
import '../../models/meeting.dart';
import '../../repositories/meeting_repository.dart';
import '../../services/auth_provider.dart';
import '../../services/class_provider.dart';
import '../common/error_view.dart';
import '../common/loading_indicator.dart';
import 'meeting_status_localization.dart';

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

  @override
  void didUpdateWidget(covariant MeetingListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classId != widget.classId) {
      _loadMeetings();
    }
  }

  String _getEffectiveClassId() {
    final classProvider = context.read<ClassProvider>();
    final fromWidget = widget.classId?.trim() ?? '';
    if (fromWidget.isNotEmpty && fromWidget != 'default_class') {
      return fromWidget;
    }
    return classProvider.selectedClassId ??
        (classProvider.hasSingleClass ? classProvider.singleClassId ?? '' : '');
  }

  Future<void> _loadMeetings({String? targetClassId}) async {
    final effectiveClassId = targetClassId ?? _getEffectiveClassId();

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
        final l10n = AppLocalizations.of(context);
        String friendlyMessage;
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('permission-denied') || errorString.contains('evaluation error')) {
          friendlyMessage = isStaff
              ? l10n.meetingErrorPermissionStaff
              : l10n.meetingErrorPermissionStudent;
        } else if (errorString.contains('network') || errorString.contains('unavailable')) {
          friendlyMessage = l10n.meetingErrorNetwork;
        } else {
          friendlyMessage = l10n.meetingErrorLoadFailed(e.toString());
        }

        setState(() {
          _errorMessage = friendlyMessage;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showCreateMeetingDialog() async {
    final l10n = AppLocalizations.of(context);
    final effectiveClassId = _getEffectiveClassId();
    if (effectiveClassId.isEmpty || effectiveClassId == 'default_class') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.meetingSelectClassFirst),
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
                    SnackBar(content: Text(l10n.meetingCreateFailed(e.toString())), backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            child: Text(l10n.meetingSaveDraftBtn),
          ),
        ],
      ),
    ).whenComplete(() {
      titleController.dispose();
      numberController.dispose();
    });

    if (created == true) {
      _loadMeetings();
    }
  }

  bool _isSyncingSchedule = false;

  Future<void> _syncScheduledMeetings() async {
    if (_isSyncingSchedule) return;
    setState(() => _isSyncingSchedule = true);
    final l10n = AppLocalizations.of(context);
    try {
      final promoted = await _meetingRepository.syncScheduledMeetings(
        classId: _getEffectiveClassId().isEmpty ? null : _getEffectiveClassId(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.meetingSyncScheduleSuccess(promoted)),
            backgroundColor: AppTheme.success,
          ),
        );
        _loadMeetings();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = context.watch<AuthProvider>();
    final isStaff = RoleGuard.isStaff(authProvider.appUser);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.meetingListTitle),
        actions: [
          if (isStaff)
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
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.meetingRefreshTooltip,
            onPressed: _loadMeetings,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: isStaff
          ? FloatingActionButton.extended(
              onPressed: _showCreateMeetingDialog,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.meetingAddFab),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: _buildBody(isStaff),
    );
  }

  Widget _buildBody(bool isStaff) {
    final l10n = AppLocalizations.of(context);
    final classProvider = context.watch<ClassProvider>();
    final effectiveClassId = _getEffectiveClassId();
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
                l10n.meetingNoClassTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.meetingNoClassBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => context.push(AppConstants.joinClassRoute),
                icon: const Icon(Icons.key_rounded),
                label: Text(l10n.meetingJoinClassBtn),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (classProvider.allClasses.isNotEmpty)
          _buildClassSelectorBar(classProvider, effectiveClassId),
        Expanded(
          child: _isLoading
              ? LoadingIndicator(message: l10n.meetingLoading)
              : _errorMessage != null
                  ? ErrorView(message: _errorMessage!, onRetry: _loadMeetings)
                  : _meetings.isEmpty
                      ? _buildEmptyMeetingsView(isStaff)
                      : RefreshIndicator(
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
                        ),
        ),
      ],
    );
  }

  Widget _buildClassSelectorBar(ClassProvider classProvider, String effectiveClassId) {
    if (classProvider.allClasses.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border.withAlpha(100))),
      ),
      child: Row(
        children: [
          const Icon(Icons.school_outlined, size: 20, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(l10n.meetingClassLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: classProvider.allClasses.any((c) => c.id == effectiveClassId)
                    ? effectiveClassId
                    : classProvider.allClasses.first.id,
                items: classProvider.allClasses.map((c) {
                  return DropdownMenuItem<String>(
                    value: c.id,
                    child: Text(
                      c.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
                onChanged: (newId) {
                  if (newId != null && newId != effectiveClassId) {
                    classProvider.selectClass(newId);
                    context.go('${AppConstants.materiRoute}?classId=$newId');
                    _loadMeetings(targetClassId: newId);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMeetingsView(bool isStaff) {
    final l10n = AppLocalizations.of(context);

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
              l10n.meetingEmptyTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              isStaff
                  ? l10n.meetingEmptyStaffDesc
                  : l10n.meetingEmptyStudentDesc,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (isStaff) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _showCreateMeetingDialog,
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.meetingCreateFirstBtn),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingCard(Meeting meeting, bool isStaff) {
    final l10n = AppLocalizations.of(context);

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
                  if (isStaff || meeting.status == ContentStatus.scheduled)
                    _buildStatusBadge(meeting.status, l10n),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                meeting.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (meeting.status == ContentStatus.scheduled && meeting.publishAt != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      l10n.meetingPublishAtLabel(DateFormatter.formatWib(meeting.publishAt)),
                      style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildModuleChip(
                    Icons.quiz_outlined,
                    l10n.meetingModulePretest,
                    meeting.pretestId != null,
                  ),
                  _buildModuleChip(
                    Icons.menu_book_rounded,
                    l10n.meetingModuleMateri,
                    meeting.materiId != null,
                  ),
                  _buildModuleChip(
                    Icons.play_circle_outline_rounded,
                    l10n.meetingModuleVideo,
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

  Widget _buildStatusBadge(ContentStatus status, AppLocalizations l10n) {
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
        MeetingStatusLocalization.label(status, l10n),
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

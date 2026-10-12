import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/auth/role_guard.dart';
import '../../core/config/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/discussion.dart';
import '../../repositories/discussion_repository.dart';
import '../../services/auth_provider.dart';
import '../../services/class_provider.dart';
import '../common/error_view.dart';
import '../common/loading_indicator.dart';

class DiscussionListScreen extends StatefulWidget {
  final String? classId;
  final DiscussionRepository? discussionRepository;

  const DiscussionListScreen({
    super.key,
    this.classId,
    this.discussionRepository,
  });

  @override
  State<DiscussionListScreen> createState() => _DiscussionListScreenState();
}

class _DiscussionListScreenState extends State<DiscussionListScreen> {
  late final DiscussionRepository _discussionRepository;
  List<Discussion> _discussions = [];
  Map<String, DateTime> _readTimes = {};
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedFilterIndex = 0; // 0: Semua, 1: Belum Dibalas, 2: Belum Dibaca
  int _discussionsGen = 0;

  @override
  void initState() {
    super.initState();
    _discussionRepository = widget.discussionRepository ?? DiscussionRepository();
    _loadDiscussions();
  }

  @override
  void didUpdateWidget(covariant DiscussionListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classId != widget.classId) {
      _loadDiscussions();
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

  Future<void> _loadDiscussions({String? targetClassId}) async {
    _discussionsGen++;
    final currentGen = _discussionsGen;
    final effectiveClassId = targetClassId ?? _getEffectiveClassId();

    if (effectiveClassId.isEmpty || effectiveClassId == 'default_class') {
      if (mounted && currentGen == _discussionsGen) {
        setState(() {
          _discussions = [];
          _isLoading = false;
          _errorMessage = null;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final authProvider = context.read<AuthProvider>();
    final isStaff = RoleGuard.isStaff(authProvider.appUser);

    try {
      final list = await _discussionRepository.getDiscussions(
        classId: effectiveClassId,
        isStaff: isStaff,
        filterUnanswered: _selectedFilterIndex == 1,
      );

      final uid = authProvider.appUser?.uid;
      Map<String, DateTime> readStates = {};
      if (uid != null && list.isNotEmpty) {
        readStates = await _discussionRepository.getReadStatesForDiscussions(
          userId: uid,
          discussionIds: list.map((d) => d.id).toList(),
        );
      }

      List<Discussion> displayList = list;
      if (_selectedFilterIndex == 2 && uid != null) {
        displayList = list.where((thread) {
          final readTime = readStates[thread.id];
          if (readTime != null) {
            final activity = thread.lastActivityAt ?? thread.createdAt ?? DateTime.now();
            return activity.isAfter(readTime);
          } else {
            // Thread belum pernah ada record baca: jika dibuat sendiri dan belum ada reply -> bukan unread
            if (thread.authorId == uid && thread.replyCount == 0) return false;
            return true;
          }
        }).toList();
      }

      if (mounted && currentGen == _discussionsGen) {
        setState(() {
          _discussions = displayList;
          _readTimes = readStates;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && currentGen == _discussionsGen) {
        final l10n = AppLocalizations.of(context);
        String friendlyMessage;
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('permission-denied') || errorString.contains('evaluation error')) {
          friendlyMessage = isStaff
              ? l10n.discussionErrorPermissionStaff
              : l10n.discussionErrorPermissionStudent;
        } else if (errorString.contains('network') || errorString.contains('unavailable')) {
          friendlyMessage = l10n.meetingErrorNetwork;
        } else {
          friendlyMessage = l10n.discussionErrorLoadFailed(e.toString());
        }

        setState(() {
          _errorMessage = friendlyMessage;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showCreateThreadDialog() async {
    final l10n = AppLocalizations.of(context);
    final effectiveClassId = _getEffectiveClassId();
    if (effectiveClassId.isEmpty || effectiveClassId == 'default_class') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.discussionSelectClassFirst),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final clientRequestId = 'req_${DateTime.now().millisecondsSinceEpoch}_${identityHashCode(formKey)}';
    bool isSubmitting = false;

    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return PopScope(
            canPop: !isSubmitting,
            child: AlertDialog(
              title: Text(l10n.discussionCreateTitle),
              content: SizedBox(
                width: 460,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: titleController,
                          enabled: !isSubmitting,
                          decoration: InputDecoration(
                            labelText: l10n.discussionTitleLabel,
                            hintText: l10n.discussionTitleHint,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().length < 3) return l10n.discussionTitleMinLength;
                            if (v.trim().length > 200) return l10n.discussionTitleMaxLength;
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: bodyController,
                          enabled: !isSubmitting,
                          decoration: InputDecoration(
                            labelText: l10n.discussionBodyLabel,
                            hintText: l10n.discussionBodyHint,
                          ),
                          maxLines: 4,
                          validator: (v) {
                            if (v == null || v.trim().length < 3) return l10n.discussionBodyMinLength;
                            if (v.trim().length > 5000) return l10n.discussionBodyMaxLength;
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx, false),
                  child: Text(l10n.btnCancel),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSubmitting = true);
                          try {
                            await _discussionRepository
                                .createThread(
                                  classId: effectiveClassId,
                                  title: titleController.text.trim(),
                                  body: bodyController.text.trim(),
                                  clientRequestId: clientRequestId,
                                )
                                .timeout(const Duration(seconds: 15));
                            if (ctx.mounted) Navigator.pop(ctx, true);
                          } catch (e) {
                            if (ctx.mounted) {
                              setDialogState(() => isSubmitting = false);
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text(l10n.meetingActionFailed(e.toString())), backgroundColor: AppTheme.error),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l10n.discussionSendBtn),
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() {
      titleController.dispose();
      bodyController.dispose();
    });

    if (created == true && mounted) {
      _loadDiscussions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.discussionForumTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.meetingRefreshTooltip,
            onPressed: _loadDiscussions,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateThreadDialog,
        icon: const Icon(Icons.add_comment_rounded),
        label: Text(l10n.discussionCreateFab),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
                Icons.forum_outlined,
                size: 56,
                color: AppTheme.textSecondary.withAlpha(128),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.discussionNoClassTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.discussionNoClassBody,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
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
        _buildFilterBar(),
        Expanded(
          child: _isLoading
              ? LoadingIndicator(message: l10n.discussionLoading)
              : _errorMessage != null
                  ? ErrorView(message: _errorMessage!, onRetry: _loadDiscussions)
                  : _discussions.isEmpty
                      ? _buildEmptyDiscussionView()
                      : RefreshIndicator(
                          onRefresh: _loadDiscussions,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                            itemCount: _discussions.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final thread = _discussions[index];
                              return _buildThreadCard(thread, effectiveClassId);
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildClassSelectorBar(ClassProvider classProvider, String effectiveClassId) {
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
                    context.go('${AppConstants.diskusiRoute}?classId=$newId');
                    _loadDiscussions(targetClassId: newId);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ChoiceChip(
              label: Text(l10n.discussionFilterAll),
              selected: _selectedFilterIndex == 0,
              onSelected: (selected) {
                if (selected && _selectedFilterIndex != 0) {
                  setState(() => _selectedFilterIndex = 0);
                  _loadDiscussions();
                }
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(l10n.discussionFilterUnanswered),
              selected: _selectedFilterIndex == 1,
              onSelected: (selected) {
                if (selected && _selectedFilterIndex != 1) {
                  setState(() => _selectedFilterIndex = 1);
                  _loadDiscussions();
                }
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(l10n.discussionFilterUnread),
              selected: _selectedFilterIndex == 2,
              onSelected: (selected) {
                if (selected && _selectedFilterIndex != 2) {
                  setState(() => _selectedFilterIndex = 2);
                  _loadDiscussions();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDiscussionView() {
    final l10n = AppLocalizations.of(context);
    String emptyTitle = l10n.discussionEmptyAllTitle;
    String emptyDesc = l10n.discussionEmptyAllDesc;

    if (_selectedFilterIndex == 1) {
      emptyTitle = l10n.discussionEmptyUnansweredTitle;
      emptyDesc = l10n.discussionEmptyUnansweredDesc;
    } else if (_selectedFilterIndex == 2) {
      emptyTitle = l10n.discussionEmptyUnreadTitle;
      emptyDesc = l10n.discussionEmptyUnreadDesc;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 56,
              color: AppTheme.textSecondary.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              emptyTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              emptyDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreadCard(Discussion thread, String classId) {
    final l10n = AppLocalizations.of(context);
    final isArchived = thread.status == DiscussionStatus.archived;
    final uid = context.read<AuthProvider>().appUser?.uid;
    final readTime = _readTimes[thread.id];
    bool isUnread = false;
    if (uid != null && !isArchived) {
      if (readTime != null) {
        final activity = thread.lastActivityAt ?? thread.createdAt ?? DateTime.now();
        isUnread = activity.isAfter(readTime);
      } else {
        if (thread.authorId != uid || thread.replyCount > 0) {
          isUnread = true;
        }
      }
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppTheme.border.withAlpha(120)),
      ),
      child: InkWell(
        onTap: () async {
          _discussionRepository.markAsRead(classId: classId, discussionId: thread.id);
          await context.push('/diskusi/${thread.id}?classId=$classId');
          if (mounted) {
            _loadDiscussions();
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isUnread) ...[
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        color: AppTheme.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                  Expanded(
                    child: Text(
                      thread.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isArchived)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l10n.meetingStatusArchived,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.warning),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                thread.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person_outline_rounded, size: 14, color: AppTheme.textSecondary.withAlpha(180)),
                  const SizedBox(width: 4),
                  Text(
                    thread.authorDisplayName,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 13, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          l10n.discussionReplyCount(thread.replyCount),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

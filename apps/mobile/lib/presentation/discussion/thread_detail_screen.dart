import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth/role_guard.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/discussion.dart';
import '../../repositories/discussion_repository.dart';
import '../../services/auth_provider.dart';
import '../common/error_view.dart';
import '../common/loading_indicator.dart';

class ThreadDetailScreen extends StatefulWidget {
  final String discussionId;
  final String classId;
  final DiscussionRepository? discussionRepository;

  const ThreadDetailScreen({
    super.key,
    required this.discussionId,
    required this.classId,
    this.discussionRepository,
  });

  @override
  State<ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends State<ThreadDetailScreen> {
  late final DiscussionRepository _discussionRepository;
  Discussion? _thread;
  List<DiscussionReply> _replies = [];
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();
  DiscussionReply? _replyingTo;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _discussionRepository = widget.discussionRepository ?? DiscussionRepository();
    _loadThreadAndReplies();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadThreadAndReplies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();
    final isStaff = RoleGuard.isStaff(authProvider.appUser);

    try {
      final thread = await _discussionRepository.getDiscussion(widget.discussionId);
      if (thread == null) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          setState(() {
            _errorMessage = l10n.discussionNotFound;
            _isLoading = false;
          });
        }
        return;
      }

      final replies = await _discussionRepository.getReplies(
        discussionId: widget.discussionId,
        isStaff: isStaff,
      );

      if (mounted) {
        setState(() {
          _thread = thread;
          _replies = replies;
          _isLoading = false;
        });
        _discussionRepository.markAsRead(
          classId: widget.classId,
          discussionId: widget.discussionId,
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _errorMessage = l10n.discussionLoadDetailFailed(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _isSending || _thread == null) return;
    final l10n = AppLocalizations.of(context);

    if (_thread!.status == DiscussionStatus.archived) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.discussionArchivedSendBlocked),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    final clientReplyId = 'rep_${DateTime.now().millisecondsSinceEpoch}_${widget.discussionId.hashCode}';

    try {
      await _discussionRepository
          .postReply(
            discussionId: widget.discussionId,
            body: text,
            clientReplyId: clientReplyId,
            parentId: _replyingTo?.id,
          )
          .timeout(const Duration(seconds: 15));

      _replyController.clear();
      _replyingTo = null;
      // Reload replies dan thread metadata (agar reply_count naik)
      await _loadThreadAndReplies();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.discussionSendReplyFailed(e.toString())), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _confirmArchiveThread() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.discussionArchiveConfirmTitle),
        content: Text(
          l10n.discussionArchiveConfirmBody,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.btnCancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.classArchiveBtn),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _discussionRepository.archiveThread(discussionId: widget.discussionId);
        await _loadThreadAndReplies();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.discussionArchiveSuccess), backgroundColor: AppTheme.success),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.discussionArchiveFailed(e.toString())), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  Future<void> _showEditThreadDialog() async {
    if (_thread == null) return;
    final l10n = AppLocalizations.of(context);
    final titleCtrl = TextEditingController(text: _thread!.title);
    final bodyCtrl = TextEditingController(text: _thread!.body);
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.discussionEditTitle),
        content: SizedBox(
          width: 460,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleCtrl,
                  decoration: InputDecoration(labelText: l10n.discussionEditTitleLabel),
                  validator: (v) => v == null || v.trim().length < 3 ? l10n.discussionTitleMinLength : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: bodyCtrl,
                  decoration: InputDecoration(labelText: l10n.discussionEditBodyLabel),
                  maxLines: 4,
                  validator: (v) => v == null || v.trim().length < 3 ? l10n.discussionBodyMinLength : null,
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
              try {
                await _discussionRepository.updateThread(
                  discussionId: widget.discussionId,
                  title: titleCtrl.text.trim(),
                  body: bodyCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(l10n.discussionUpdateFailed(e.toString())), backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            child: Text(l10n.btnSave),
          ),
        ],
      ),
    ).whenComplete(() {
      titleCtrl.dispose();
      bodyCtrl.dispose();
    });

    if (updated == true) {
      _loadThreadAndReplies();
    }
  }

  Widget _buildReplyCard({
    required DiscussionReply reply,
    required bool isChild,
    required bool isArchived,
    required bool isStaff,
    required dynamic currentUser,
  }) {
    final l10n = AppLocalizations.of(context);
    final isReplyAuthor = currentUser?.uid == reply.authorId;
    return Card(
      margin: EdgeInsets.only(bottom: isChild ? 6 : 10),
      elevation: isChild ? 0 : 0.5,
      color: isChild ? (context.isDarkMode ? AppTheme.surfaceVariantDark : context.cardColor) : context.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isChild
              ? context.borderColor.withAlpha(70)
              : context.borderColor.withAlpha(120),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: isChild ? 10 : 12,
                  backgroundColor: isChild
                      ? AppTheme.primary.withAlpha(20)
                      : AppTheme.secondary.withAlpha(20),
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: isChild ? 12 : 14,
                    color: isChild ? AppTheme.primary : AppTheme.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        reply.authorDisplayName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      if (isChild && reply.parentAuthorName != null && reply.parentAuthorName!.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_right_rounded, size: 14, color: context.textSecondaryColor),
                        Text(
                          '@${reply.parentAuthorName}',
                          style: TextStyle(fontSize: 11, color: context.primaryColor, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isArchived && (isReplyAuthor || isStaff))
                  IconButton(
                    icon: Icon(Icons.archive_outlined, size: 16, color: context.textSecondaryColor),
                    tooltip: l10n.discussionArchiveReplyTooltip,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () async {
                      try {
                        await _discussionRepository.archiveReply(
                          discussionId: widget.discussionId,
                          replyId: reply.id,
                        );
                        await _loadThreadAndReplies();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.meetingActionFailed(e.toString())), backgroundColor: AppTheme.error),
                          );
                        }
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              reply.body,
              style: TextStyle(fontSize: 13, height: 1.4, color: context.textPrimaryColor),
            ),
            if (!isArchived) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () {
                    setState(() => _replyingTo = reply);
                    _replyFocusNode.requestFocus();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.reply_rounded, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          l10n.discussionReplyAction,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        body: LoadingIndicator(message: l10n.discussionThreadLoading),
      );
    }

    if (_errorMessage != null || _thread == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.discussionDetailTitle)),
        body: ErrorView(
          message: _errorMessage ?? l10n.discussionNotFound,
          onRetry: _loadThreadAndReplies,
        ),
      );
    }

    final thread = _thread!;
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.appUser;
    final isAuthor = currentUser?.uid == thread.authorId;
    final isStaff = RoleGuard.isStaff(currentUser);
    final isArchived = thread.status == DiscussionStatus.archived;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.discussionDetailTitle),
        actions: [
          if (!isArchived && isAuthor)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.discussionEditTooltip,
              onPressed: _showEditThreadDialog,
            ),
          if (!isArchived && (isAuthor || isStaff))
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              tooltip: l10n.discussionArchiveTooltip,
              onPressed: _confirmArchiveThread,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.meetingRefreshTooltip,
            onPressed: _loadThreadAndReplies,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadThreadAndReplies,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Thread Header Card
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: context.borderColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppTheme.primary.withAlpha(25),
                                child: const Icon(Icons.person_rounded, color: AppTheme.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      thread.authorDisplayName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      isArchived ? l10n.discussionStatusArchivedTag : l10n.discussionStatusActiveTag,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isArchived ? AppTheme.warning : AppTheme.success,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            thread.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            thread.body,
                            style: TextStyle(fontSize: 14, height: 1.5, color: context.textPrimaryColor),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 18, color: context.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        l10n.discussionDetailReplyCount(_replies.length),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_replies.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(Icons.mark_chat_read_outlined, size: 40, color: context.textSecondaryColor.withAlpha(100)),
                            const SizedBox(height: 8),
                            Text(
                              l10n.discussionNoRepliesYet,
                              style: TextStyle(color: context.textSecondaryColor, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...() {
                    final Map<String, List<DiscussionReply>> childrenMap = {};
                    final List<DiscussionReply> rootReplies = [];
                    final Set<String> replyIds = _replies.map((r) => r.id).toSet();

                    for (final reply in _replies) {
                      if (reply.parentId != null && reply.parentId!.isNotEmpty && replyIds.contains(reply.parentId)) {
                        childrenMap.putIfAbsent(reply.parentId!, () => []).add(reply);
                      } else {
                        rootReplies.add(reply);
                      }
                    }

                    return rootReplies.map((rootReply) {
                      final children = childrenMap[rootReply.id] ?? const [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildReplyCard(
                            reply: rootReply,
                            isChild: false,
                            isArchived: isArchived,
                            isStaff: isStaff,
                            currentUser: currentUser,
                          ),
                          if (children.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 16, bottom: 8),
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      width: 2,
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      decoration: BoxDecoration(
                                        color: context.borderColor,
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        children: children
                                            .map((child) => _buildReplyCard(
                                                  reply: child,
                                                  isChild: true,
                                                  isArchived: isArchived,
                                                  isStaff: isStaff,
                                                  currentUser: currentUser,
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    }).toList();
                  }(),
                ],
              ),
            ),
          ),

          // Reply Target Banner (Twitter/X Context)
          if (!isArchived && _replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(15),
                border: Border(top: BorderSide(color: AppTheme.primary.withAlpha(40))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply_rounded, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.discussionReplyingTo(
                        _replyingTo!.authorDisplayName,
                        _replyingTo!.body.length > 30 ? '${_replyingTo!.body.substring(0, 30)}...' : _replyingTo!.body,
                      ),
                      style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _replyingTo = null),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(Icons.close_rounded, size: 16, color: context.textSecondaryColor),
                    ),
                  ),
                ],
              ),
            ),

          // Bottom Reply Composer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              border: Border(top: BorderSide(color: context.borderColor.withAlpha(120))),
            ),
            child: SafeArea(
              child: isArchived
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 16, color: AppTheme.warning),
                          const SizedBox(width: 8),
                          Text(
                            l10n.discussionArchivedBanner,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.warning),
                          ),
                        ],
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _replyController,
                            focusNode: _replyFocusNode,
                            decoration: InputDecoration(
                              hintText: _replyingTo != null
                                  ? l10n.discussionReplyToHint(_replyingTo!.authorDisplayName)
                                  : l10n.discussionReplyGeneralHint,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onFieldSubmitted: (_) => _sendReply(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _isSending ? null : _sendReply,
                          icon: _isSending
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send_rounded, size: 18),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

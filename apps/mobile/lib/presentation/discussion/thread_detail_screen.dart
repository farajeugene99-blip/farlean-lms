import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth/role_guard.dart';
import '../../core/theme/app_theme.dart';
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
          setState(() {
            _errorMessage = 'Diskusi tidak ditemukan atau telah dihapus.';
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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat detail diskusi: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _isSending || _thread == null) return;

    if (_thread!.status == DiscussionStatus.archived) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diskusi ini telah diarsipkan. Pengiriman balasan dinonaktifkan.'),
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
          )
          .timeout(const Duration(seconds: 15));

      _replyController.clear();
      // Reload replies dan thread metadata (agar reply_count naik)
      await _loadThreadAndReplies();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim balasan: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _confirmArchiveThread() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Arsipkan Diskusi?'),
        content: const Text(
          'Diskusi yang diarsipkan akan dikunci dari pengiriman balasan baru dan disembunyikan dari daftar anggota kelas.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Arsipkan'),
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
            const SnackBar(content: Text('Diskusi berhasil diarsipkan.'), backgroundColor: AppTheme.success),
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

  Future<void> _showEditThreadDialog() async {
    if (_thread == null) return;
    final titleCtrl = TextEditingController(text: _thread!.title);
    final bodyCtrl = TextEditingController(text: _thread!.body);
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Diskusi'),
        content: SizedBox(
          width: 460,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Judul Diskusi'),
                  validator: (v) => v == null || v.trim().length < 3 ? 'Judul minimal 3 karakter' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: bodyCtrl,
                  decoration: const InputDecoration(labelText: 'Isi Diskusi'),
                  maxLines: 4,
                  validator: (v) => v == null || v.trim().length < 3 ? 'Isi diskusi minimal 3 karakter' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
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
                    SnackBar(content: Text('Gagal update: $e'), backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            child: const Text('Simpan'),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Memuat thread diskusi...'),
      );
    }

    if (_errorMessage != null || _thread == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Diskusi')),
        body: ErrorView(
          message: _errorMessage ?? 'Diskusi tidak ditemukan.',
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
        title: const Text('Detail Diskusi'),
        actions: [
          if (!isArchived && isAuthor)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Diskusi',
              onPressed: _showEditThreadDialog,
            ),
          if (!isArchived && (isAuthor || isStaff))
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              tooltip: 'Arsipkan Diskusi',
              onPressed: _confirmArchiveThread,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan',
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
                      side: const BorderSide(color: AppTheme.border),
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
                                      isArchived ? 'Status: Diarsipkan' : 'Thread Diskusi Aktif',
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
                            style: const TextStyle(fontSize: 14, height: 1.5, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Balasan (${_replies.length})',
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
                            Icon(Icons.mark_chat_read_outlined, size: 40, color: AppTheme.textSecondary.withAlpha(100)),
                            const SizedBox(height: 8),
                            const Text(
                              'Belum ada tanggapan pada diskusi ini.',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._replies.map((reply) {
                      final isReplyAuthor = currentUser?.uid == reply.authorId;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 0.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppTheme.border.withAlpha(100)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppTheme.secondary.withAlpha(20),
                                    child: const Icon(Icons.person_outline_rounded, size: 14, color: AppTheme.secondary),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    reply.authorDisplayName,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  const Spacer(),
                                  if (!isArchived && (isReplyAuthor || isStaff))
                                    IconButton(
                                      icon: const Icon(Icons.archive_outlined, size: 16, color: AppTheme.textSecondary),
                                      tooltip: 'Arsipkan Balasan',
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
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.error),
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
                                style: const TextStyle(fontSize: 13, height: 1.4, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),

          // Bottom Reply Composer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.border.withAlpha(120))),
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
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline_rounded, size: 16, color: AppTheme.warning),
                          SizedBox(width: 8),
                          Text(
                            'Diskusi diarsipkan. Pengiriman balasan dinonaktifkan.',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.warning),
                          ),
                        ],
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _replyController,
                            decoration: const InputDecoration(
                              hintText: 'Tulis tanggapan atau balasan...',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

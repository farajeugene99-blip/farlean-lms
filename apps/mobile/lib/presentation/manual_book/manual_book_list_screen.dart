import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/auth/role_guard.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/manual_book.dart';
import '../../repositories/manual_book_repository.dart';
import '../../services/auth_provider.dart';
import '../../services/cloudinary_upload_service.dart';
import '../common/error_view.dart';
import '../common/loading_indicator.dart';
import 'create_manual_book_dialog.dart';

class ManualBookListScreen extends StatefulWidget {
  final String? classId;
  final ManualBookRepository? manualBookRepository;

  const ManualBookListScreen({
    super.key,
    this.classId,
    this.manualBookRepository,
  });

  @override
  State<ManualBookListScreen> createState() => _ManualBookListScreenState();
}

class _ManualBookListScreenState extends State<ManualBookListScreen> {
  late final ManualBookRepository _manualBookRepository;
  List<ManualBook> _books = [];
  bool _isLoading = true;
  String? _errorMessage;

  String get _effectiveClassId {
    final raw = widget.classId?.trim() ?? '';
    if (raw.isEmpty || raw == 'default_class') return 'SYSTEM';
    return raw;
  }

  bool get _isSystem => _effectiveClassId == 'SYSTEM';

  @override
  void initState() {
    super.initState();
    _manualBookRepository = widget.manualBookRepository ?? ManualBookRepository();
    _loadBooks();
  }

  Future<void> _loadBooks({bool isSoftRefresh = false}) async {
    if (!isSoftRefresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final authProvider = context.read<AuthProvider>();
    final isStaff = RoleGuard.isStaff(authProvider.appUser);
    final isAdmin = RoleGuard.canAccessAdmin(authProvider.appUser);
    final canManage = _isSystem ? isAdmin : isStaff;

    try {
      final list = await _manualBookRepository.getManualBooksByClass(
        _effectiveClassId,
        isAdmin: canManage,
      );
      if (mounted) {
        setState(() {
          _books = list;
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
              ? l10n.manualBookErrorPermissionStaff
              : l10n.manualBookErrorPermissionStudent;
        } else if (errorString.contains('network') || errorString.contains('unavailable')) {
          friendlyMessage = l10n.meetingErrorNetwork;
        } else {
          friendlyMessage = l10n.manualBookErrorLoadFailed(e.toString());
        }

        setState(() {
          _errorMessage = friendlyMessage;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openPdf(String fileUrl) async {
    final l10n = AppLocalizations.of(context);
    try {
      final cleanUrl = CloudinaryUploadService.getCleanUrl(fileUrl);
      final uri = Uri.parse(cleanUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.manualBookOpenPdfFailed),
              backgroundColor: AppTheme.error,
            ),
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

  Future<void> _showAddBookDialog() async {
    final authProvider = context.read<AuthProvider>();
    final isStaff = RoleGuard.isStaff(authProvider.appUser);
    final isAdmin = RoleGuard.canAccessAdmin(authProvider.appUser);
    final canManage = _isSystem ? isAdmin : isStaff;

    if (!canManage) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSystem ? l10n.manualBookOnlyAdminCanManage : l10n.manualBookErrorPermissionStaff),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final formData = await showDialog<ManualBookFormData>(
      context: context,
      builder: (ctx) => const CreateManualBookDialog(),
    );

    if (formData != null && mounted) {
      try {
        final book = ManualBook(
          id: '',
          classId: _effectiveClassId,
          title: formData.title,
          description: formData.description,
          fileUrl: formData.fileUrl,
          fileName: formData.fileName,
          fileSize: 1024 * 1024,
          status: formData.isPublished ? 'Published' : 'Draft',
          createdBy: authProvider.firebaseUser?.uid,
          createdAt: DateTime.now(),
          publishedAt: formData.isPublished ? DateTime.now() : null,
        );

        await _manualBookRepository.createManualBook(book);
        if (mounted) {
          _loadBooks(isSoftRefresh: true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Buku panduan berhasil disimpan.'), backgroundColor: AppTheme.success),
          );
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

  Future<void> _togglePublishStatus(ManualBook book) async {
    final newStatus = book.isPublished ? 'Draft' : 'Published';
    try {
      await _manualBookRepository.updateStatus(book.id, newStatus);
      if (mounted) {
        _loadBooks(isSoftRefresh: true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'Published' ? 'Buku panduan dipublikasikan.' : 'Buku panduan diubah ke Draft.'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _deleteBook(ManualBook book) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Buku Panduan?'),
        content: Text("Buku panduan '${book.title}' akan dihapus secara permanen."),
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
        await _manualBookRepository.deleteManualBook(book.id);
        if (mounted) {
          _loadBooks(isSoftRefresh: true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Buku panduan berhasil dihapus.'), backgroundColor: AppTheme.success),
          );
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = context.watch<AuthProvider>();
    final isStaff = RoleGuard.isStaff(authProvider.appUser);
    final isAdmin = RoleGuard.canAccessAdmin(authProvider.appUser);
    final canManage = _isSystem ? isAdmin : isStaff;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSystem ? l10n.manualBookSystemTitle : l10n.manualBookAppBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.meetingRefreshTooltip,
            onPressed: () => _loadBooks(isSoftRefresh: true),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _showAddBookDialog,
              icon: const Icon(Icons.upload_file_rounded),
              label: Text(l10n.manualBookAddTitle),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: _buildBody(canManage),
    );
  }

  Widget _buildBody(bool canManage) {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return LoadingIndicator(message: l10n.manualBookLoading);
    }

    if (_errorMessage != null) {
      return ErrorView(message: _errorMessage!, onRetry: () => _loadBooks());
    }

    if (_books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 56,
                color: context.textSecondaryColor.withAlpha(128),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.manualBookEmptyTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _isSystem ? l10n.manualBookSystemEmpty : l10n.manualBookEmptyBody,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textSecondaryColor),
              ),
              if (canManage) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _showAddBookDialog,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: Text(l10n.manualBookAddTitle),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadBooks(isSoftRefresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _books.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final book = _books[index];
          return _buildBookCard(book, canManage);
        },
      ),
    );
  }

  Widget _buildBookCard(ManualBook book, bool canManage) {
    final l10n = AppLocalizations.of(context);
    final sizeKb = (book.fileSize / 1024).round();
    final sizeStr = sizeKb > 1024
        ? '${(sizeKb / 1024).toStringAsFixed(1)} MB'
        : '$sizeKb KB';

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: context.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              book.title,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                          ),
                          if (canManage) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (book.isPublished ? AppTheme.success : AppTheme.warning).withAlpha(20),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                book.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: book.isPublished ? AppTheme.success : AppTheme.warning,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.description.isNotEmpty ? book.description : l10n.manualBookNoDescription,
                        style: TextStyle(fontSize: 13, color: context.textSecondaryColor),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            book.fileName,
                            style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•  $sizeStr',
                            style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (canManage)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: context.textSecondaryColor, size: 20),
                    onSelected: (val) {
                      if (val == 'toggle') _togglePublishStatus(book);
                      if (val == 'delete') _deleteBook(book);
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(book.isPublished ? 'Ubah ke Draft' : 'Publikasikan'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(l10n.meetingDeleteAction, style: const TextStyle(color: AppTheme.error)),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _openPdf(book.fileUrl),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: Text(l10n.manualBookOpenPdfBtn),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(140, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

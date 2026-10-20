import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/auth/role_guard.dart';
import '../../core/config/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/manual_book.dart';
import '../../repositories/manual_book_repository.dart';
import '../../services/auth_provider.dart';
import '../common/error_view.dart';
import '../common/loading_indicator.dart';

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

  @override
  void initState() {
    super.initState();
    _manualBookRepository = widget.manualBookRepository ?? ManualBookRepository();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final effectiveClassId = widget.classId?.trim() ?? '';
    if (effectiveClassId.isEmpty || effectiveClassId == 'default_class') {
      if (mounted) {
        setState(() {
          _books = [];
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
      final list = await _manualBookRepository.getManualBooksByClass(effectiveClassId);
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
      final uri = Uri.parse(fileUrl);
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
    final l10n = AppLocalizations.of(context);
    final effectiveClassId = widget.classId?.trim() ?? '';
    if (effectiveClassId.isEmpty || effectiveClassId == 'default_class') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.manualBookSelectClassFirst),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final titleController = TextEditingController();
    final descController = TextEditingController();
    final urlController = TextEditingController();
    final fileNameController = TextEditingController(text: 'panduan.pdf');
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.manualBookAddTitle),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: l10n.manualBookTitleLabel),
                    validator: (v) => v == null || v.trim().isEmpty ? l10n.manualBookTitleRequired : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: descController,
                    decoration: InputDecoration(labelText: l10n.manualBookDescLabel),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: urlController,
                    decoration: InputDecoration(
                      labelText: l10n.manualBookUrlLabel,
                      prefixIcon: const Icon(Icons.link_rounded, size: 20),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return l10n.manualBookUrlRequired;
                      if (!v.trim().startsWith('https://')) {
                        return l10n.manualBookUrlInvalid;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: fileNameController,
                    decoration: InputDecoration(labelText: l10n.manualBookFileNameLabel),
                  ),
                ],
              ),
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
                final book = ManualBook(
                  id: '',
                  classId: effectiveClassId,
                  title: titleController.text.trim(),
                  description: descController.text.trim(),
                  fileUrl: urlController.text.trim(),
                  fileName: fileNameController.text.trim(),
                  fileSize: 1024 * 1024, // Estimasi 1 MB
                  createdAt: DateTime.now(),
                );
                await _manualBookRepository.createManualBook(book);
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
      descController.dispose();
      urlController.dispose();
      fileNameController.dispose();
    });

    if (created == true) {
      _loadBooks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = context.watch<AuthProvider>();
    final isStaff = RoleGuard.isStaff(authProvider.appUser);
    final isAdmin = RoleGuard.canAccessAdmin(authProvider.appUser);
    final effectiveClassId = widget.classId?.trim() ?? '';
    final isSystem = effectiveClassId == 'SYSTEM';
    final canManage = isSystem ? isAdmin : isStaff;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSystem ? l10n.manualBookSystemTitle : l10n.manualBookAppBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.meetingRefreshTooltip,
            onPressed: _loadBooks,
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context);
    final effectiveClassId = widget.classId?.trim() ?? '';
    if (effectiveClassId.isEmpty || effectiveClassId == 'default_class') {
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
                l10n.meetingNoClassTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.manualBookNoClassBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => context.push(AppConstants.joinClassRoute),
                icon: const Icon(Icons.qr_code_rounded),
                label: Text(l10n.manualBookJoinNewClassBtn),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return LoadingIndicator(message: l10n.manualBookLoading);
    }

    if (_errorMessage != null) {
      return ErrorView(message: _errorMessage!, onRetry: _loadBooks);
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
                effectiveClassId == 'SYSTEM' ? l10n.manualBookSystemEmpty : l10n.manualBookEmptyBody,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textSecondaryColor),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBooks,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _books.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final book = _books[index];
          return _buildBookCard(book);
        },
      ),
    );
  }

  Widget _buildBookCard(ManualBook book) {
    final l10n = AppLocalizations.of(context);
    final sizeKb = (book.fileSize / 1024).round();
    final sizeStr = sizeKb > 1024
        ? '${(sizeKb / 1024).toStringAsFixed(1)} MB'
        : '$sizeKb KB';

    return Card(
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
                      Text(
                        book.title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
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

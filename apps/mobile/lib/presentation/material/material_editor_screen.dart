import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/content_status.dart';
import '../../models/delta_sanitizer.dart';
import '../../models/material_content.dart';
import '../../repositories/material_repository.dart';
import '../../services/auth_provider.dart';
import '../../services/cloudinary_upload_service.dart';
import '../common/error_view.dart';
import '../common/loading_indicator.dart';
import '../meeting/meeting_status_localization.dart';

class MaterialEditorScreen extends StatefulWidget {
  final String? materiId;
  final MaterialContent? initialMaterial;
  final String classId;
  final String meetingId;
  final MaterialRepository? materialRepository;
  final CloudinaryUploadService? cloudinaryUploadService;

  const MaterialEditorScreen({
    super.key,
    this.materiId,
    this.initialMaterial,
    this.classId = '',
    this.meetingId = '',
    this.materialRepository,
    this.cloudinaryUploadService,
  });

  @override
  State<MaterialEditorScreen> createState() => _MaterialEditorScreenState();
}

class _MaterialEditorScreenState extends State<MaterialEditorScreen> {
  late final MaterialRepository _materialRepository;
  late final CloudinaryUploadService _uploadService;
  late final TextEditingController _titleController;
  late QuillController _quillController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isSaving = false;
  bool _isLoadingInitial = false;
  bool _isUploadingFile = false;
  String? _initError;
  MaterialContent? _existingMaterial;
  late List<String> _attachments;
  bool _isDirty = false;

  static const String _templateDeltaJson = '[{"insert":"Pendahuluan\\n"},{"insert":"Tujuan Pembelajaran\\n"},{"insert":"Pembahasan\\n"},{"insert":"Contoh\\n"},{"insert":"Rangkuman\\n"}]';

  int get _charCount {
    try {
      return _quillController.document.toPlainText().trim().length;
    } catch (_) {
      return 0;
    }
  }

  void _markDirty() {
    if (!_isDirty && mounted) {
      setState(() => _isDirty = true);
    }
  }

  void _attachDirtyListeners() {
    _titleController.removeListener(_markDirty);
    _titleController.addListener(_markDirty);
    _quillController.removeListener(_markDirty);
    _quillController.addListener(_markDirty);
  }

  @override
  void initState() {
    super.initState();
    _materialRepository = widget.materialRepository ?? MaterialRepository();
    _uploadService = widget.cloudinaryUploadService ?? CloudinaryUploadService();
    _existingMaterial = widget.initialMaterial;
    _attachments = List<String>.from(widget.initialMaterial?.attachments ?? []);
    _titleController = TextEditingController(text: widget.initialMaterial?.title ?? '');

    Document doc;
    if (widget.initialMaterial != null && widget.initialMaterial!.content is List) {
      try {
        doc = Document.fromJson(widget.initialMaterial!.content as List);
      } catch (_) {
        doc = Document()..insert(0, '\n');
      }
    } else {
      doc = Document()..insert(0, '\n');
    }

    _quillController = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _attachDirtyListeners();

    // Deep-link / Reload recovery guard: Ambil data lama agar tidak tertimpa kosong
    final isExisting = widget.materiId != null &&
        widget.materiId!.isNotEmpty &&
        widget.materiId != 'new';

    if (isExisting && widget.initialMaterial == null) {
      _fetchExistingMaterial(widget.materiId!);
    }
  }

  Future<void> _fetchExistingMaterial(String id) async {
    setState(() {
      _isLoadingInitial = true;
      _initError = null;
    });

    try {
      final fetched = await _materialRepository.getMaterial(id);
      if (!mounted) return;

      if (fetched == null) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _isLoadingInitial = false;
          _initError = l10n.materialNotFoundOrDeleted;
        });
        return;
      }

      Document doc;
      try {
        if (fetched.content is List) {
          doc = Document.fromJson(fetched.content as List);
        } else {
          doc = Document()..insert(0, '\n');
        }
      } catch (_) {
        doc = Document()..insert(0, '\n');
      }

      _titleController.text = fetched.title;
      _quillController.dispose();
      _quillController = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
      _attachDirtyListeners();

      setState(() {
        _existingMaterial = fetched;
        _attachments = List<String>.from(fetched.attachments);
        _isLoadingInitial = false;
        _isDirty = false;
      });
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _isLoadingInitial = false;
          _initError = l10n.materialLoadFailed(e.toString());
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showInsertImageDialog() async {
    final l10n = AppLocalizations.of(context);
    final urlController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isUploadingImage = false;
    String? uploadError;

    final inserted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.materialInsertImageTitle),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.materialInsertImageSecurityNote,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: isUploadingImage
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.photo_library_outlined, size: 18),
                    label: Text(l10n.materialPickImageDevice),
                    onPressed: isUploadingImage
                        ? null
                        : () async {
                            try {
                              final file = await _uploadService.pickImageFile();
                              if (file == null) return;
                              setDialogState(() {
                                isUploadingImage = true;
                                uploadError = null;
                              });
                              final effectiveClassId = widget.classId.isNotEmpty
                                  ? widget.classId
                                  : (_existingMaterial?.classId.isNotEmpty == true ? _existingMaterial!.classId : null);
                              final result = await _uploadService.uploadFile(
                                file: file,
                                folderType: 'images',
                                classId: effectiveClassId,
                              );
                              urlController.text = result.secureUrl;
                              setDialogState(() => isUploadingImage = false);
                            } catch (e) {
                              setDialogState(() {
                                isUploadingImage = false;
                                uploadError = e.toString().replaceFirst('Exception: ', '');
                              });
                            }
                          },
                  ),
                  if (uploadError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      uploadError!,
                      style: const TextStyle(fontSize: 11, color: AppTheme.error),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: urlController,
                    autofocus: false,
                    decoration: InputDecoration(
                      labelText: l10n.materialImageUrlLabel,
                      prefixIcon: const Icon(Icons.image_outlined, size: 20),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return l10n.materialImageUrlRequired;
                      final trimmed = v.trim().toLowerCase();
                      if (trimmed.startsWith('data:image')) {
                        return l10n.materialImageBase64Forbidden;
                      }
                      if (!trimmed.startsWith('https://')) {
                        return l10n.materialImageUrlInvalid;
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
              onPressed: isUploadingImage ? null : () => Navigator.pop(ctx, false),
              child: Text(l10n.btnCancel),
            ),
            ElevatedButton(
              onPressed: isUploadingImage
                  ? null
                  : () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(ctx, true);
                      }
                    },
              child: Text(l10n.materialInsertBtn),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      urlController.dispose();
    });

    if (inserted == true) {
      final index = _quillController.selection.baseOffset;
      final safeIndex = index < 0 ? 0 : index;
      _quillController.document.insert(
        safeIndex,
        BlockEmbed.image(urlController.text.trim()),
      );
      _markDirty();
    }
  }

  Future<void> _pickAndAttachDocumentFile() async {
    try {
      final file = await _uploadService.pickDocumentFile();
      if (file == null) return;

      setState(() => _isUploadingFile = true);
      final effectiveClassId = widget.classId.isNotEmpty
          ? widget.classId
          : (_existingMaterial?.classId.isNotEmpty == true ? _existingMaterial!.classId : null);

      final result = await _uploadService.uploadFile(
        file: file,
        folderType: 'materials',
        classId: effectiveClassId,
      );

      final encodedUrl = result.toEncodedUrl();
      setState(() {
        _attachments.add(encodedUrl);
        _isUploadingFile = false;
      });

      final index = _quillController.selection.baseOffset;
      final safeIndex = index < 0 ? 0 : index;
      final insertText = '📎 Lampiran: ${result.fileName}\n';
      _quillController.document.insert(safeIndex, insertText);
      _quillController.document.format(
        safeIndex,
        insertText.length - 1,
        LinkAttribute(result.secureUrl),
      );
      _markDirty();

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.materialAttachmentSuccess),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingFile = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  /// Menyisipkan template struktur materi (Pendahuluan → Tujuan → Pembahasan → Contoh → Rangkuman).
  /// Hanya mengisi editor kosong agar tidak menimpa konten guru yang sudah ada.
  void _insertTemplate() {
    final l10n = AppLocalizations.of(context);
    final plainText = _quillController.document.toPlainText().trim();
    if (plainText.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.materialTemplateOnlyEmpty),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }
    try {
      final ops = jsonDecode(_templateDeltaJson) as List;
      final doc = Document.fromJson(ops);
      _quillController.dispose();
      _quillController = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
      _attachDirtyListeners();
      _markDirty();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.materialTemplateSuccess),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.materialTemplateFailed(e.toString())), backgroundColor: AppTheme.error),
      );
    }
  }

  /// Pratinjau tampilan mahasiswa memakai renderer read-only yang sama dengan reader.
  void _showStudentPreview() {
    final l10n = AppLocalizations.of(context);
    final title = _titleController.text.trim();
    List previewOps;
    try {
      previewOps = _quillController.document.toDelta().toJson() as List;
    } catch (_) {
      previewOps = [
        {'insert': 'Konten belum dapat dipratinjau.\n'}
      ];
    }
    final previewDoc = Document.fromJson(previewOps);
    final previewController = QuillController(
      document: previewDoc,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
    final previewFocus = FocusNode();
    final previewScroll = ScrollController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title.isEmpty ? l10n.materialPreviewTitle : title),
        content: SizedBox(
          width: 440,
          height: 420,
          child: QuillEditor(
            controller: previewController,
            focusNode: previewFocus,
            scrollController: previewScroll,
            config: QuillEditorConfig(
              autoFocus: false,
              expands: true,
              padding: EdgeInsets.zero,
              placeholder: l10n.materialEmptyPlaceholder,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.btnClose),
          ),
        ],
      ),
    ).whenComplete(() {
      previewController.dispose();
      previewFocus.dispose();
      previewScroll.dispose();
    });
  }

  /// Konfirmasi keluar saat ada perubahan yang belum disimpan.
  Future<bool> _confirmDiscardIfDirty() async {
    if (!_isDirty || _isSaving) return true;
    final l10n = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.materialDiscardConfirmTitle),
        content: Text(
          l10n.materialDiscardConfirmBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.materialKeepEditingBtn),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text(l10n.materialDiscardChangesBtn),
          ),
        ],
      ),
    );
    return discard == true;
  }

  Future<void> _saveMaterial(ContentStatus status) async {
    final l10n = AppLocalizations.of(context);
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.materialTitleRequired), backgroundColor: AppTheme.error),
      );
      return;
    }

    final deltaJson = _quillController.document.toDelta().toJson();

    // Validasi Sanitasi Delta
    final sanitizationError = DeltaSanitizer.validate(deltaJson);
    if (sanitizationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sanitizationError), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _isSaving = true);
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.firebaseUser?.uid ?? 'unknown_user';

    try {
      String? savedId;
      if (_existingMaterial != null) {
        // Update materi yang sudah ada (Anti-Overwrite data lama)
        final updated = _existingMaterial!.copyWith(
          title: title,
          content: deltaJson,
          attachments: _attachments,
          status: status,
          updatedBy: uid,
        );
        await _materialRepository.updateMaterial(updated);
        savedId = updated.id;
      } else {
        // Buat materi baru (abaikan sentinel rute 'new' agar Firestore membuat auto-id unik aman)
        final effectiveNewId = (widget.materiId == null || widget.materiId == 'new') ? '' : widget.materiId!;
        final newMaterial = MaterialContent(
          id: effectiveNewId,
          meetingId: widget.meetingId,
          classId: widget.classId,
          title: title,
          content: deltaJson,
          attachments: _attachments,
          status: status,
          updatedBy: uid,
        );
        savedId = await _materialRepository.createMaterial(newMaterial);
      }

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isDirty = false;
      });

      final statusLabel = MeetingStatusLocalization.label(status, l10n);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.materialSavedAsStatus(statusLabel)),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context, savedId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.materialSaveFailed(e.toString())), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isLoadingInitial) {
      return Scaffold(
        body: LoadingIndicator(message: l10n.materialLoading),
      );
    }

    if (_initError != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.materialEditTitle,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        body: ErrorView(
          message: _initError!,
          onRetry: () {
            if (widget.materiId != null && widget.materiId!.isNotEmpty) {
              _fetchExistingMaterial(widget.materiId!);
            }
          },
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmDiscardIfDirty() && context.mounted) {
          Navigator.pop(context, result);
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(
          _existingMaterial == null ? l10n.materialCreateTitle : l10n.materialEditTitle,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility_outlined, size: 20),
            tooltip: l10n.materialPreviewTooltip,
            onPressed: _isSaving ? null : _showStudentPreview,
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined, size: 20),
            tooltip: l10n.meetingSaveDraftBtn,
            onPressed: _isSaving ? null : () => _saveMaterial(ContentStatus.draft),
          ),
          ElevatedButton(
            onPressed: _isSaving ? null : () => _saveMaterial(ContentStatus.published),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              minimumSize: const Size(80, 36),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(l10n.materialPublishBtn),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _titleController,
              enabled: !_isSaving,
              decoration: InputDecoration(
                labelText: l10n.materialTitleLabel,
                prefixIcon: const Icon(Icons.title_rounded, size: 20),
              ),
            ),
          ),

          // Quill Toolbar
          QuillSimpleToolbar(
            controller: _quillController,
            config: const QuillSimpleToolbarConfig(
              showFontFamily: false,
              showFontSize: false,
              showSubscript: false,
              showSuperscript: false,
              showSearchButton: false,
              showInlineCode: true,
              showCodeBlock: true,
              multiRowsDisplay: false,
            ),
          ),
          const Divider(height: 1),

          // Action Toolbar tambahan untuk Gambar Cloudinary + Template
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: context.surfaceColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : _showInsertImageDialog,
                    icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                    label: Text(l10n.materialImageBtn, style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(80, 32)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: (_isSaving || _isUploadingFile) ? null : _pickAndAttachDocumentFile,
                    icon: _isUploadingFile
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.attach_file_rounded, size: 16),
                    label: Text(l10n.materialAttachFileBtn, style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(80, 32)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : _insertTemplate,
                    icon: const Icon(Icons.dashboard_customize_outlined, size: 16),
                    label: Text(l10n.materialTemplateBtn, style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(80, 32)),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    l10n.materialCharCountDeltaJson(_charCount),
                    style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Chips Bar Lampiran Berkas Materi
          if (_attachments.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: context.surfaceColor,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int i = 0; i < _attachments.length; i++) ...[
                      Builder(builder: (ctx) {
                        final parsed = CloudinaryUploadResult.parseEncodedUrl(_attachments[i]);
                        final name = parsed['fileName'] as String? ?? 'Lampiran';
                        final size = parsed['sizeBytes'] as int?;
                        final sizeStr = size != null ? ' (${(size / (1024 * 1024)).toStringAsFixed(1)} MB)' : '';
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InputChip(
                            avatar: const Icon(Icons.attach_file_rounded, size: 16, color: AppTheme.primary),
                            label: Text('$name$sizeStr', style: const TextStyle(fontSize: 11)),
                            onDeleted: _isSaving ? null : () {
                              setState(() {
                                _attachments.removeAt(i);
                                _markDirty();
                              });
                            },
                            deleteIconColor: AppTheme.error,
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),

          // Peringatan materi kosong
          if (_charCount == 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.warning.withAlpha(20),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.materialEmptyWarning,
                      style: const TextStyle(fontSize: 12, color: AppTheme.warning),
                    ),
                  ),
                ],
              ),
            ),

          // Quill Editor
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: QuillEditor(
                controller: _quillController,
                focusNode: _focusNode,
                scrollController: _scrollController,
                config: QuillEditorConfig(
                  autoFocus: true,
                  expands: true,
                  padding: EdgeInsets.zero,
                  placeholder: l10n.materialEditorPlaceholder,
                  customStyles: DefaultStyles(
                    paragraph: DefaultTextBlockStyle(
                      TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 15,
                        height: 1.5,
                      ),
                      const HorizontalSpacing(0, 0),
                      const VerticalSpacing(0, 0),
                      const VerticalSpacing(0, 0),
                      null,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Info terakhir disimpan
          if (_existingMaterial?.updatedAt != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: context.surfaceColor,
              child: Text(
                '${l10n.labelLastSaved}: ${DateFormatter.formatLastSaved(_existingMaterial!.updatedAt, _existingMaterial!.version)}',
                style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
      ),
    );
  }
}

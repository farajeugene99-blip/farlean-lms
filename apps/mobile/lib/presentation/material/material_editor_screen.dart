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
import '../common/error_view.dart';
import '../common/loading_indicator.dart';
import '../meeting/meeting_status_localization.dart';

class MaterialEditorScreen extends StatefulWidget {
  final String? materiId;
  final MaterialContent? initialMaterial;
  final String classId;
  final String meetingId;
  final MaterialRepository? materialRepository;

  const MaterialEditorScreen({
    super.key,
    this.materiId,
    this.initialMaterial,
    this.classId = '',
    this.meetingId = '',
    this.materialRepository,
  });

  @override
  State<MaterialEditorScreen> createState() => _MaterialEditorScreenState();
}

class _MaterialEditorScreenState extends State<MaterialEditorScreen> {
  late final MaterialRepository _materialRepository;
  late final TextEditingController _titleController;
  late QuillController _quillController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isSaving = false;
  bool _isLoadingInitial = false;
  String? _initError;
  MaterialContent? _existingMaterial;
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
    _existingMaterial = widget.initialMaterial;
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

    final inserted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
                TextFormField(
                  controller: urlController,
                  autofocus: true,
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
                    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
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
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.btnCancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: Text(l10n.materialInsertBtn),
          ),
        ],
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
        appBar: AppBar(title: Text(l10n.materialEditTitle)),
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
        title: Text(_existingMaterial == null ? l10n.materialCreateTitle : l10n.materialEditTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility_outlined, size: 20),
            tooltip: l10n.materialPreviewTooltip,
            onPressed: _isSaving ? null : _showStudentPreview,
          ),
          TextButton(
            onPressed: _isSaving ? null : () => _saveMaterial(ContentStatus.draft),
            child: Text(l10n.meetingSaveDraftBtn),
          ),
          ElevatedButton(
            onPressed: _isSaving ? null : () => _saveMaterial(ContentStatus.published),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              minimumSize: const Size(90, 36),
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
            color: AppTheme.surface,
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _showInsertImageDialog,
                  icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                  label: Text(l10n.materialImageBtn, style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(90, 32)),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _insertTemplate,
                  icon: const Icon(Icons.dashboard_customize_outlined, size: 16),
                  label: Text(l10n.materialTemplateBtn, style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(90, 32)),
                ),
                const Spacer(),
                Text(
                  l10n.materialCharCountDeltaJson(_charCount),
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

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
                ),
              ),
            ),
          ),

          // Info terakhir disimpan
          if (_existingMaterial?.updatedAt != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: AppTheme.surface,
              child: Text(
                '${l10n.labelLastSaved}: ${DateFormatter.formatLastSaved(_existingMaterial!.updatedAt, _existingMaterial!.version)}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
      ),
    );
  }
}

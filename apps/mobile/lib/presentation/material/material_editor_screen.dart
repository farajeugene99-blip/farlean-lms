import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/content_status.dart';
import '../../models/delta_sanitizer.dart';
import '../../models/material_content.dart';
import '../../repositories/material_repository.dart';
import '../../services/auth_provider.dart';
import '../common/error_view.dart';
import '../common/loading_indicator.dart';

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
        setState(() {
          _isLoadingInitial = false;
          _initError = 'Materi tidak ditemukan atau telah dihapus.';
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
        setState(() {
          _isLoadingInitial = false;
          _initError = 'Gagal memuat materi: $e';
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
    final urlController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final inserted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sisipkan Gambar (URL Cloudinary)'),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sesuai aturan keamanan Farlean LMS, gambar harus bersumber dari URL eksternal (Cloudinary). Gambar base64 dilarang.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: urlController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'URL Gambar (https://...)',
                    prefixIcon: Icon(Icons.image_outlined, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'URL gambar wajib diisi';
                    final trimmed = v.trim().toLowerCase();
                    if (trimmed.startsWith('data:image')) {
                      return 'Gambar base64 inline dilarang.';
                    }
                    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
                      return 'URL harus diawali dengan http:// atau https://';
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
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Sisipkan'),
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
    final plainText = _quillController.document.toPlainText().trim();
    if (plainText.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Template hanya dapat disisipkan pada editor kosong agar konten tidak tertimpa.'),
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
        const SnackBar(
          content: Text('Template materi berhasil disisipkan. Silakan lengkapi setiap bagian.'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyisipkan template: $e'), backgroundColor: AppTheme.error),
      );
    }
  }

  /// Pratinjau tampilan mahasiswa memakai renderer read-only yang sama dengan reader.
  void _showStudentPreview() {
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
        title: Text(title.isEmpty ? 'Pratinjau Materi' : title),
        content: SizedBox(
          width: 440,
          height: 420,
          child: QuillEditor(
            controller: previewController,
            focusNode: previewFocus,
            scrollController: previewScroll,
            config: const QuillEditorConfig(
              autoFocus: false,
              expands: true,
              padding: EdgeInsets.zero,
              placeholder: 'Materi kosong.',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
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
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buang Perubahan?'),
        content: const Text(
          'Ada perubahan materi yang belum disimpan. Keluar sekarang akan membuang perubahan tersebut.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Lanjutkan Mengedit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Buang Perubahan'),
          ),
        ],
      ),
    );
    return discard == true;
  }

  Future<void> _saveMaterial(ContentStatus status) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul materi wajib diisi.'), backgroundColor: AppTheme.error),
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Materi berhasil disimpan sebagai ${status.value}.'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context, savedId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan materi: $e'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingInitial) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Memuat materi pembelajaran...'),
      );
    }

    if (_initError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Materi')),
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
        title: Text(_existingMaterial == null ? 'Buat Materi Baru' : 'Edit Materi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility_outlined, size: 20),
            tooltip: 'Pratinjau Tampilan Mahasiswa',
            onPressed: _isSaving ? null : _showStudentPreview,
          ),
          TextButton(
            onPressed: _isSaving ? null : () => _saveMaterial(ContentStatus.draft),
            child: const Text('Simpan Draft'),
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
                : const Text('Publikasikan'),
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
              decoration: const InputDecoration(
                labelText: 'Judul Materi Pembelajaran',
                prefixIcon: Icon(Icons.title_rounded, size: 20),
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
                  label: const Text('Gambar', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(90, 32)),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _insertTemplate,
                  icon: const Icon(Icons.dashboard_customize_outlined, size: 16),
                  label: const Text('Template', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(90, 32)),
                ),
                const Spacer(),
                Text(
                  '$_charCount karakter • Format: Delta JSON',
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
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.warning),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Materi masih kosong. Tulis konten atau sisipkan template sebelum menyimpan.',
                      style: TextStyle(fontSize: 12, color: AppTheme.warning),
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
                config: const QuillEditorConfig(
                  autoFocus: true,
                  expands: true,
                  padding: EdgeInsets.zero,
                  placeholder: 'Tuliskan materi pembelajaran terstruktur di sini...',
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
                'Terakhir disimpan: ${_existingMaterial!.updatedAt!.day.toString().padLeft(2, '0')}/${_existingMaterial!.updatedAt!.month.toString().padLeft(2, '0')}/${_existingMaterial!.updatedAt!.year} ${_existingMaterial!.updatedAt!.hour.toString().padLeft(2, '0')}:${_existingMaterial!.updatedAt!.minute.toString().padLeft(2, '0')} • Versi ${_existingMaterial!.version}',
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

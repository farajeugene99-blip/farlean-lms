import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/content_status.dart';
import '../../models/delta_sanitizer.dart';
import '../../models/material_content.dart';
import '../../repositories/material_repository.dart';
import '../../services/auth_provider.dart';

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
  late final QuillController _quillController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _materialRepository = widget.materialRepository ?? MaterialRepository();
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
        content: Form(
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
    );

    if (inserted == true) {
      final index = _quillController.selection.baseOffset;
      final safeIndex = index < 0 ? 0 : index;
      _quillController.document.insert(
        safeIndex,
        BlockEmbed.image(urlController.text.trim()),
      );
    }
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
      if (widget.initialMaterial != null) {
        // Update materi
        final updated = widget.initialMaterial!.copyWith(
          title: title,
          content: deltaJson,
          status: status,
          updatedBy: uid,
        );
        await _materialRepository.updateMaterial(updated);
        savedId = updated.id;
      } else {
        // Buat materi baru
        final newMaterial = MaterialContent(
          id: widget.materiId ?? '',
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
      setState(() => _isSaving = false);

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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialMaterial == null ? 'Buat Materi Baru' : 'Edit Materi'),
        actions: [
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

          // Action Toolbar tambahan untuk Gambar Cloudinary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: AppTheme.surface,
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _showInsertImageDialog,
                  icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                  label: const Text('Sisipkan Gambar Cloudinary', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(120, 32)),
                ),
                const Spacer(),
                const Text(
                  'Format: Delta JSON',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

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
        ],
      ),
    );
  }
}

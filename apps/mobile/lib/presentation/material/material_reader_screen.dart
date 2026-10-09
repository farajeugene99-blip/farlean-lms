import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/auth/role_guard.dart';
import '../../core/theme/app_theme.dart';
import '../../models/material_content.dart';
import '../../repositories/material_repository.dart';
import '../../services/auth_provider.dart';
import '../common/error_view.dart';
import '../common/loading_indicator.dart';

class MaterialReaderScreen extends StatefulWidget {
  final String materiId;
  final String classId;
  final String meetingId;
  final MaterialRepository? materialRepository;

  const MaterialReaderScreen({
    super.key,
    required this.materiId,
    this.classId = '',
    this.meetingId = '',
    this.materialRepository,
  });

  @override
  State<MaterialReaderScreen> createState() => _MaterialReaderScreenState();
}

class _MaterialReaderScreenState extends State<MaterialReaderScreen> {
  late final MaterialRepository _materialRepository;
  MaterialContent? _material;
  QuillController? _quillController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  String? _errorMessage;
  bool _isRecordingView = false;
  bool _recordSuccess = false;
  String? _recordError;

  @override
  void initState() {
    super.initState();
    _materialRepository = widget.materialRepository ?? MaterialRepository();
    _loadMaterial();
  }

  @override
  void dispose() {
    _quillController?.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _recordViewOnly() async {
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.firebaseUser?.uid;
    if (uid == null || widget.classId.isEmpty || widget.meetingId.isEmpty) return;

    if (mounted) {
      setState(() {
        _isRecordingView = true;
        _recordError = null;
      });
    }

    try {
      await _materialRepository.recordMateriOpened(
        classId: widget.classId,
        meetingId: widget.meetingId,
        materiId: widget.materiId,
        uid: uid,
      );
      if (mounted) {
        setState(() {
          _isRecordingView = false;
          _recordSuccess = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRecordingView = false;
          _recordSuccess = false;
          _recordError = e.toString();
        });
      }
    }
  }

  Future<void> _loadMaterial() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final material = await _materialRepository.getMaterial(widget.materiId);
      if (!mounted) return;

      if (material == null) {
        setState(() {
          _errorMessage = 'Materi tidak ditemukan.';
          _isLoading = false;
        });
        return;
      }

      // Inisialisasi QuillController dengan konten Delta JSON
      Document doc;
      try {
        if (material.content is List) {
          doc = Document.fromJson(material.content as List);
        } else {
          doc = Document()..insert(0, 'Konten belum tersedia.\n');
        }
      } catch (e) {
        doc = Document()..insert(0, 'Gagal memuat format konten Delta: $e\n');
      }

      _quillController?.dispose();
      _quillController = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );

      setState(() {
        _material = material;
        _isLoading = false;
      });

      // Catat materi_opened_at untuk validasi pretest secara asynchronous terpantau
      await _recordViewOnly();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat materi: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Memuat materi pembelajaran...'),
      );
    }

    if (_errorMessage != null || _material == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Materi')),
        body: ErrorView(
          message: _errorMessage ?? 'Materi tidak ditemukan.',
          onRetry: _loadMaterial,
        ),
      );
    }

    final material = _material!;
    final authProvider = context.watch<AuthProvider>();
    final isStaff = RoleGuard.isStaff(authProvider.appUser);

    return Scaffold(
      appBar: AppBar(
        title: Text(material.title),
        actions: [
          if (isStaff)
            IconButton(
              icon: const Icon(Icons.edit_note_rounded),
              tooltip: 'Edit Materi',
              onPressed: () async {
                final queryParams = <String, String>{};
                if (widget.classId.isNotEmpty) queryParams['classId'] = widget.classId;
                if (widget.meetingId.isNotEmpty) queryParams['meetingId'] = widget.meetingId;
                final uri = Uri(
                  path: '/materials/${material.id}/edit',
                  queryParameters: queryParams.isEmpty ? null : queryParams,
                );
                await context.push(uri.toString(), extra: material);
                _loadMaterial();
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Header Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppTheme.surface,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Versi ${material.version}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Format: ${material.format.toUpperCase()}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                const Spacer(),
                if (_isRecordingView) ...[
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Mencatat Progres...',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ] else if (_recordSuccess) ...[
                  const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppTheme.success),
                  const SizedBox(width: 4),
                  const Text(
                    'Tercatat Dibuka',
                    style: TextStyle(fontSize: 11, color: AppTheme.success, fontWeight: FontWeight.w500),
                  ),
                ] else if (_recordError != null) ...[
                  InkWell(
                    onTap: _recordViewOnly,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.warning_amber_rounded, size: 14, color: AppTheme.warning),
                        SizedBox(width: 4),
                        Text(
                          'Belum Tersinkron (Ketuk untuk coba lagi)',
                          style: TextStyle(fontSize: 11, color: AppTheme.warning, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),

          // Quill Editor (Read-Only)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: QuillEditor(
                controller: _quillController!,
                focusNode: _focusNode,
                scrollController: _scrollController,
                config: const QuillEditorConfig(
                  autoFocus: false,
                  expands: true,
                  padding: EdgeInsets.zero,
                  placeholder: 'Materi kosong.',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

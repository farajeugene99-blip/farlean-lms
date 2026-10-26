import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/cloudinary_upload_service.dart';

class SubmissionFormData {
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final String note;

  const SubmissionFormData({
    required this.fileUrl,
    required this.fileName,
    this.fileSize = 0,
    required this.note,
  });
}

class SubmitAssignmentDialog extends StatefulWidget {
  final bool isResubmit;
  final String? initialFileUrl;
  final String? initialFileName;
  final int? initialFileSize;
  final String? initialNote;
  final String? classId;
  final String? assignmentId;
  final List<String> allowedFileTypes;
  final int maxFileSizeMb;
  final CloudinaryUploadService? cloudinaryUploadService;

  const SubmitAssignmentDialog({
    super.key,
    this.isResubmit = false,
    this.initialFileUrl,
    this.initialFileName,
    this.initialFileSize,
    this.initialNote,
    this.classId,
    this.assignmentId,
    this.allowedFileTypes = const ['pdf', 'doc', 'docx', 'zip'],
    this.maxFileSizeMb = 10,
    this.cloudinaryUploadService,
  });

  @override
  State<SubmitAssignmentDialog> createState() => _SubmitAssignmentDialogState();
}

class _SubmitAssignmentDialogState extends State<SubmitAssignmentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _noteController;
  late final CloudinaryUploadService _uploadService;

  PlatformFile? _selectedFile;
  String? _selectedFileName;
  int? _selectedFileSize;
  bool _isUploading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _uploadService = widget.cloudinaryUploadService ?? CloudinaryUploadService();
    _noteController = TextEditingController(text: widget.initialNote ?? '');
    _selectedFileName = widget.initialFileName;
    _selectedFileSize = widget.initialFileSize;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _pickFile() async {
    setState(() => _errorMessage = null);
    try {
      final file = await _uploadService.pickDocumentFile(
        allowedExtensions: widget.allowedFileTypes,
      );
      if (file == null) return;

      final size = await _uploadService.validateFile(
        file,
        allowedExtensions: widget.allowedFileTypes,
      );

      final maxBytes = widget.maxFileSizeMb * 1024 * 1024;
      if (size > maxBytes) {
        throw CloudinaryUploadException(
          'Ukuran berkas melebihi batas maksimal ${widget.maxFileSizeMb} MB.',
        );
      }

      setState(() {
        _selectedFile = file;
        _selectedFileName = file.name;
        _selectedFileSize = size;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _selectedFileName = null;
      _selectedFileSize = null;
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    if (_isUploading) return;
    setState(() => _errorMessage = null);

    final hasPickedFile = _selectedFile != null;
    final hasExistingResubmitFile = widget.isResubmit &&
        _selectedFile == null &&
        (widget.initialFileUrl != null && widget.initialFileUrl!.isNotEmpty) &&
        (_selectedFileName != null && _selectedFileName!.isNotEmpty);

    if (!hasPickedFile && !hasExistingResubmitFile) {
      setState(() {
        _errorMessage = 'Silakan pilih berkas tugas terlebih dahulu.';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (hasPickedFile) {
      setState(() => _isUploading = true);
      try {
        final result = await _uploadService.uploadFile(
          file: _selectedFile!,
          folderType: 'assignments',
          classId: widget.classId,
          assignmentId: widget.assignmentId,
          allowedExtensions: widget.allowedFileTypes,
        );

        if (mounted) {
          Navigator.of(context).pop(
            SubmissionFormData(
              fileUrl: result.secureUrl,
              fileName: result.fileName,
              fileSize: result.sizeBytes,
              note: _noteController.text.trim(),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isUploading = false;
            _errorMessage = e.toString().replaceFirst('Exception: ', '');
          });
        }
      }
    } else if (hasExistingResubmitFile) {
      // Pengumpulan ulang dengan mempertahankan berkas yang sudah ada sebelumnya
      Navigator.of(context).pop(
        SubmissionFormData(
          fileUrl: widget.initialFileUrl!,
          fileName: widget.initialFileName ?? 'tugas.pdf',
          fileSize: widget.initialFileSize ?? 1048576,
          note: _noteController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasFile = _selectedFile != null || (widget.isResubmit && widget.initialFileUrl != null && widget.initialFileUrl!.isNotEmpty && _selectedFileName != null);

    return PopScope(
      canPop: !_isUploading,
      child: AlertDialog(
        title: Text(widget.isResubmit ? l10n.assignmentResubmitBtn : l10n.assignmentSubmitBtn),
        content: SizedBox(
          width: 440,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Berkas Tugas',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (hasFile)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.attach_file_rounded, color: AppTheme.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedFileName ?? 'Berkas Tugas',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_selectedFileSize != null)
                                  Text(
                                    _formatFileSize(_selectedFileSize!),
                                    style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                            tooltip: 'Ganti Berkas',
                            onPressed: _isUploading ? null : _pickFile,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppTheme.error, size: 20),
                            tooltip: 'Hapus Berkas',
                            onPressed: _isUploading ? null : _removeFile,
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isUploading ? null : _pickFile,
                          icon: const Icon(Icons.upload_file_rounded, size: 18),
                          label: const Text('Pilih Berkas dari Perangkat'),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Format yang diizinkan: ${widget.allowedFileTypes.map((e) => e.toUpperCase()).join(', ')} (Maks. ${widget.maxFileSizeMb} MB)',
                          style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                        ),
                      ],
                    ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 11, color: AppTheme.error),
                    ),
                  ],

                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: l10n.assignmentFeedbackLabel,
                      hintText: 'Catatan tambahan untuk dosen (opsional)',
                    ),
                    maxLines: 2,
                    enabled: !_isUploading,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : () => Navigator.of(context).pop(null),
            child: Text(l10n.btnCancel),
          ),
          ElevatedButton(
            onPressed: _isUploading ? null : _submit,
            child: _isUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(widget.isResubmit ? l10n.assignmentResubmitBtn : l10n.assignmentSubmitBtn),
          ),
        ],
      ),
    );
  }
}

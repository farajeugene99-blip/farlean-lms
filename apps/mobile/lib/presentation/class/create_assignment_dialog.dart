import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/assignment.dart';
import '../../services/cloudinary_upload_service.dart';

class AssignmentFormData {
  final String title;
  final String instructions;
  final DateTime deadline;
  final bool isGroup;
  final bool allowLate;
  final String? meetingId;
  final String? attachmentUrl;
  final String? attachmentFileName;
  final int? attachmentFileSize;

  const AssignmentFormData({
    required this.title,
    required this.instructions,
    required this.deadline,
    required this.isGroup,
    required this.allowLate,
    this.meetingId,
    this.attachmentUrl,
    this.attachmentFileName,
    this.attachmentFileSize,
  });
}

class AssignmentFormDialog extends StatefulWidget {
  final Assignment? initialAssignment;
  final bool hasSubmissions;
  final DateTime? initialDeadline;
  final String? preselectedMeetingId;
  final String? classId;
  final CloudinaryUploadService? cloudinaryUploadService;

  const AssignmentFormDialog({
    super.key,
    this.initialAssignment,
    this.hasSubmissions = false,
    this.initialDeadline,
    this.preselectedMeetingId,
    this.classId,
    this.cloudinaryUploadService,
  });

  bool get isEdit => initialAssignment != null;

  @override
  State<AssignmentFormDialog> createState() => _AssignmentFormDialogState();
}

// Alias untuk backward compatibility
typedef CreateAssignmentDialog = AssignmentFormDialog;

class _AssignmentFormDialogState extends State<AssignmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _instructionsController;
  late final TextEditingController _attachmentUrlController;
  late final TextEditingController _attachmentNameController;
  late final CloudinaryUploadService _uploadService;
  late DateTime _deadline;
  late bool _isGroup;
  late bool _allowLate;
  late String? _meetingId;
  int? _attachmentFileSize;
  bool _isUploading = false;
  String? _uploadError;
  bool _showManualUrlField = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initialAssignment;
    _uploadService = widget.cloudinaryUploadService ?? CloudinaryUploadService();
    _titleController = TextEditingController(text: init?.title ?? '');
    _instructionsController = TextEditingController(text: init?.instructions ?? '');
    _attachmentUrlController = TextEditingController(text: init?.attachmentUrl ?? '');
    _attachmentNameController = TextEditingController(text: init?.attachmentFileName ?? '');
    _attachmentFileSize = init?.attachmentFileSize;
    _deadline = init?.deadline ?? widget.initialDeadline ?? DateTime.now().add(const Duration(days: 7));
    _isGroup = init?.isGroupAssignment ?? false;
    _allowLate = init?.allowLateSubmission ?? true;
    _meetingId = init?.meetingId ?? widget.preselectedMeetingId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    _attachmentUrlController.dispose();
    _attachmentNameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAttachment() async {
    setState(() {
      _uploadError = null;
    });

    try {
      final file = await _uploadService.pickDocumentFile();
      if (file == null) return;

      setState(() => _isUploading = true);

      final result = await _uploadService.uploadFile(
        file: file,
        folderType: 'assignment_instructions',
        classId: widget.classId ?? widget.initialAssignment?.classId,
      );

      if (mounted) {
        setState(() {
          _attachmentUrlController.text = result.secureUrl;
          _attachmentNameController.text = result.fileName;
          _attachmentFileSize = result.sizeBytes;
          _isUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _removeAttachment() {
    setState(() {
      _attachmentUrlController.clear();
      _attachmentNameController.clear();
      _attachmentFileSize = null;
      _uploadError = null;
    });
  }

  void _submit() {
    if (_isUploading) return;
    if (!_formKey.currentState!.validate()) return;
    final rawUrl = _attachmentUrlController.text.trim();
    final rawName = _attachmentNameController.text.trim();

    Navigator.of(context).pop(
      AssignmentFormData(
        title: _titleController.text.trim(),
        instructions: _instructionsController.text.trim(),
        deadline: _deadline,
        isGroup: _isGroup,
        allowLate: _allowLate,
        meetingId: _meetingId,
        attachmentUrl: rawUrl.isNotEmpty ? rawUrl : null,
        attachmentFileName: rawName.isNotEmpty ? rawName : (rawUrl.isNotEmpty ? 'petunjuk_tugas.pdf' : null),
        attachmentFileSize: rawUrl.isNotEmpty ? _attachmentFileSize : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEdit = widget.isEdit;
    final hasAttachment = _attachmentUrlController.text.trim().isNotEmpty;

    return AlertDialog(
      title: Text(isEdit ? 'Ubah Tugas' : l10n.assignmentCreateTitle),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: l10n.assignmentTitleLabel,
                    hintText: 'Contoh: Tugas 1 - Desain ERD',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? l10n.assignmentTitleRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _instructionsController,
                  decoration: InputDecoration(
                    labelText: l10n.assignmentInstructionsLabel,
                    hintText: 'Petunjuk pengerjaan dan format berkas...',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Text('${l10n.assignmentDeadlineLabel}:', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text(DateFormatter.formatWib(_deadline)),
                  onPressed: () async {
                    final firstAllowed = _deadline.isBefore(DateTime.now())
                        ? _deadline.subtract(const Duration(days: 30))
                        : DateTime.now().subtract(const Duration(days: 1));
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _deadline,
                      firstDate: firstAllowed,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _deadline = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          23,
                          59,
                        );
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(l10n.assignmentIsGroupLabel, style: const TextStyle(fontSize: 13)),
                  subtitle: widget.hasSubmissions
                      ? const Text(
                          'Tipe tugas terkunci karena sudah ada mahasiswa yang mengumpulkan tugas.',
                          style: TextStyle(fontSize: 11, color: Colors.orange),
                        )
                      : null,
                  value: _isGroup,
                  onChanged: widget.hasSubmissions
                      ? null
                      : (val) => setState(() => _isGroup = val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(l10n.assignmentAllowLateLabel, style: const TextStyle(fontSize: 13)),
                  value: _allowLate,
                  onChanged: (val) => setState(() => _allowLate = val),
                ),
                const SizedBox(height: 12),
                if (_meetingId != null && _meetingId!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.teal.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.link_rounded, size: 16, color: Colors.teal),
                          SizedBox(width: 6),
                          Text(
                            'Terkoneksi ke Pertemuan',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.teal),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Bagian Lampiran Berkas Petunjuk
                const Divider(),
                const SizedBox(height: 6),
                const Text(
                  'Lampiran Berkas Petunjuk (Opsional)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Dosen dapat mengunggah lembar soal/panduan (PDF, DOCX, ZIP maks 10MB)',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 8),

                if (_isUploading)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primary.withAlpha(50)),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Mengunggah berkas petunjuk ke Cloudinary...',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (hasAttachment)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
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
                                _attachmentNameController.text.trim().isNotEmpty
                                    ? _attachmentNameController.text.trim()
                                    : 'Berkas Petunjuk',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_attachmentFileSize != null)
                                Text(
                                  '${(_attachmentFileSize! / (1024 * 1024)).toStringAsFixed(1)} MB',
                                  style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                          tooltip: 'Ganti Berkas',
                          onPressed: _pickAndUploadAttachment,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.error, size: 20),
                          tooltip: 'Hapus Lampiran',
                          onPressed: _removeAttachment,
                        ),
                      ],
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _pickAndUploadAttachment,
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    label: const Text('Pilih Berkas dari Perangkat'),
                  ),

                if (_uploadError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _uploadError!,
                    style: const TextStyle(fontSize: 11, color: AppTheme.error),
                  ),
                ],

                const SizedBox(height: 6),
                InkWell(
                  onTap: () => setState(() => _showManualUrlField = !_showManualUrlField),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showManualUrlField ? Icons.arrow_drop_down_rounded : Icons.arrow_right_rounded,
                          size: 18,
                          color: context.textSecondaryColor,
                        ),
                        Text(
                          'Opsi URL manual',
                          style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showManualUrlField) ...[
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _attachmentUrlController,
                    decoration: const InputDecoration(
                      labelText: 'URL Berkas Petunjuk',
                      hintText: 'https://res.cloudinary.com/.../petunjuk.pdf',
                      prefixIcon: Icon(Icons.link_rounded, size: 18),
                    ),
                    validator: (v) {
                      if (v != null && v.trim().isNotEmpty && !v.trim().startsWith('https://')) {
                        return 'URL harus diawali dengan https://';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _attachmentNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Berkas Lampiran',
                      hintText: 'Panduan_Tugas.pdf',
                      prefixIcon: Icon(Icons.description_outlined, size: 18),
                    ),
                  ),
                ],
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
              : Text(l10n.btnSave),
        ),
      ],
    );
  }
}


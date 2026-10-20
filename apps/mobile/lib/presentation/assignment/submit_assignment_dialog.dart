import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

class SubmissionFormData {
  final String fileUrl;
  final String fileName;
  final String note;

  const SubmissionFormData({
    required this.fileUrl,
    required this.fileName,
    required this.note,
  });
}

class SubmitAssignmentDialog extends StatefulWidget {
  final bool isResubmit;
  final String? initialFileUrl;
  final String? initialFileName;
  final String? initialNote;

  const SubmitAssignmentDialog({
    super.key,
    this.isResubmit = false,
    this.initialFileUrl,
    this.initialFileName,
    this.initialNote,
  });

  @override
  State<SubmitAssignmentDialog> createState() => _SubmitAssignmentDialogState();
}

class _SubmitAssignmentDialogState extends State<SubmitAssignmentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;
  late final TextEditingController _nameController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialFileUrl ?? '');
    _nameController = TextEditingController(text: widget.initialFileName ?? 'tugas.pdf');
    _noteController = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      SubmissionFormData(
        fileUrl: _urlController.text.trim(),
        fileName: _nameController.text.trim(),
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(widget.isResubmit ? l10n.assignmentResubmitBtn : l10n.assignmentSubmitBtn),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: l10n.manualBookUrlLabel,
                    hintText: 'https://res.cloudinary.com/...',
                    prefixIcon: const Icon(Icons.link_rounded, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return l10n.manualBookUrlRequired;
                    if (!v.trim().startsWith('https://')) return l10n.manualBookUrlInvalid;
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.assignmentFileLabel,
                    prefixIcon: const Icon(Icons.description_outlined, size: 20),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Nama berkas wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: l10n.assignmentFeedbackLabel,
                    hintText: 'Catatan tambahan (opsional)',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(null), child: Text(l10n.btnCancel)),
        ElevatedButton(
          onPressed: _submit,
          child: Text(l10n.btnSave),
        ),
      ],
    );
  }
}

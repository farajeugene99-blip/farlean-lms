import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

class ManualBookFormData {
  final String title;
  final String description;
  final String fileUrl;
  final String fileName;
  final bool isPublished;

  const ManualBookFormData({
    required this.title,
    required this.description,
    required this.fileUrl,
    required this.fileName,
    required this.isPublished,
  });
}

class CreateManualBookDialog extends StatefulWidget {
  final String? initialTitle;
  final String? initialDescription;
  final String? initialUrl;
  final String? initialFileName;
  final bool initialIsPublished;

  const CreateManualBookDialog({
    super.key,
    this.initialTitle,
    this.initialDescription,
    this.initialUrl,
    this.initialFileName,
    this.initialIsPublished = true,
  });

  @override
  State<CreateManualBookDialog> createState() => _CreateManualBookDialogState();
}

class _CreateManualBookDialogState extends State<CreateManualBookDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _urlController;
  late final TextEditingController _fileNameController;
  late bool _isPublished;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _descController = TextEditingController(text: widget.initialDescription ?? '');
    _urlController = TextEditingController(text: widget.initialUrl ?? '');
    _fileNameController = TextEditingController(text: widget.initialFileName ?? 'panduan.pdf');
    _isPublished = widget.initialIsPublished;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _urlController.dispose();
    _fileNameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      ManualBookFormData(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        fileUrl: _urlController.text.trim(),
        fileName: _fileNameController.text.trim(),
        isPublished: _isPublished,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.manualBookAddTitle),
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
                    labelText: l10n.manualBookTitleLabel,
                    hintText: 'Contoh: Buku Panduan Mahasiswa',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? l10n.manualBookTitleRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  decoration: InputDecoration(
                    labelText: l10n.manualBookDescLabel,
                    hintText: 'Ringkasan isi panduan aplikasi...',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: l10n.manualBookUrlLabel,
                    hintText: 'https://res.cloudinary.com/.../manual.pdf',
                    prefixIcon: const Icon(Icons.link_rounded, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return l10n.manualBookUrlRequired;
                    final trimmed = v.trim();
                    if (!trimmed.startsWith('https://')) {
                      return l10n.manualBookUrlInvalid;
                    }
                    if (!trimmed.toLowerCase().endsWith('.pdf') && !trimmed.toLowerCase().contains('/raw/upload') && !trimmed.toLowerCase().contains('/auto/upload')) {
                      return 'Berkas panduan harus berformat PDF (.pdf)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fileNameController,
                  decoration: InputDecoration(labelText: l10n.manualBookFileNameLabel),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Publikasikan Sekarang', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Buku panduan langsung dapat dibaca oleh seluruh pengguna aplikasi', style: TextStyle(fontSize: 11)),
                  value: _isPublished,
                  onChanged: (val) => setState(() => _isPublished = val),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.btnCancel),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(l10n.btnSave),
        ),
      ],
    );
  }
}

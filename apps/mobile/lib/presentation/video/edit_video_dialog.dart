import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/ai_service.dart';

class VideoFormData {
  final String title;
  final String description;

  const VideoFormData({
    required this.title,
    required this.description,
  });
}

class EditVideoDialog extends StatefulWidget {
  final String initialTitle;
  final String initialDescription;
  final AiService aiService;

  const EditVideoDialog({
    super.key,
    required this.initialTitle,
    required this.initialDescription,
    required this.aiService,
  });

  @override
  State<EditVideoDialog> createState() => _EditVideoDialogState();
}

class _EditVideoDialogState extends State<EditVideoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  bool _isDrafting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _descController = TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _requestAiDraft() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isDrafting = true);

    try {
      final draft = await widget.aiService.generateVideoDescription(
        title: _titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : 'Video Pembelajaran',
        existingDescription: _descController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _descController.text = draft;
          _isDrafting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.aiVideoDraftSuccess), backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDrafting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      VideoFormData(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.videoEditTitle),
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
                    labelText: l10n.videoTitleLabel,
                    hintText: 'Contoh: Penjelasan State Management',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(l10n.videoDescLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _isDrafting ? null : _requestAiDraft,
                      icon: _isDrafting
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.auto_awesome_rounded, size: 16),
                      label: Text(l10n.aiVideoDraftBtn, style: const TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    hintText: 'Tuliskan deskripsi atau rangkuman video...',
                  ),
                  maxLines: 5,
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

import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

/// Data hasil input dari dialog pembuatan pertemuan
class MeetingFormData {
  final int number;
  final String title;

  const MeetingFormData({
    required this.number,
    required this.title,
  });
}

/// Dialog bersama untuk membuat pertemuan baru (digunakan di ClassDetailScreen dan MeetingListScreen)
class CreateMeetingDialog extends StatefulWidget {
  final int initialNumber;
  final String? submitButtonText;

  const CreateMeetingDialog({
    super.key,
    required this.initialNumber,
    this.submitButtonText,
  });

  @override
  State<CreateMeetingDialog> createState() => _CreateMeetingDialogState();
}

class _CreateMeetingDialogState extends State<CreateMeetingDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numberController;
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController(text: '${widget.initialNumber}');
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _numberController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final num = int.parse(_numberController.text.trim());
    final title = _titleController.text.trim();
    Navigator.of(context).pop(MeetingFormData(number: num, title: title));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(
        l10n.meetingCreateTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _numberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.meetingNumberLabel),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l10n.meetingNumberRequired;
                  final num = int.tryParse(v.trim());
                  if (num == null || num <= 0) return l10n.meetingNumberMustBePositive;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: l10n.meetingTitleLabel),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l10n.meetingTitleRequired;
                  return null;
                },
              ),
            ],
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
          child: Text(widget.submitButtonText ?? l10n.classSaveMeetingBtn),
        ),
      ],
    );
  }
}

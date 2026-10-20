import 'package:flutter/material.dart';
import '../../core/utils/date_formatter.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/assignment.dart';

class AssignmentFormData {
  final String title;
  final String instructions;
  final DateTime deadline;
  final bool isGroup;
  final bool allowLate;

  const AssignmentFormData({
    required this.title,
    required this.instructions,
    required this.deadline,
    required this.isGroup,
    required this.allowLate,
  });
}

class AssignmentFormDialog extends StatefulWidget {
  final Assignment? initialAssignment;
  final bool hasSubmissions;
  final DateTime? initialDeadline;

  const AssignmentFormDialog({
    super.key,
    this.initialAssignment,
    this.hasSubmissions = false,
    this.initialDeadline,
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
  late DateTime _deadline;
  late bool _isGroup;
  late bool _allowLate;

  @override
  void initState() {
    super.initState();
    final init = widget.initialAssignment;
    _titleController = TextEditingController(text: init?.title ?? '');
    _instructionsController = TextEditingController(text: init?.instructions ?? '');
    _deadline = init?.deadline ?? widget.initialDeadline ?? DateTime.now().add(const Duration(days: 7));
    _isGroup = init?.isGroupAssignment ?? false;
    _allowLate = init?.allowLateSubmission ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      AssignmentFormData(
        title: _titleController.text.trim(),
        instructions: _instructionsController.text.trim(),
        deadline: _deadline,
        isGroup: _isGroup,
        allowLate: _allowLate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEdit = widget.isEdit;

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

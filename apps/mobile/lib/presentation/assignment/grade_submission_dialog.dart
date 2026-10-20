import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

class GradeFormData {
  final double score;
  final String feedback;

  const GradeFormData({
    required this.score,
    required this.feedback,
  });
}

class GradeSubmissionDialog extends StatefulWidget {
  final double? initialScore;
  final String? initialFeedback;

  const GradeSubmissionDialog({
    super.key,
    this.initialScore,
    this.initialFeedback,
  });

  @override
  State<GradeSubmissionDialog> createState() => _GradeSubmissionDialogState();
}

class _GradeSubmissionDialogState extends State<GradeSubmissionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _scoreController;
  late final TextEditingController _feedbackController;

  @override
  void initState() {
    super.initState();
    _scoreController = TextEditingController(text: widget.initialScore?.toStringAsFixed(0) ?? '');
    _feedbackController = TextEditingController(text: widget.initialFeedback ?? '');
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      GradeFormData(
        score: double.parse(_scoreController.text.trim()),
        feedback: _feedbackController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.assignmentGradeTitle),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _scoreController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.assignmentScoreLabel,
                  prefixIcon: const Icon(Icons.star_outline_rounded, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Nilai wajib diisi';
                  final numVal = double.tryParse(v.trim());
                  if (numVal == null || numVal < 0 || numVal > 100) {
                    return 'Masukkan angka 0 - 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _feedbackController,
                decoration: InputDecoration(
                  labelText: l10n.assignmentFeedbackLabel,
                  hintText: 'Umpan balik untuk mahasiswa/kelompok',
                ),
                maxLines: 3,
              ),
            ],
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

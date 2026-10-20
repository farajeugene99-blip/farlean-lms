import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/class_member.dart';

class GroupFormData {
  final String name;
  final List<ClassMember> selectedMembers;

  const GroupFormData({
    required this.name,
    required this.selectedMembers,
  });
}

class GroupFormDialog extends StatefulWidget {
  final String? initialName;
  final List<ClassMember> pool;
  final Set<ClassMember> initialSelected;
  final bool isEdit;

  const GroupFormDialog({
    super.key,
    this.initialName,
    required this.pool,
    required this.initialSelected,
    this.isEdit = false,
  });

  @override
  State<GroupFormDialog> createState() => _GroupFormDialogState();
}

class _GroupFormDialogState extends State<GroupFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final Set<ClassMember> _selectedMembers;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedMembers = Set<ClassMember>.from(widget.initialSelected);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      GroupFormData(
        name: _nameController.text.trim(),
        selectedMembers: _selectedMembers.toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(widget.isEdit ? l10n.groupsEditTitle : l10n.groupsCreateTitle),
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
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.groupsNameLabel,
                    hintText: l10n.groupsNameHint,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? l10n.groupsNameRequired : null,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.groupsSelectMembersTitle(_selectedMembers.length),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                if (widget.pool.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      l10n.groupsNoAvailableMembers,
                      style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                    ),
                  )
                else
                  Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      border: Border.all(color: context.borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: widget.pool.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final m = widget.pool[i];
                        final isChecked = _selectedMembers.contains(m);
                        return CheckboxListTile(
                          dense: true,
                          title: Text(m.displayName, style: const TextStyle(fontSize: 13)),
                          subtitle: m.nim != null ? Text('NIM: ${m.nim}', style: const TextStyle(fontSize: 11)) : null,
                          value: isChecked,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedMembers.add(m);
                              } else {
                                _selectedMembers.remove(m);
                              }
                            });
                          },
                        );
                      },
                    ),
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

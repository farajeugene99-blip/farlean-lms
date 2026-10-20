import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/class_group.dart';
import '../../models/class_member.dart';

class GroupFormData {
  final String name;
  final List<ClassMember> selectedMembers;

  const GroupFormData({
    required this.name,
    required this.selectedMembers,
  });
}

class GroupDialogResult {
  final bool isRandom;
  final GroupFormData? manualGroup;
  final List<ClassGroup>? randomGroups;

  const GroupDialogResult.manual(this.manualGroup)
      : isRandom = false,
        randomGroups = null;

  const GroupDialogResult.random(this.randomGroups)
      : isRandom = true,
        manualGroup = null;
}

class GroupFormDialog extends StatefulWidget {
  final String? initialName;
  final List<ClassMember> pool;
  final Set<ClassMember> initialSelected;
  final bool isEdit;
  final int existingGroupCount;
  final String classId;

  const GroupFormDialog({
    super.key,
    this.initialName,
    required this.pool,
    required this.initialSelected,
    this.isEdit = false,
    this.existingGroupCount = 0,
    this.classId = '',
  });

  @override
  State<GroupFormDialog> createState() => _GroupFormDialogState();
}

class _GroupFormDialogState extends State<GroupFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final Set<ClassMember> _selectedMembers;

  int _creationMode = 0; // 0 = Manual, 1 = Acak
  int _randomStrategy = 0; // 0 = Jumlah Kelompok (K), 1 = Anggota per Kelompok (S)
  final TextEditingController _randomInputController = TextEditingController(text: '2');
  List<ClassGroup>? _generatedRandomGroups;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedMembers = Set<ClassMember>.from(widget.initialSelected);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _randomInputController.dispose();
    super.dispose();
  }

  void _submitManual() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      GroupDialogResult.manual(
        GroupFormData(
          name: _nameController.text.trim(),
          selectedMembers: _selectedMembers.toList(),
        ),
      ),
    );
  }

  void _generateRandomGroups() {
    final availableStudents = List<ClassMember>.from(widget.pool);
    final n = availableStudents.length;
    if (n == 0) return;

    final inputVal = int.tryParse(_randomInputController.text.trim()) ?? 1;
    int k;

    if (_randomStrategy == 0) {
      // Opsi A: Jumlah Kelompok (K)
      k = inputVal.clamp(1, n);
    } else {
      // Opsi B: Ukuran per Kelompok (S)
      final s = inputVal.clamp(1, n);
      k = (n / s).ceil().clamp(1, n);
    }

    // Acak urutan mahasiswa (Fisher-Yates via Random)
    availableStudents.shuffle(Random());

    final baseSize = n ~/ k;
    final remainder = n % k;

    final List<ClassGroup> groups = [];
    int studentIndex = 0;

    for (int i = 0; i < k; i++) {
      final size = i < remainder ? baseSize + 1 : baseSize;
      final groupMembers = availableStudents.sublist(studentIndex, studentIndex + size);
      studentIndex += size;

      final groupNum = widget.existingGroupCount + i + 1;
      final groupName = 'Kelompok $groupNum';

      groups.add(
        ClassGroup(
          id: '',
          classId: widget.classId,
          name: groupName,
          memberUids: groupMembers.map((m) => m.uid).toList(),
          memberNames: {for (final m in groupMembers) m.uid: m.displayName},
        ),
      );
    }

    setState(() {
      _generatedRandomGroups = groups;
    });
  }

  void _submitRandom() {
    if (_generatedRandomGroups == null || _generatedRandomGroups!.isEmpty) return;
    Navigator.of(context).pop(GroupDialogResult.random(_generatedRandomGroups));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(widget.isEdit ? l10n.groupsEditTitle : l10n.groupsCreateTitle),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.isEdit) ...[
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment<int>(
                      value: 0,
                      label: Text('Manual'),
                      icon: Icon(Icons.touch_app_rounded, size: 16),
                    ),
                    ButtonSegment<int>(
                      value: 1,
                      label: Text('Acak (Random)'),
                      icon: Icon(Icons.shuffle_rounded, size: 16),
                    ),
                  ],
                  selected: {_creationMode},
                  onSelectionChanged: (set) {
                    setState(() => _creationMode = set.first);
                  },
                ),
                const SizedBox(height: 16),
              ],
              if (_creationMode == 0 || widget.isEdit)
                _buildManualForm(l10n)
              else
                _buildRandomForm(l10n),
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
          onPressed: (_creationMode == 0 || widget.isEdit) ? _submitManual : (_generatedRandomGroups != null ? _submitRandom : null),
          child: Text((_creationMode == 1 && !widget.isEdit) ? 'Simpan Semua Kelompok' : l10n.btnSave),
        ),
      ],
    );
  }

  Widget _buildManualForm(AppLocalizations l10n) {
    return Form(
      key: _formKey,
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
    );
  }

  Widget _buildRandomForm(AppLocalizations l10n) {
    final n = widget.pool.length;
    if (n == 0) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            l10n.groupsNoAvailableMembers,
            style: TextStyle(fontSize: 13, color: context.textSecondaryColor),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.primary.withAlpha(40)),
          ),
          child: Row(
            children: [
              const Icon(Icons.people_alt_outlined, color: AppTheme.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                'Mahasiswa aktif tersedia: $n orang',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Pilihan Strategi Pembagian
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Jumlah Kelompok', style: TextStyle(fontSize: 12)),
                selected: _randomStrategy == 0,
                onSelected: (val) {
                  if (val) setState(() => _randomStrategy = 0);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Text('Ukuran per Kelompok', style: TextStyle(fontSize: 12)),
                selected: _randomStrategy == 1,
                onSelected: (val) {
                  if (val) setState(() => _randomStrategy = 1);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _randomInputController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _randomStrategy == 0 ? 'Berapa Kelompok? (1 - $n)' : 'Berapa Mahasiswa per Kelompok? (1 - $n)',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _generateRandomGroups,
              icon: const Icon(Icons.shuffle_rounded, size: 16),
              label: const Text('Acak'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_generatedRandomGroups != null) ...[
          Text(
            'Pratinjau Hasil Pembagian (${_generatedRandomGroups!.length} Kelompok):',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 240),
            decoration: BoxDecoration(
              border: Border.all(color: context.borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _generatedRandomGroups!.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (ctx, idx) {
                final grp = _generatedRandomGroups![idx];
                return Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(grp.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 8),
                          Text(
                            '(${grp.memberUids.length} orang)',
                            style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: grp.memberUids.map((uid) {
                          final name = grp.memberNames[uid] ?? 'Mahasiswa';
                          return Chip(
                            label: Text(name, style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

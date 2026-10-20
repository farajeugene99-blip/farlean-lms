import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/models/assignment.dart';
import 'package:mobile/presentation/class/create_assignment_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AssignmentFormDialog Edit Guard Tests (Masalah D)', () {
    final pastDeadline = DateTime.now().subtract(const Duration(days: 2));
    final existingAssignment = Assignment(
      id: 'assign_1',
      classId: 'c1',
      title: 'Tugas Perancangan Basis Data',
      instructions: 'Buat skema konseptual ERD dan relasional.',
      deadline: pastDeadline,
      isGroupAssignment: true,
      allowLateSubmission: false,
    );

    testWidgets('1. Mode Edit menampilkan nilai awal dan menolak perubahan tipe tugas saat hasSubmissions == true', (tester) async {
      AssignmentFormData? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  result = await showDialog<AssignmentFormData>(
                    context: ctx,
                    builder: (_) => AssignmentFormDialog(
                      initialAssignment: existingAssignment,
                      hasSubmissions: true, // Ada submission yang sudah masuk
                    ),
                  );
                },
                child: const Text('Buka'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();

      // Judul dialog mode edit
      expect(find.text('Ubah Tugas'), findsOneWidget);
      // Nilai awal tampil di form
      expect(find.text('Tugas Perancangan Basis Data'), findsOneWidget);
      expect(find.text('Buat skema konseptual ERD dan relasional.'), findsOneWidget);

      // Verifikasi switch tugas kelompok terkunci (disabled) dengan pesan peringatan
      expect(find.textContaining('Tipe tugas terkunci karena sudah ada mahasiswa yang mengumpulkan tugas.'), findsOneWidget);

      // Ubah judul & instruksi (tanpa mengubah deadline lampau)
      await tester.enterText(find.byType(TextFormField).first, 'Tugas Perancangan Basis Data (Revisi Judul)');
      await tester.pumpAndSettle();

      // Simpan perubahan
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // Form berhasil di-submit tanpa error deadline lampau
      expect(result, isNotNull);
      expect(result!.title, equals('Tugas Perancangan Basis Data (Revisi Judul)'));
      expect(result!.isGroup, isTrue); // Tetap kelompok
      expect(tester.takeException(), isNull);
    });
  });
}

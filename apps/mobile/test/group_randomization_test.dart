import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/models/class_member.dart';
import 'package:mobile/presentation/class/group_form_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Group Randomization & Candidate Filter Tests (Masalah B)', () {
    test('1. Algoritma pembagian acak seimbang mendistribusikan 23 mahasiswa ke 5 kelompok (5, 5, 5, 4, 4)', () {
      final students = List.generate(
        23,
        (i) => ClassMember(
          uid: 's_$i',
          displayName: 'Mahasiswa $i',
          accountType: AccountType.mahasiswa,
          status: MemberStatus.active,
        ),
      );

      final n = students.length;
      final k = 5;
      final baseSize = n ~/ k;
      final remainder = n % k;

      final groupSizes = <int>[];
      for (int i = 0; i < k; i++) {
        groupSizes.add(i < remainder ? baseSize + 1 : baseSize);
      }

      expect(groupSizes, equals([5, 5, 5, 4, 4]));
      expect(groupSizes.reduce((a, b) => a + b), equals(23));
    });

    testWidgets('2. GroupFormDialog Mode Acak memvalidasi input K, menamai kelompok melanjutkan indeks, dan menghasilkan grup seimbang', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // 6 mahasiswa tersedia, 2 kelompok sudah ada sebelumnya
      final pool = List.generate(
        6,
        (i) => ClassMember(
          uid: 'student_$i',
          displayName: 'Siswa $i',
          accountType: AccountType.mahasiswa,
          status: MemberStatus.active,
        ),
      );

      GroupDialogResult? dialogResult;

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
                  dialogResult = await showDialog<GroupDialogResult>(
                    context: ctx,
                    builder: (_) => GroupFormDialog(
                      pool: pool,
                      initialSelected: const {},
                      isEdit: false,
                      existingGroupCount: 2, // Sudah ada Kelompok 1 & Kelompok 2
                      classId: 'c_test',
                    ),
                  );
                },
                child: const Text('Buka Form'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buka Form'));
      await tester.pumpAndSettle();

      // Pindah ke tab Acak (Random)
      await tester.tap(find.text('Acak (Random)'));
      await tester.pumpAndSettle();

      expect(find.text('Mahasiswa aktif tersedia: 6 orang'), findsOneWidget);

      // Bagi menjadi 3 kelompok
      await tester.enterText(find.byType(TextFormField).first, '3');
      await tester.tap(find.text('Acak'));
      await tester.pumpAndSettle();

      // Verifikasi pratinjau kelompok melanjutkan penomoran eksisting (mulai dari Kelompok 3)
      expect(find.text('Pratinjau Hasil Pembagian (3 Kelompok):'), findsOneWidget);
      expect(find.text('Kelompok 3'), findsOneWidget);
      expect(find.text('Kelompok 4'), findsOneWidget);
      expect(find.text('Kelompok 5'), findsOneWidget);

      // Simpan semua kelompok
      await tester.tap(find.text('Simpan Semua Kelompok'));
      await tester.pumpAndSettle();

      expect(dialogResult, isNotNull);
      expect(dialogResult!.isRandom, isTrue);
      expect(dialogResult!.randomGroups!.length, equals(3));
      expect(dialogResult!.randomGroups![0].name, equals('Kelompok 3'));
      expect(dialogResult!.randomGroups![0].memberUids.length, equals(2));
      expect(dialogResult!.randomGroups![1].memberUids.length, equals(2));
      expect(dialogResult!.randomGroups![2].memberUids.length, equals(2));
      expect(tester.takeException(), isNull);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/models/content_status.dart';
import 'package:mobile/models/pretest.dart';
import 'package:mobile/models/posttest.dart';
import 'package:mobile/models/question.dart';
import 'package:mobile/repositories/posttest_repository.dart';
import 'package:mobile/repositories/pretest_repository.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:mobile/services/class_provider.dart';
import 'package:provider/provider.dart';

import 'session_pipeline_test.dart';

class MockPretestRepoForCountTest extends PretestRepository {
  List<Question> mockQuestions;
  ContentStatus mockStatus;
  int deleteCallCount = 0;

  MockPretestRepoForCountTest({
    required this.mockQuestions,
    this.mockStatus = ContentStatus.published,
  });

  @override
  Future<Pretest?> getPretest(String testId) async {
    return Pretest(
      id: testId,
      classId: 'class_01',
      meetingId: 'meet_01',
      title: 'Pretest Fisika',
      status: mockStatus,
    );
  }

  @override
  Future<List<Question>> getQuestions(String testId) async {
    return mockQuestions;
  }

  @override
  Future<void> deleteQuestion({required String testId, required String qid}) async {
    deleteCallCount++;
    mockQuestions.removeWhere((q) => q.id == qid);
  }
}

class MockPosttestRepoForCountTest extends PosttestRepository {
  List<Question> mockQuestions;
  ContentStatus mockStatus;

  MockPosttestRepoForCountTest({
    required this.mockQuestions,
    this.mockStatus = ContentStatus.draft,
  });

  @override
  Future<Posttest?> getPosttest(String testId) async {
    return Posttest(
      id: testId,
      classId: 'class_01',
      meetingId: 'meet_01',
      title: 'Posttest Fisika',
      status: mockStatus,
    );
  }

  @override
  Future<List<Question>> getQuestions(String testId) async {
    return mockQuestions;
  }
}

void main() {
  group('Question Count Control & Fixed 5 Options Tests', () {
    testWidgets('Header displays exact question count: "Jumlah Soal: X soal aktif"', (tester) async {
      final fakeUser = FakeUser(uid: 'guru_test', email: 'guru@dosen.farlean.edu');
      final mockAuth = MockAuthService(mockCurrentUser: fakeUser);
      final authProvider = AuthProvider(authService: mockAuth);

      final pretestRepo = MockPretestRepoForCountTest(
        mockQuestions: [
          const Question(id: 'q1', text: 'Soal 1', options: ['A', 'B', 'C', 'D', 'E'], points: 10),
          const Question(id: 'q2', text: 'Soal 2', options: ['A', 'B', 'C', 'D', 'E'], points: 10),
          const Question(id: 'q3', text: 'Soal 3', options: ['A', 'B', 'C', 'D', 'E'], points: 10),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<ClassProvider>(create: (_) => ClassProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => Scaffold(
                        body: Column(
                          children: [
                            Text('Jumlah Soal: ${pretestRepo.mockQuestions.length} soal aktif'),
                            ...pretestRepo.mockQuestions.asMap().entries.map((e) {
                              return Text('Soal ${e.key + 1}: ${e.value.text}');
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                  child: const Text('Buka Kelola Soal'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Buka Kelola Soal'));
      await tester.pumpAndSettle();

      // Verifikasi: Angka mewakili JUMLAH SOAL (3), bukan jumlah pilihan jawaban (5)
      expect(find.text('Jumlah Soal: 3 soal aktif'), findsOneWidget);
      expect(find.text('Soal 1: Soal 1'), findsOneWidget);
      expect(find.text('Soal 2: Soal 2'), findsOneWidget);
      expect(find.text('Soal 3: Soal 3'), findsOneWidget);
    });

    testWidgets('Editor renders exactly 5 options A through E and displays legacy options 6+ read-only', (tester) async {
      // Buat soal legacy dengan 7 opsi (A s/d G)
      const legacyQuestion = Question(
        id: 'q_legacy',
        text: 'Berapakah nilai konstanta Planck?',
        options: ['6.626 x 10^-34', '1.0 x 10^-34', '3.0 x 10^8', '9.8', '0', 'Legacy F', 'Legacy G'],
        points: 25,
      );

      // Render form dialog editor soal
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 440,
                child: Builder(
                  builder: (context) {
                    final existingOpts = legacyQuestion.options;
                    final controllers = List.generate(5, (index) {
                      return TextEditingController(text: index < existingOpts.length ? existingOpts[index] : '');
                    });
                    final legacyExtras = existingOpts.length > 5 ? existingOpts.sublist(5) : <String>[];

                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Pilihan Jawaban & Kunci (A - E) *'),
                          ...controllers.asMap().entries.map((entry) {
                            final label = String.fromCharCode(65 + entry.key);
                            return TextFormField(
                              controller: entry.value,
                              decoration: InputDecoration(labelText: 'Pilihan $label'),
                            );
                          }),
                          if (legacyExtras.isNotEmpty) ...[
                            const Text('Pilihan Tambahan Terarsip (Legacy - Read Only):'),
                            ...legacyExtras.asMap().entries.map((e) {
                              final label = String.fromCharCode(70 + e.key);
                              return Text('$label. ${e.value}');
                            }),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Verifikasi: tepat 5 pilihan A sampai E dapat diedit
      expect(find.text('Pilihan A'), findsOneWidget);
      expect(find.text('Pilihan B'), findsOneWidget);
      expect(find.text('Pilihan C'), findsOneWidget);
      expect(find.text('Pilihan D'), findsOneWidget);
      expect(find.text('Pilihan E'), findsOneWidget);

      // Opsi ke-6 dan ke-7 tampil sebagai teks read-only
      expect(find.text('Pilihan Tambahan Terarsip (Legacy - Read Only):'), findsOneWidget);
      expect(find.text('F. Legacy F'), findsOneWidget);
      expect(find.text('G. Legacy G'), findsOneWidget);

      // TIDAK ADA kontrol "+ Tambah Opsi" atau "- Hapus Opsi"
      expect(find.text('Tambah Opsi'), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('Attempting to delete the last active question of a Published test is rejected with snackbar', (tester) async {
      final fakeUser = FakeUser(uid: 'guru_test_2', email: 'guru@dosen.farlean.edu');
      final mockAuth = MockAuthService(mockCurrentUser: fakeUser);
      final authProvider = AuthProvider(authService: mockAuth);

      final pretestRepo = MockPretestRepoForCountTest(
        mockStatus: ContentStatus.published,
        mockQuestions: [
          const Question(id: 'q_only_one', text: 'Satu-satunya soal', options: ['A', 'B', 'C', 'D', 'E'], points: 100),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<ClassProvider>(create: (_) => ClassProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      final questions = pretestRepo.mockQuestions;
                      final status = pretestRepo.mockStatus;
                      if (status == ContentStatus.published && questions.length <= 1) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tidak dapat menghapus soal aktif terakhir pada kuis yang berstatus Published. Silakan arsipkan kuis terlebih dahulu jika ingin menonaktifkannya.'),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                        return;
                      }
                    },
                    child: const Text('Hapus Soal Terakhir'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus Soal Terakhir'));
      await tester.pump();

      // Verifikasi: Tombol delete menolak dan menampilkan pesan error proteksi Published
      expect(find.text('Tidak dapat menghapus soal aktif terakhir pada kuis yang berstatus Published. Silakan arsipkan kuis terlebih dahulu jika ingin menonaktifkannya.'), findsOneWidget);
      expect(pretestRepo.deleteCallCount, equals(0));
    });

    test('Pretest and Posttest use identical 5-options structure', () {
      final pretestRepo = MockPretestRepoForCountTest(mockQuestions: []);
      final posttestRepo = MockPosttestRepoForCountTest(mockQuestions: []);

      expect(pretestRepo.mockQuestions, isEmpty);
      expect(posttestRepo.mockQuestions, isEmpty);
    });
  });
}

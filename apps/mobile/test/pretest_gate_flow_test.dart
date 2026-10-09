import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/models/pretest.dart';
import 'package:mobile/models/question.dart';
import 'package:mobile/models/test_attempt.dart';
import 'package:mobile/presentation/common/error_view.dart';
import 'package:mobile/presentation/pretest/pretest_screen.dart';
import 'package:mobile/repositories/attempt_repository.dart';
import 'package:mobile/repositories/material_repository.dart';
import 'package:mobile/repositories/pretest_repository.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:provider/provider.dart';

import 'session_pipeline_test.dart';

class MockPretestRepoForGate extends PretestRepository {
  final Pretest mockPretest;
  final List<Question> mockQuestions;

  MockPretestRepoForGate({
    required this.mockPretest,
    this.mockQuestions = const [],
  });

  @override
  Future<Pretest?> getPretest(String pretestId) async => mockPretest;

  @override
  Future<List<Question>> getQuestions(String pretestId) async => mockQuestions;
}

class MockAttemptRepoForGate extends AttemptRepository {
  @override
  Future<TestAttempt?> getInProgressAttempt({
    required String userId,
    required String testId,
  }) async => null;

  @override
  Future<int> getAttemptCount({
    required String userId,
    required String testId,
  }) async => 0;

  @override
  Future<TestAttempt> startAttempt({
    required String userId,
    required String testId,
    required String classId,
    required int attemptNo,
    required List<String> questionOrder,
    String kind = 'pretest',
  }) async {
    return TestAttempt(
      id: 'att_01',
      userId: userId,
      testId: testId,
      classId: classId,
      attemptNo: attemptNo,
      answers: const {},
      questionOrder: questionOrder,
      score: null,
      status: AttemptStatus.inProgress,
      startedAt: DateTime.now(),
      kind: kind,
    );
  }
}

class MockMaterialRepoForGate extends MaterialRepository {
  final bool Function() hasOpenedCallback;

  MockMaterialRepoForGate({required this.hasOpenedCallback});

  @override
  Future<bool> hasOpenedMateri({
    required String classId,
    required String meetingId,
    required String uid,
  }) async {
    return hasOpenedCallback();
  }
}

void main() {
  group('Pretest Gate & Error Prioritization Tests', () {
    late Pretest testPretest;
    late AuthProvider authProvider;

    setUp(() {
      testPretest = const Pretest(
        id: 'test_pre_01',
        classId: 'class_01',
        meetingId: 'meet_01',
        title: 'Pretest Algoritma',
        duration: 15,
        maxAttempts: 2,
      );

      final fakeUser = FakeUser(uid: 'student_01', email: 'budi@farlean.edu');
      final mockAuthService = MockAuthService(
        mockCurrentUser: fakeUser,
        mockProfileToReturn: AppUser(
          uid: 'student_01',
          name: 'Budi Mahasiswa',
          email: 'budi@farlean.edu',
          accountType: AccountType.mahasiswa,
          role: UserRole.user,
        ),
      );
      authProvider = AuthProvider(authService: mockAuthService);
    });

    Widget createTestWidget({
      required MaterialRepository materialRepo,
      required PretestRepository pretestRepo,
    }) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: PretestScreen(
            pretestId: 'test_pre_01',
            classId: 'class_01',
            meetingId: 'meet_01',
            pretestRepository: pretestRepo,
            materialRepository: materialRepo,
            attemptRepository: MockAttemptRepoForGate(),
          ),
        ),
      );
    }

    testWidgets('1. Menampilkan Gate Screen dengan pesan edukatif jika materi belum dibuka', (tester) async {
      final materialRepo = MockMaterialRepoForGate(hasOpenedCallback: () => false);
      final pretestRepo = MockPretestRepoForGate(mockPretest: testPretest);

      await tester.pumpWidget(createTestWidget(
        materialRepo: materialRepo,
        pretestRepo: pretestRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Materi Belum Dibuka'), findsOneWidget);
      expect(
        find.textContaining('Jika sebelumnya Anda sudah pernah membuka materi, ketuk tombol di bawah'),
        findsOneWidget,
      );
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Buka Materi Pembelajaran'), findsOneWidget);
      expect(find.byType(ErrorView), findsNothing);
    });

    testWidgets('2. Mendahulukan ErrorView (bukan Gate) saat terjadi error jaringan/Firestore', (tester) async {
      final materialRepo = MockMaterialRepoForGate(
        hasOpenedCallback: () => throw Exception('Koneksi timeout / Network failed'),
      );
      final pretestRepo = MockPretestRepoForGate(mockPretest: testPretest);

      await tester.pumpWidget(createTestWidget(
        materialRepo: materialRepo,
        pretestRepo: pretestRepo,
      ));
      await tester.pumpAndSettle();

      // Harus menampilkan ErrorView dengan tombol Coba Lagi, BUKAN Gate screen
      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.textContaining('Koneksi timeout / Network failed'), findsOneWidget);
      expect(find.text('Materi Belum Dibuka'), findsNothing);
    });

    testWidgets('3. Langsung membuka soal jika materi sudah tercatat dibuka di server', (tester) async {
      final materialRepo = MockMaterialRepoForGate(hasOpenedCallback: () => true);
      final pretestRepo = MockPretestRepoForGate(
        mockPretest: testPretest,
        mockQuestions: const [
          Question(
            id: 'q1',
            text: 'Apa kompleksitas Quicksort best case?',
            options: ['O(n)', 'O(n log n)', 'O(n^2)', 'O(1)', 'O(log n)'],
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget(
        materialRepo: materialRepo,
        pretestRepo: pretestRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Materi Belum Dibuka'), findsNothing);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('Apa kompleksitas Quicksort best case?'), findsOneWidget);
      expect(find.text('O(n log n)'), findsOneWidget);
    });
  });
}

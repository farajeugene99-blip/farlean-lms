import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/models/content_status.dart';
import 'package:mobile/models/posttest.dart';
import 'package:mobile/models/pretest.dart';
import 'package:mobile/models/question.dart';
import 'package:mobile/models/test_attempt.dart';
import 'package:mobile/presentation/posttest/posttest_screen.dart';
import 'package:mobile/presentation/pretest/pretest_screen.dart';
import 'package:mobile/repositories/attempt_repository.dart';
import 'package:mobile/repositories/material_repository.dart';
import 'package:mobile/repositories/posttest_repository.dart';
import 'package:mobile/repositories/pretest_repository.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:provider/provider.dart';

import 'session_pipeline_test.dart';

class MockPretestRepo extends PretestRepository {
  final Pretest pretest;
  final List<Question> questions;

  MockPretestRepo({required this.pretest, required this.questions});

  @override
  Future<Pretest?> getPretest(String pretestId) async => pretest;

  @override
  Future<List<Question>> getQuestions(String pretestId) async => questions;
}

class MockPosttestRepo extends PosttestRepository {
  final Posttest posttest;
  final List<Question> questions;

  MockPosttestRepo({required this.posttest, required this.questions});

  @override
  Future<Posttest?> getPosttest(String posttestId) async => posttest;

  @override
  Future<List<Question>> getQuestions(String posttestId) async => questions;
}

class MockAttemptRepo extends AttemptRepository {
  final TestAttempt attempt;

  MockAttemptRepo({required this.attempt});

  @override
  Future<TestAttempt?> getInProgressAttempt({
    required String userId,
    required String testId,
  }) async => attempt;

  @override
  Future<int> getAttemptCount({
    required String userId,
    required String testId,
  }) async => 0;

  @override
  Future<void> autosaveAnswers({
    required String attemptId,
    required Map<String, dynamic> answers,
  }) async {}
}

class MockMaterialRepo extends MaterialRepository {
  final bool opened;

  MockMaterialRepo({required this.opened});

  @override
  Future<bool> hasOpenedMateri({
    required String classId,
    required String meetingId,
    required String uid,
  }) async => opened;
}

void main() {
  group('Quiz Gap Closure Localization Tests (Pretest & Posttest)', () {
    late AuthProvider authProvider;
    late Pretest samplePretest;
    late Posttest samplePosttest;
    late List<Question> sampleQuestions;
    late TestAttempt sampleAttempt;

    setUp(() {
      final fakeUser = FakeUser(uid: 'user_01', email: 'test@farlean.edu');
      final mockAuth = MockAuthService(
        mockCurrentUser: fakeUser,
        mockProfileToReturn: AppUser(
          uid: 'user_01',
          name: 'Budi Test',
          email: 'test@farlean.edu',
          accountType: AccountType.mahasiswa,
          role: UserRole.user,
        ),
      );
      authProvider = AuthProvider(authService: mockAuth);

      samplePretest = const Pretest(
        id: 'pre_01',
        classId: 'cls_01',
        meetingId: 'meet_01',
        title: 'Pretest Fisika Dasar',
        duration: 15,
        maxAttempts: 2,
        status: ContentStatus.published,
      );

      samplePosttest = Posttest(
        id: 'post_01',
        classId: 'cls_01',
        meetingId: 'meet_01',
        title: 'Posttest Fisika Dasar',
        duration: 20,
        maxAttempts: 3,
        status: ContentStatus.published,
      );

      sampleQuestions = const [
        Question(
          id: 'q1',
          text: 'Berapakah kecepatan cahaya?',
          options: ['3x10^8 m/s', '1.5x10^8 m/s', '300 m/s', '9.8 m/s2', '0 m/s'],
          points: 10,
        ),
      ];

      sampleAttempt = TestAttempt(
        id: 'att_01',
        userId: 'user_01',
        testId: 'pre_01',
        classId: 'cls_01',
        attemptNo: 1,
        answers: const {},
        questionOrder: const ['q1'],
        status: AttemptStatus.inProgress,
        startedAt: DateTime.now(),
      );
    });

    testWidgets('1. Pretest Gate Screen renders Indonesian UI chrome', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: PretestScreen(
              pretestId: 'pre_01',
              classId: 'cls_01',
              meetingId: 'meet_01',
              pretestRepository: MockPretestRepo(pretest: samplePretest, questions: sampleQuestions),
              materialRepository: MockMaterialRepo(opened: false),
              attemptRepository: MockAttemptRepo(attempt: sampleAttempt),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Materi Belum Dibuka'), findsOneWidget);
      expect(find.text('Buka Materi Pembelajaran'), findsOneWidget);
      expect(find.text('Akses Pretest Terkunci'), findsOneWidget);
    });

    testWidgets('2. Pretest Gate Screen renders English UI chrome', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: PretestScreen(
              pretestId: 'pre_01',
              classId: 'cls_01',
              meetingId: 'meet_01',
              pretestRepository: MockPretestRepo(pretest: samplePretest, questions: sampleQuestions),
              materialRepository: MockMaterialRepo(opened: false),
              attemptRepository: MockAttemptRepo(attempt: sampleAttempt),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Learning Material Not Opened'), findsOneWidget);
      expect(find.text('Open Learning Material'), findsOneWidget);
      expect(find.text('Pretest Access Locked'), findsOneWidget);
    });

    testWidgets('3. Posttest Screen renders Indonesian UI chrome', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: PosttestScreen(
              posttestId: 'post_01',
              classId: 'cls_01',
              meetingId: 'meet_01',
              posttestRepository: MockPosttestRepo(posttest: samplePosttest, questions: sampleQuestions),
              attemptRepository: MockAttemptRepo(attempt: sampleAttempt),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Posttest Fisika Dasar'), findsOneWidget);
      expect(find.text('Soal 1 dari 1'), findsOneWidget);
      expect(find.text('10 Poin'), findsOneWidget);
      expect(find.text('Kumpulkan'), findsOneWidget);
    });

    testWidgets('4. Posttest Screen renders English UI chrome', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: PosttestScreen(
              posttestId: 'post_01',
              classId: 'cls_01',
              meetingId: 'meet_01',
              posttestRepository: MockPosttestRepo(posttest: samplePosttest, questions: sampleQuestions),
              attemptRepository: MockAttemptRepo(attempt: sampleAttempt),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Posttest Fisika Dasar'), findsOneWidget);
      expect(find.text('Question 1 of 1'), findsOneWidget);
      expect(find.text('10 Points'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);
    });

    test('5. ARB Semantic distinction: Pretest autosave vs Posttest autosubmit', () {
      final idL10n = lookupAppLocalizations(const Locale('id'));
      final enL10n = lookupAppLocalizations(const Locale('en'));

      expect(idL10n.quizTimeUpAutosaved, contains('disimpan'));
      expect(idL10n.quizTimeUpAutosubmitted, contains('dikumpulkan'));

      expect(enL10n.quizTimeUpAutosaved, contains('saved'));
      expect(enL10n.quizTimeUpAutosubmitted, contains('submitted'));
    });
  });
}

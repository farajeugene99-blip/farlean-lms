import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/models/assignment.dart';
import 'package:mobile/models/assignment_submission.dart';
import 'package:mobile/models/class_member.dart';
import 'package:mobile/models/classroom.dart';
import 'package:mobile/presentation/assignment/assignment_detail_screen.dart';
import 'package:mobile/presentation/class/class_detail_screen.dart';
import 'package:mobile/repositories/assignment_repository.dart';
import 'package:mobile/repositories/class_repository.dart';
import 'package:mobile/repositories/meeting_repository.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:provider/provider.dart';

import 'session_pipeline_test.dart';

class MockAssignmentRepo extends AssignmentRepository {
  List<Assignment> assignments;
  Map<String, AssignmentSubmission> submissions;

  MockAssignmentRepo({required this.assignments, required this.submissions});

  @override
  Future<List<Assignment>> getAssignmentsByClass(String classId) async => assignments;

  @override
  Future<Assignment?> getAssignment(String classId, String assignmentId) async {
    return assignments.cast<Assignment?>().firstWhere((a) => a?.id == assignmentId, orElse: () => null);
  }

  @override
  Future<AssignmentSubmission?> getSubmission({
    required String classId,
    required String assignmentId,
    required String submissionId,
  }) async {
    return submissions['${assignmentId}_$submissionId'];
  }

  @override
  Future<List<AssignmentSubmission>> getAllSubmissions({
    required String classId,
    required String assignmentId,
  }) async {
    return submissions.values.where((s) => s.assignmentId == assignmentId).toList();
  }

  @override
  Future<void> submitAssignment(AssignmentSubmission submission) async {
    submissions['${submission.assignmentId}_${submission.id}'] = submission;
  }

  @override
  Future<void> gradeSubmission({
    required String classId,
    required String assignmentId,
    required String submissionId,
    required double score,
    String? feedback,
    required String graderUid,
  }) async {
    final key = '${assignmentId}_$submissionId';
    final current = submissions[key];
    if (current != null) {
      submissions[key] = AssignmentSubmission(
        id: current.id,
        assignmentId: current.assignmentId,
        classId: current.classId,
        isGroup: current.isGroup,
        studentUid: current.studentUid,
        studentName: current.studentName,
        groupId: current.groupId,
        groupName: current.groupName,
        contributorIds: current.contributorIds,
        submittedByUid: current.submittedByUid,
        submittedByName: current.submittedByName,
        fileUrl: current.fileUrl,
        fileName: current.fileName,
        fileSize: current.fileSize,
        note: current.note,
        status: SubmissionStatus.graded,
        score: score,
        feedback: feedback,
        gradedByUid: graderUid,
        gradedAt: DateTime.now(),
        submittedAt: current.submittedAt,
      );
    }
  }
}

class MockClassRepoForAssignment extends ClassRepository {
  final Classroom mockClass;
  final List<ClassMember> mockMembers;

  MockClassRepoForAssignment({required this.mockClass, required this.mockMembers});

  @override
  Future<Classroom?> getClass(String classId) async => mockClass;

  @override
  Future<List<ClassMember>> getClassMembers(String classId) async => mockMembers;

  @override
  Future<Map<String, double>> getClassPretestScores(String classId) async => {};

  @override
  Future<Map<String, double>> getClassPosttestScores(String classId) async => {};

  @override
  Future<Map<String, double>> getStudentScores({required String classId, required String uid}) async => {};
}

AuthProvider _authForUser({
  required String uid,
  required String name,
  required String email,
  required AccountType type,
  required UserRole role,
}) {
  final fakeUser = FakeUser(uid: uid, email: email);
  final mockAuth = MockAuthService(
    mockCurrentUser: fakeUser,
    mockProfileToReturn: AppUser(
      uid: uid,
      name: name,
      email: email,
      accountType: type,
      role: role,
    ),
  );
  return AuthProvider(authService: mockAuth);
}

void main() {
  group('Assignment & AssignmentSubmission Model Tests (Fitur D)', () {
    test('Assignment serialization & deadline check', () {
      final deadline = DateTime(2026, 12, 31, 23, 59);
      final assignment = Assignment(
        id: 'assign_1',
        classId: 'c1',
        title: 'Tugas Perancangan Arsitektur',
        instructions: 'Kumpulkan file PDF laporan sistem.',
        deadline: deadline,
        allowLateSubmission: true,
        isGroupAssignment: false,
      );

      final map = assignment.toMap();
      expect(map['title'], equals('Tugas Perancangan Arsitektur'));
      expect(map['allow_late_submission'], isTrue);
      expect(map['is_group_assignment'], isFalse);

      final fromMap = Assignment.fromMap(map, id: 'assign_1', classId: 'c1');
      expect(fromMap.id, equals('assign_1'));
      expect(fromMap.title, equals('Tugas Perancangan Arsitektur'));
      expect(fromMap.allowLateSubmission, isTrue);
    });

    test('AssignmentSubmission serialization & graded check', () {
      final sub = AssignmentSubmission(
        id: 'student_01',
        assignmentId: 'assign_1',
        classId: 'c1',
        isGroup: false,
        studentUid: 'student_01',
        studentName: 'Budi Santoso',
        submittedByUid: 'student_01',
        submittedByName: 'Budi Santoso',
        fileUrl: 'https://res.cloudinary.com/farlean/tugas1.pdf',
        fileName: 'tugas1.pdf',
        fileSize: 2048,
        status: SubmissionStatus.graded,
        score: 95.0,
        feedback: 'Sangat baik dan komprehensif.',
      );

      expect(sub.isGraded, isTrue);
      final map = sub.toMap();
      expect(map['score'], equals(95.0));
      expect(map['status'], equals('GRADED'));

      final fromMap = AssignmentSubmission.fromMap(map, id: 'student_01', assignmentId: 'assign_1', classId: 'c1');
      expect(fromMap.score, equals(95.0));
      expect(fromMap.status, equals(SubmissionStatus.graded));
    });

    test('AssignmentRepository parameter validation', () {
      final repo = AssignmentRepository();
      expect(
        () => repo.createAssignment(
          Assignment(id: '', classId: '', title: '', deadline: DateTime.now()),
        ),
        throwsArgumentError,
      );
      expect(
        () => repo.gradeSubmission(
          classId: 'c1',
          assignmentId: 'a1',
          submissionId: 's1',
          score: 105.0, // di luar 0-100
          graderUid: 't1',
        ),
        throwsArgumentError,
      );
    });
  });

  group('AssignmentDetailScreen UI Tests (Fitur D)', () {
    late Classroom testClass;
    late List<ClassMember> testMembers;
    late Assignment individualAssignment;
    late Assignment groupAssignment;

    setUp(() {
      testClass = Classroom(
        id: 'c1',
        name: 'Pemrograman Flutter',
        code: 'FLUT123',
        teacherId: 'teacher_01',
        status: 'Active',
      );
      testMembers = [
        const ClassMember(
          uid: 'student_01',
          displayName: 'Budi Santoso',
          accountType: AccountType.mahasiswa,
          status: MemberStatus.active,
          groupId: 'g1',
        ),
        const ClassMember(
          uid: 'student_nogroup',
          displayName: 'Siti Solo',
          accountType: AccountType.mahasiswa,
          status: MemberStatus.active,
        ),
      ];
      individualAssignment = Assignment(
        id: 'assign_indiv',
        classId: 'c1',
        title: 'Tugas Mandiri 1',
        instructions: 'Kerjakan soal mandiri.',
        deadline: DateTime.now().add(const Duration(days: 3)),
        isGroupAssignment: false,
      );
      groupAssignment = Assignment(
        id: 'assign_group',
        classId: 'c1',
        title: 'Tugas Kelompok Proyek',
        instructions: 'Kerjakan bersama kelompok.',
        deadline: DateTime.now().add(const Duration(days: 5)),
        isGroupAssignment: true,
      );
    });

    testWidgets('1. Mahasiswa tanpa kelompok pada tugas kelompok melihat pesan peringatan informatif', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = _authForUser(
        uid: 'student_nogroup',
        name: 'Siti Solo',
        email: 'siti@farlean.edu',
        type: AccountType.mahasiswa,
        role: UserRole.user,
      );

      final repo = MockAssignmentRepo(assignments: [groupAssignment], submissions: {});
      final classRepo = MockClassRepoForAssignment(mockClass: testClass, mockMembers: testMembers);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: AssignmentDetailScreen(
              assignmentId: groupAssignment.id,
              classId: 'c1',
              initialAssignment: groupAssignment,
              assignmentRepository: repo,
              classRepository: classRepo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Peringatan mahasiswa belum punya kelompok
      expect(find.textContaining('Anda belum tergabung dalam kelompok mana pun'), findsOneWidget);
      // Tombol kumpulkan tugas disembunyikan/tidak dapat diakses
      expect(find.text('Kumpulkan Tugas'), findsNothing);
    });

    testWidgets('2. Dosen dapat melihat submission mahasiswa dan memberi nilai', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = _authForUser(
        uid: 'teacher_01',
        name: 'Dosen Pembimbing',
        email: 'dosen@farlean.edu',
        type: AccountType.dosen,
        role: UserRole.guru,
      );

      final initialSub = AssignmentSubmission(
        id: 'student_01',
        assignmentId: individualAssignment.id,
        classId: 'c1',
        isGroup: false,
        studentUid: 'student_01',
        studentName: 'Budi Santoso',
        submittedByUid: 'student_01',
        submittedByName: 'Budi Santoso',
        fileUrl: 'https://res.cloudinary.com/farlean/tugas_budi.pdf',
        fileName: 'tugas_budi.pdf',
        fileSize: 1048576,
        status: SubmissionStatus.submitted,
      );

      final repo = MockAssignmentRepo(
        assignments: [individualAssignment],
        submissions: {'${individualAssignment.id}_student_01': initialSub},
      );
      final classRepo = MockClassRepoForAssignment(mockClass: testClass, mockMembers: testMembers);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: AssignmentDetailScreen(
              assignmentId: individualAssignment.id,
              classId: 'c1',
              initialAssignment: individualAssignment,
              assignmentRepository: repo,
              classRepository: classRepo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Beri Nilai'), findsOneWidget);

      // Tap tombol Beri Nilai
      await tester.tap(find.text('Beri Nilai'));
      await tester.pumpAndSettle();

      expect(find.text('Penilaian Tugas'), findsOneWidget);

      // Isi nilai 90
      await tester.enterText(find.byType(TextFormField).first, '90');
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // Terverifikasi bahwa submission telah dinilai
      expect(repo.submissions['${individualAssignment.id}_student_01']?.score, equals(90.0));
      expect(repo.submissions['${individualAssignment.id}_student_01']?.status, equals(SubmissionStatus.graded));
    });
  });

  group('ClassDetailScreen Sub-tab Tugas Tests (Fitur D & UI)', () {
    testWidgets('1. Tab pertama memiliki SegmentedButton [Pertemuan | Tugas] dan dapat berpindah', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = _authForUser(
        uid: 'teacher_01',
        name: 'Dosen Pembimbing',
        email: 'dosen@farlean.edu',
        type: AccountType.dosen,
        role: UserRole.guru,
      );

      final testAssignment = Assignment(
        id: 'assign_1',
        classId: 'c1',
        title: 'Tugas Analisis Data',
        instructions: 'Petunjuk tugas...',
        deadline: DateTime.now().add(const Duration(days: 4)),
      );

      final classRepo = MockClassRepoForAssignment(
        mockClass: Classroom(id: 'c1', name: 'Flutter Class', code: 'FLUT1', teacherId: 'teacher_01', status: 'Active'),
        mockMembers: [],
      );
      final assignmentRepo = MockAssignmentRepo(assignments: [testAssignment], submissions: {});

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: ClassDetailScreen(
              classId: 'c1',
              classRepository: classRepo,
              meetingRepository: MeetingRepository(),
              assignmentRepository: assignmentRepo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Sub-tab SegmentedButton tersedia di Tab pertama
      expect(find.textContaining('Pertemuan'), findsWidgets);
      expect(find.textContaining('1 tugas'), findsOneWidget);

      // Tap sub-tab Tugas
      await tester.tap(find.textContaining('1 tugas'));
      await tester.pumpAndSettle();

      // Kartu tugas tampil
      expect(find.text('Tugas Analisis Data'), findsOneWidget);
      // Tombol Buat Tugas untuk Dosen
      expect(find.text('Buat Tugas'), findsWidgets);
    });
  });
}

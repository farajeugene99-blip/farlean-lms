import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/models/assignment.dart';
import 'package:mobile/models/assignment_submission.dart';
import 'package:mobile/models/class_member.dart';
import 'package:mobile/models/classroom.dart';
import 'package:mobile/presentation/class/class_detail_screen.dart';
import 'package:mobile/repositories/assignment_repository.dart';
import 'package:mobile/repositories/class_repository.dart';
import 'package:mobile/repositories/group_repository.dart';
import 'package:mobile/repositories/meeting_repository.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:provider/provider.dart';

import 'session_pipeline_test.dart';

class _MockClassRepoForGradebook extends ClassRepository {
  final Classroom mockClass;
  final List<ClassMember> mockMembers;

  _MockClassRepoForGradebook({required this.mockClass, required this.mockMembers});

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

class _MockAssignmentRepoForGradebook extends AssignmentRepository {
  final List<Assignment> assignments;
  final List<AssignmentSubmission> submissions;

  _MockAssignmentRepoForGradebook({required this.assignments, required this.submissions});

  @override
  Future<List<Assignment>> getAssignmentsByClass(String classId) async => assignments;

  @override
  Future<List<AssignmentSubmission>> getAllSubmissions({required String classId, required String assignmentId}) async {
    return submissions.where((s) => s.assignmentId == assignmentId).toList();
  }
}

AuthProvider _createTeacherAuth(String uid) {
  final fakeUser = FakeUser(uid: uid, email: '$uid@farlean.edu');
  final mockAuth = MockAuthService(
    mockCurrentUser: fakeUser,
    mockProfileToReturn: AppUser(
      uid: uid,
      name: 'Dosen Pembimbing',
      email: '$uid@farlean.edu',
      accountType: AccountType.dosen,
      role: UserRole.guru,
    ),
  );
  return AuthProvider(authService: mockAuth);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Gradebook Comprehensive & Dosen Exclusion Tests (Masalah C)', () {
    late Classroom testClass;
    late List<ClassMember> testMembers;
    late List<Assignment> testAssignments;
    late List<AssignmentSubmission> testSubmissions;

    setUp(() {
      testClass = const Classroom(
        id: 'c_grade',
        name: 'Kelas Rekap Nilai',
        teacherId: 'teacher_1',
        status: 'Active',
      );

      testMembers = [
        // Dosen Pengajar (HARUS DI-EXCLUDE dari baris rekap dan hitungan siswa)
        const ClassMember(
          uid: 'teacher_1',
          displayName: 'Dosen Pengampu Utama',
          accountType: AccountType.dosen,
          status: MemberStatus.active,
        ),
        // Mahasiswa 1: Mengerjakan tepat waktu & dinilai
        const ClassMember(
          uid: 'student_1',
          displayName: 'Budi Santoso',
          accountType: AccountType.mahasiswa,
          status: MemberStatus.active,
          groupId: 'grp_1',
        ),
        // Mahasiswa 2: Mengerjakan terlambat & dinilai
        const ClassMember(
          uid: 'student_2',
          displayName: 'Siti Rahma',
          accountType: AccountType.mahasiswa,
          status: MemberStatus.active,
        ),
        // Mahasiswa 3: Belum mengumpulkan
        const ClassMember(
          uid: 'student_3',
          displayName: 'Agus Pratama',
          accountType: AccountType.mahasiswa,
          status: MemberStatus.active,
        ),
      ];

      final deadline = DateTime(2026, 10, 15, 23, 59);

      testAssignments = [
        Assignment(
          id: 'assign_indiv_1',
          classId: 'c_grade',
          title: 'Tugas 1 Arsitektur',
          instructions: 'Kumpulkan PDF',
          deadline: deadline,
          isGroupAssignment: false,
        ),
      ];

      testSubmissions = [
        // Budi: On-time graded
        AssignmentSubmission(
          id: 'student_1',
          assignmentId: 'assign_indiv_1',
          classId: 'c_grade',
          isGroup: false,
          studentUid: 'student_1',
          submittedByUid: 'student_1',
          submittedByName: 'Budi Santoso',
          fileUrl: 'https://res.cloudinary.com/farlean/budi.pdf',
          fileName: 'budi.pdf',
          fileSize: 1024,
          status: SubmissionStatus.graded,
          score: 95.0,
          submittedAt: DateTime(2026, 10, 14, 10, 0), // Sebelum deadline
        ),
        // Siti: Late graded
        AssignmentSubmission(
          id: 'student_2',
          assignmentId: 'assign_indiv_1',
          classId: 'c_grade',
          isGroup: false,
          studentUid: 'student_2',
          submittedByUid: 'student_2',
          submittedByName: 'Siti Rahma',
          fileUrl: 'https://res.cloudinary.com/farlean/siti.pdf',
          fileName: 'siti.pdf',
          fileSize: 1024,
          status: SubmissionStatus.graded,
          score: 80.0,
          submittedAt: DateTime(2026, 10, 16, 10, 0), // Melewati deadline
        ),
      ];
    });

    testWidgets('1. Rekap Nilai Dosen mengecualikan akun Dosen dan menampilkan status tugas lengkap', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = _createTeacherAuth('teacher_1');
      final classRepo = _MockClassRepoForGradebook(mockClass: testClass, mockMembers: testMembers);
      final assignRepo = _MockAssignmentRepoForGradebook(assignments: testAssignments, submissions: testSubmissions);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: ClassDetailScreen(
              classId: 'c_grade',
              classRepository: classRepo,
              meetingRepository: MeetingRepository(),
              groupRepository: GroupRepository(),
              assignmentRepository: assignRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Buka Tab Rekap Nilai
      await tester.tap(find.text('Rekap Nilai'));
      await tester.pumpAndSettle();

      // Verifikasi: Dosen Pengampu Utama TIDAK muncul di baris siswa
      expect(find.text('Dosen Pengampu Utama'), findsNothing);
      // Total Mahasiswa murni 3 orang (bukan 4)
      expect(find.text('3'), findsOneWidget);

      // Tiga mahasiswa aktif tampil
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Siti Rahma'), findsOneWidget);
      expect(find.text('Agus Pratama'), findsOneWidget);

      // Pilih filter Tugas 1 dari dropdown
      await tester.tap(find.text('Semua Pertemuan (Ringkasan)'));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Tugas 1 Arsitektur').last);
      await tester.pumpAndSettle();

      // Budi: DINILAI: 95
      expect(find.text('DINILAI: 95'), findsOneWidget);
      // Siti: DINILAI (TERLAMBAT): 80
      expect(find.text('DINILAI (TERLAMBAT): 80'), findsOneWidget);
      // Agus: Belum Mengerjakan (-)
      expect(find.text('Belum Mengerjakan (-)'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });
}

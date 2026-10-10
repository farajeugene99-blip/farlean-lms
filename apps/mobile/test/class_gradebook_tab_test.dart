import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/models/class_member.dart';
import 'package:mobile/models/classroom.dart';
import 'package:mobile/models/content_status.dart';
import 'package:mobile/models/meeting.dart';
import 'package:mobile/presentation/class/class_detail_screen.dart';
import 'package:mobile/repositories/class_repository.dart';
import 'package:mobile/repositories/meeting_repository.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:provider/provider.dart';

import 'session_pipeline_test.dart';

class MockClassRepoForGradebook extends ClassRepository {
  final Classroom mockClass;
  final List<ClassMember> mockMembers;
  final Map<String, double> mockPreScores;
  final Map<String, double> mockPostScores;
  final Map<String, double> mockPersonalScores;

  MockClassRepoForGradebook({
    required this.mockClass,
    this.mockMembers = const [],
    this.mockPreScores = const {},
    this.mockPostScores = const {},
    this.mockPersonalScores = const {},
  });

  @override
  Future<Classroom?> getClass(String classId) async => mockClass;

  @override
  Future<List<ClassMember>> getClassMembers(String classId) async => mockMembers;

  @override
  Future<Map<String, double>> getClassPretestScores(String classId) async => mockPreScores;

  @override
  Future<Map<String, double>> getClassPosttestScores(String classId) async => mockPostScores;

  @override
  Future<Map<String, double>> getStudentScores({
    required String classId,
    required String uid,
  }) async => mockPersonalScores;
}

class MockMeetingRepoForGradebook extends MeetingRepository {
  final List<Meeting> mockMeetings;

  MockMeetingRepoForGradebook({this.mockMeetings = const []});

  @override
  Future<List<Meeting>> getMeetingsByClass(String classId, {bool isStaff = false}) async {
    return mockMeetings;
  }
}

void main() {
  group('ClassDetailScreen Gradebook Tab Tests', () {
    late Classroom testClass;
    late List<Meeting> testMeetings;
    late List<ClassMember> testMembers;

    setUp(() {
      testClass = Classroom(
        id: 'c1',
        name: 'Pemrograman Flutter',
        code: 'FLUT123',
        teacherId: 'teacher_01',
        status: 'Active',
      );

      testMeetings = [
        Meeting(
          id: 'm1',
          classId: 'c1',
          number: 1,
          title: 'Pengenalan Widget',
          pretestId: 'pre_01',
          posttestId: 'post_01',
          status: ContentStatus.published,
        ),
      ];

      testMembers = [
        const ClassMember(
          uid: 'student_01',
          displayName: 'Budi Santoso',
          accountType: AccountType.mahasiswa,
          status: MemberStatus.active,
        ),
        const ClassMember(
          uid: 'student_02',
          displayName: 'Siti Rahma',
          accountType: AccountType.mahasiswa,
          status: MemberStatus.active,
        ),
      ];
    });

    testWidgets('1. Tab Bar meletakkan Rekap Nilai di tengah antara Pertemuan dan Anggota Kelas', (tester) async {
      final fakeUser = FakeUser(uid: 'teacher_01', email: 'dosen@dosen.farlean.edu');
      final mockAuth = MockAuthService(
        mockCurrentUser: fakeUser,
        mockProfileToReturn: AppUser(
          uid: 'teacher_01',
          name: 'Dosen Pengampu',
          email: 'dosen@dosen.farlean.edu',
          accountType: AccountType.dosen,
          role: UserRole.guru,
        ),
      );
      final authProvider = AuthProvider(authService: mockAuth);

      final classRepo = MockClassRepoForGradebook(
        mockClass: testClass,
        mockMembers: testMembers,
        mockPreScores: {'pre_01_student_01': 85.0},
        mockPostScores: {'post_01_student_01': 90.0},
      );
      final meetingRepo = MockMeetingRepoForGradebook(mockMeetings: testMeetings);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: ClassDetailScreen(
              classId: 'c1',
              classRepository: classRepo,
              meetingRepository: meetingRepo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verifikasi urutan ketiga tab persis: Pertemuan, Rekap Nilai, Anggota Kelas
      final tabFinder = find.byType(Tab);
      expect(tabFinder, findsNWidgets(3));
      expect(find.descendant(of: tabFinder.at(0), matching: find.text('Pertemuan')), findsOneWidget);
      expect(find.descendant(of: tabFinder.at(1), matching: find.text('Rekap Nilai')), findsOneWidget);
      expect(find.descendant(of: tabFinder.at(2), matching: find.text('Anggota Kelas')), findsOneWidget);
    });

    testWidgets('2. Dosen dapat melihat rekap nilai dengan KPI summary dan skor mahasiswa', (tester) async {
      final fakeUser = FakeUser(uid: 'teacher_01', email: 'dosen@dosen.farlean.edu');
      final mockAuth = MockAuthService(
        mockCurrentUser: fakeUser,
        mockProfileToReturn: AppUser(
          uid: 'teacher_01',
          name: 'Dosen Pengampu',
          email: 'dosen@dosen.farlean.edu',
          accountType: AccountType.dosen,
          role: UserRole.guru,
        ),
      );
      final authProvider = AuthProvider(authService: mockAuth);

      final classRepo = MockClassRepoForGradebook(
        mockClass: testClass,
        mockMembers: testMembers,
        mockPreScores: {'pre_01_student_01': 85.0},
        mockPostScores: {'post_01_student_01': 90.0},
      );
      final meetingRepo = MockMeetingRepoForGradebook(mockMeetings: testMeetings);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: ClassDetailScreen(
              classId: 'c1',
              classRepository: classRepo,
              meetingRepository: meetingRepo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Pindah ke tab Rekap Nilai (tab index 1)
      await tester.tap(find.text('Rekap Nilai'));
      await tester.pumpAndSettle();

      // Verifikasi komponen rekap guru
      expect(find.text('Semua Pertemuan (Ringkasan)'), findsOneWidget);
      expect(find.textContaining('Menampilkan 1-2 dari 2 mahasiswa'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      await tester.drag(find.byType(ListView).last, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('Siti Rahma'), findsOneWidget);
    });

    testWidgets('3. Mahasiswa melihat rekap capaian belajar pribadi miliknya sendiri', (tester) async {
      final fakeUser = FakeUser(uid: 'student_01', email: 'budi@farlean.edu');
      final mockAuth = MockAuthService(
        mockCurrentUser: fakeUser,
        mockProfileToReturn: AppUser(
          uid: 'student_01',
          name: 'Budi Santoso',
          email: 'budi@farlean.edu',
          accountType: AccountType.mahasiswa,
          role: UserRole.user,
        ),
      );
      final authProvider = AuthProvider(authService: mockAuth);

      final classRepo = MockClassRepoForGradebook(
        mockClass: testClass,
        mockMembers: testMembers,
        mockPersonalScores: {
          'pre_pre_01': 85.0,
          'post_post_01': 95.0,
        },
      );
      final meetingRepo = MockMeetingRepoForGradebook(mockMeetings: testMeetings);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: ClassDetailScreen(
              classId: 'c1',
              classRepository: classRepo,
              meetingRepository: meetingRepo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Pindah ke tab Rekap Nilai
      await tester.tap(find.text('Rekap Nilai'));
      await tester.pumpAndSettle();

      // Verifikasi kartu capaian belajar mahasiswa
      expect(find.text('Hasil Capaian Belajar Anda'), findsOneWidget);
      expect(find.text('Pertemuan 1: Pengenalan Widget'), findsOneWidget);
      expect(find.text('Pretest: 85.0'), findsOneWidget);
      expect(find.text('Post Test: 95.0'), findsOneWidget);
    });

    testWidgets('4. GURU non-owner melihat banner akses terbatas pada tab Rekap Nilai', (tester) async {
      final fakeUser = FakeUser(uid: 'other_guru_99', email: 'other@dosen.farlean.edu');
      final mockAuth = MockAuthService(
        mockCurrentUser: fakeUser,
        mockProfileToReturn: AppUser(
          uid: 'other_guru_99',
          name: 'Dosen Luar',
          email: 'other@dosen.farlean.edu',
          accountType: AccountType.dosen,
          role: UserRole.guru,
        ),
      );
      final authProvider = AuthProvider(authService: mockAuth);

      final classRepo = MockClassRepoForGradebook(
        mockClass: testClass, // teacher_id is teacher_01, not other_guru_99
        mockMembers: testMembers,
      );
      final meetingRepo = MockMeetingRepoForGradebook(mockMeetings: testMeetings);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: ClassDetailScreen(
              classId: 'c1',
              classRepository: classRepo,
              meetingRepository: meetingRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rekap Nilai'));
      await tester.pumpAndSettle();

      expect(find.text('Akses Rekap Nilai Terbatas'), findsOneWidget);
      expect(find.textContaining('hanya Pengajar Pemilik Kelas dan Admin'), findsOneWidget);
    });
  });
}

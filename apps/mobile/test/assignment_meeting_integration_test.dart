import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/models/assignment.dart';
import 'package:mobile/models/content_status.dart';
import 'package:mobile/models/meeting.dart';
import 'package:mobile/presentation/meeting/meeting_detail_screen.dart';
import 'package:mobile/repositories/assignment_repository.dart';
import 'package:mobile/repositories/meeting_repository.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:mobile/services/cache_management_service.dart';
import 'package:provider/provider.dart';

import 'session_pipeline_test.dart';

class MockMeetingRepoForIntegration extends MeetingRepository {
  Meeting? meetingToReturn;

  MockMeetingRepoForIntegration({this.meetingToReturn});

  @override
  Future<Meeting?> getMeeting(String meetingId) async => meetingToReturn;
}

class MockAssignmentRepoForIntegration extends AssignmentRepository {
  Assignment? assignmentToReturn;
  String? lastMeetingIdQueried;

  MockAssignmentRepoForIntegration({this.assignmentToReturn});

  @override
  Future<Assignment?> getAssignment(String classId, String assignmentId) async => assignmentToReturn;

  @override
  Future<Assignment?> getAssignmentByMeeting(String classId, String meetingId) async {
    lastMeetingIdQueried = meetingId;
    return assignmentToReturn;
  }
}

AuthProvider _createStaffAuth() {
  final fakeUser = FakeUser(
    uid: 'guru_1',
    email: 'dosen@farlean.edu',
    mockClaims: const {'role': 'GURU'},
  );
  final mockAuth = MockAuthService(
    mockCurrentUser: fakeUser,
    mockProfileToReturn: const AppUser(
      uid: 'guru_1',
      name: 'Dosen Farlean',
      email: 'dosen@farlean.edu',
      accountType: AccountType.dosen,
      role: UserRole.guru,
      claimsRole: UserRole.guru,
    ),
  );
  return AuthProvider(authService: mockAuth);
}

AuthProvider _createStudentAuth() {
  final fakeUser = FakeUser(
    uid: 'mhs_1',
    email: 'mhs@farlean.edu',
    mockClaims: const {'role': 'USER'},
  );
  final mockAuth = MockAuthService(
    mockCurrentUser: fakeUser,
    mockProfileToReturn: const AppUser(
      uid: 'mhs_1',
      name: 'Mahasiswa Farlean',
      email: 'mhs@farlean.edu',
      accountType: AccountType.mahasiswa,
      role: UserRole.user,
      claimsRole: UserRole.user,
    ),
  );
  return AuthProvider(authService: mockAuth);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 3 Models & CacheManagementService Unit Tests', () {
    test('1. Meeting model serialization with assignmentId preserves backwards compatibility', () {
      final meetingWithAssign = Meeting(
        id: 'm1',
        classId: 'c1',
        number: 1,
        title: 'Pertemuan 1',
        assignmentId: 'assign_101',
      );

      final map = meetingWithAssign.toMap();
      expect(map['assignment_id'], equals('assign_101'));

      final reconstructed = Meeting.fromMap(map, id: 'm1');
      expect(reconstructed.assignmentId, equals('assign_101'));

      final cleared = reconstructed.copyWith(clearAssignmentId: true);
      expect(cleared.assignmentId, isNull);
    });

    test('2. Assignment model supports attachment fields and meeting link', () {
      final assignment = Assignment(
        id: 'a1',
        classId: 'c1',
        meetingId: 'm1',
        title: 'Tugas 1',
        deadline: DateTime.now().add(const Duration(days: 3)),
        attachmentUrl: 'https://res.cloudinary.com/farlean/petunjuk.pdf',
        attachmentFileName: 'petunjuk.pdf',
        attachmentFileSize: 2048576,
      );

      final map = assignment.toMap();
      expect(map['meeting_id'], equals('m1'));
      expect(map['attachment_url'], equals('https://res.cloudinary.com/farlean/petunjuk.pdf'));
      expect(map['attachment_file_name'], equals('petunjuk.pdf'));
      expect(map['attachment_file_size'], equals(2048576));

      final reconstructed = Assignment.fromMap(map, id: 'a1', classId: 'c1');
      expect(reconstructed.meetingId, equals('m1'));
      expect(reconstructed.attachmentUrl, equals('https://res.cloudinary.com/farlean/petunjuk.pdf'));
      expect(reconstructed.attachmentFileName, equals('petunjuk.pdf'));
      expect(reconstructed.attachmentFileSize, equals(2048576));
    });

    test('3. CacheManagementService correctly identifies safe temp files and protects engine dirs', () {
      // Safe extensions
      expect(CacheManagementService.isSafeTempFile('/tmp/file.pdf'), isTrue);
      expect(CacheManagementService.isSafeTempFile('/tmp/document.docx'), isTrue);
      expect(CacheManagementService.isSafeTempFile('/tmp/archive.zip'), isTrue);
      expect(CacheManagementService.isSafeTempFile('/tmp/image.png'), isTrue);
      expect(CacheManagementService.isSafeTempFile('/tmp/cache_item.tmp'), isTrue);

      // Protected engine & shader dirs must NEVER be marked safe
      expect(CacheManagementService.isSafeTempFile('/data/flutter/app.tmp'), isFalse);
      expect(CacheManagementService.isSafeTempFile('/cache/shader_cache/data.cache'), isFalse);
      expect(CacheManagementService.isSafeTempFile('/cache/skia_cache/blob.png'), isFalse);
      expect(CacheManagementService.isSafeTempFile('/cache/code_cache/bundle.tmp'), isFalse);
      expect(CacheManagementService.isSafeTempFile('/tmp/random.exe'), isFalse);
    });
  });

  group('Phase 3B MeetingDetailScreen 5th Module Widget Tests', () {
    Widget createTestWidget({
      required AuthProvider authProvider,
      required Meeting meeting,
      required AssignmentRepository assignmentRepo,
    }) {
      final meetingRepo = MockMeetingRepoForIntegration(meetingToReturn: meeting);
      return MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: MeetingDetailScreen(
            meetingId: meeting.id,
            initialMeeting: meeting,
            meetingRepository: meetingRepo,
            assignmentRepository: assignmentRepo,
          ),
        ),
      );
    }

    testWidgets('4. MeetingDetailScreen renders 5th module card "Tugas Pembelajaran" when assignment is linked', (tester) async {
      final meeting = Meeting(
        id: 'meeting_1',
        classId: 'class_1',
        number: 1,
        title: 'Pengantar Farlean LMS',
        status: ContentStatus.published,
        assignmentId: 'assign_1',
      );

      final assignment = Assignment(
        id: 'assign_1',
        classId: 'class_1',
        meetingId: 'meeting_1',
        title: 'Tugas Analisis Proses Bisnis',
        instructions: 'Analisis 5 waste pada lini perakitan.',
        deadline: DateTime.now().add(const Duration(days: 5)),
        isGroupAssignment: false,
      );

      final assignmentRepo = MockAssignmentRepoForIntegration(assignmentToReturn: assignment);

      await tester.pumpWidget(createTestWidget(
        authProvider: _createStaffAuth(),
        meeting: meeting,
        assignmentRepo: assignmentRepo,
      ));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Buka Tugas'), 300);
      await tester.pumpAndSettle();

      // Memastikan kartu modul ke-5 tampil
      expect(find.text('Tugas Pembelajaran'), findsOneWidget);
      expect(find.text('Buka Tugas'), findsOneWidget);
      expect(find.byIcon(Icons.task_alt_rounded), findsOneWidget);
      expect(find.textContaining('Individu'), findsOneWidget);
    });

    testWidgets('5. Graceful Fallback: Dokumen tugas null/terhapus menampilkan status kosong tanpa crash', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final meeting = Meeting(
        id: 'meeting_2',
        classId: 'class_1',
        number: 2,
        title: 'Kaizen & Gemba',
        status: ContentStatus.published,
        assignmentId: 'deleted_assignment_id', // assignment sudah terhapus di backend
      );

      final assignmentRepo = MockAssignmentRepoForIntegration(assignmentToReturn: null);

      await tester.pumpWidget(createTestWidget(
        authProvider: _createStaffAuth(),
        meeting: meeting,
        assignmentRepo: assignmentRepo,
      ));
      await tester.pumpAndSettle();

      // UI harus menangani null secara graceful
      expect(find.text('Tugas Pembelajaran'), findsOneWidget);
      // Untuk pengajar: tombol Buat Tugas tampil
      expect(find.text('Buat Tugas'), findsOneWidget);
      expect(find.textContaining('Tugas belum ditautkan'), findsOneWidget);
    });

    testWidgets('6. Mahasiswa melihat pesan edukatif saat tugas belum tersedia pada pertemuan', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final meeting = Meeting(
        id: 'meeting_3',
        classId: 'class_1',
        number: 3,
        title: '5S Framework',
        status: ContentStatus.published,
      );

      final assignmentRepo = MockAssignmentRepoForIntegration(assignmentToReturn: null);

      await tester.pumpWidget(createTestWidget(
        authProvider: _createStudentAuth(),
        meeting: meeting,
        assignmentRepo: assignmentRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Tugas Pembelajaran'), findsOneWidget);
      expect(find.text('Belum ada tugas pembelajaran untuk pertemuan ini'), findsOneWidget);
    });
  });
}

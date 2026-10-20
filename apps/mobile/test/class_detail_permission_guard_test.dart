import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
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

class _MockClassRepoForPermissionGuard extends ClassRepository {
  final Classroom? classroomToReturn;
  final ClassMember? membershipToReturn;
  final bool throwPermissionDeniedOnClass;

  _MockClassRepoForPermissionGuard({
    this.classroomToReturn,
    this.membershipToReturn,
    this.throwPermissionDeniedOnClass = false,
  });

  @override
  Future<Classroom?> getClass(String classId) async {
    if (throwPermissionDeniedOnClass) {
      throw FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied', message: 'The caller does not have permission');
    }
    return classroomToReturn;
  }

  @override
  Future<ClassMember?> getMyMembership(String classId, String uid) async => membershipToReturn;

  @override
  Future<List<ClassMember>> getClassMembers(String classId) async => [];

  @override
  Future<Map<String, double>> getClassPretestScores(String classId) async => {};

  @override
  Future<Map<String, double>> getClassPosttestScores(String classId) async => {};

  @override
  Future<Map<String, double>> getStudentScores({required String classId, required String uid}) async => {};
}

class _MockMeetingRepoForPermissionGuard extends MeetingRepository {
  bool lastIsStaffParam = false;
  int callCount = 0;

  @override
  Future<List<Meeting>> getMeetingsByClass(String classId, {bool isStaff = false}) async {
    callCount++;
    lastIsStaffParam = isStaff;
    return [
      const Meeting(
        id: 'm1',
        classId: 'c1',
        number: 1,
        title: 'Pertemuan 1',
        status: ContentStatus.published,
      ),
    ];
  }
}

AuthProvider _createAuth({
  required String uid,
  required UserRole role,
  required AccountType type,
}) {
  final fakeUser = FakeUser(uid: uid, email: '$uid@farlean.edu');
  final mockAuth = MockAuthService(
    mockCurrentUser: fakeUser,
    mockProfileToReturn: AppUser(
      uid: uid,
      name: 'User $uid',
      email: '$uid@farlean.edu',
      accountType: type,
      role: role,
    ),
  );
  return AuthProvider(authService: mockAuth);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClassDetailScreen Permission Guard Tests (Masalah B)', () {
    testWidgets('1. Guru yang membuka kelas Guru lain TIDAK dianggap isStaff untuk query meetings (isClassTeacher = false)', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // User adalah GURU_B, tapi kelas dimiliki oleh GURU_A
      final auth = _createAuth(uid: 'guru_b', role: UserRole.guru, type: AccountType.dosen);
      final classroom = const Classroom(
        id: 'c1',
        name: 'Kelas Dosen A',
        teacherId: 'guru_a',
        status: 'Active',
      );

      final classRepo = _MockClassRepoForPermissionGuard(classroomToReturn: classroom);
      final meetingRepo = _MockMeetingRepoForPermissionGuard();

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
              meetingRepository: meetingRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kelas Dosen A'), findsWidgets);
      // isClassTeacher harus false karena guru_b != guru_a
      expect(meetingRepo.callCount, equals(1));
      expect(meetingRepo.lastIsStaffParam, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. Anggota berstatus pending menampilkan antarmuka ramah Pendaftaran Menunggu Persetujuan', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = _createAuth(uid: 'student_pending', role: UserRole.user, type: AccountType.umum);

      final classRepo = _MockClassRepoForPermissionGuard(
        throwPermissionDeniedOnClass: true,
        membershipToReturn: const ClassMember(
          uid: 'student_pending',
          displayName: 'Peserta Pending',
          accountType: AccountType.umum,
          status: MemberStatus.pending,
        ),
      );

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
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Menampilkan view pending yang ramah, BUKAN ErrorView permission-denied
      expect(find.text('Pendaftaran Menunggu Persetujuan'), findsOneWidget);
      expect(find.textContaining('menunggu konfirmasi dari Dosen Pengampu'), findsOneWidget);
      expect(find.text('Kembali ke Beranda'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/models/classroom.dart';
import 'package:mobile/presentation/class/class_detail_screen.dart';
import 'package:mobile/repositories/class_repository.dart';
import 'package:mobile/repositories/meeting_repository.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:mobile/services/class_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'session_pipeline_test.dart';

class _MockClassRepoForLifecycle extends ClassRepository {
  Classroom classroom;
  int reactivateCount = 0;
  int archiveCount = 0;

  _MockClassRepoForLifecycle({required this.classroom});

  @override
  Future<Classroom?> getClass(String classId) async => classroom;

  @override
  Future<Map<String, List<Classroom>>> getMyClasses() async {
    return {'owned': [classroom], 'joined': []};
  }

  @override
  Future<void> archiveClass(String classId) async {
    archiveCount++;
    classroom = classroom.copyWith(status: 'Archived');
  }

  @override
  Future<void> reactivateClass(String classId) async {
    reactivateCount++;
    classroom = classroom.copyWith(status: 'Active');
  }
}

AuthProvider _createTeacherAuth(String uid) {
  final fakeUser = FakeUser(uid: uid, email: '$uid@farlean.edu');
  final mockAuth = MockAuthService(
    mockCurrentUser: fakeUser,
    mockProfileToReturn: AppUser(
      uid: uid,
      name: 'Dosen Pengampu',
      email: '$uid@farlean.edu',
      accountType: AccountType.dosen,
      role: UserRole.guru,
    ),
  );
  return AuthProvider(authService: mockAuth);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Class Lifecycle & Reactivation Tests (Masalah A.2)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('1. Dosen dapat mengaktifkan kembali kelas yang berstatus Archived tanpa error', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = _createTeacherAuth('teacher_1');
      final archivedClass = const Classroom(
        id: 'c_archived',
        name: 'Kelas Pemrograman Web',
        teacherId: 'teacher_1',
        status: 'Archived', // Kelas dalam status diarsipkan
      );

      final repo = _MockClassRepoForLifecycle(classroom: archivedClass);
      final classProvider = ClassProvider(classRepository: repo);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<ClassProvider>.value(value: classProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            locale: const Locale('id'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ClassDetailScreen(
              classId: 'c_archived',
              classRepository: repo,
              meetingRepository: MeetingRepository(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tombol aktifkan kembali tersedia untuk Dosen pemilik kelas
      expect(find.byIcon(Icons.unarchive_outlined), findsOneWidget);

      // Ketuk tombol aktifkan kembali
      await tester.tap(find.byIcon(Icons.unarchive_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Aktifkan Kembali Kelas?'), findsOneWidget);

      // Konfirmasi aktifkan
      await tester.tap(find.widgetWithText(ElevatedButton, 'Aktifkan'));
      await tester.pumpAndSettle();

      // Verifikasi: repository reactivateClass dipanggil & status berhasil diaktifkan
      expect(repo.reactivateCount, equals(1));
      expect(find.text('Kelas berhasil diaktifkan kembali.'), findsOneWidget);
      expect(find.byIcon(Icons.archive_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

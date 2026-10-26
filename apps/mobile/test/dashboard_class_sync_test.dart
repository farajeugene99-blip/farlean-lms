import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/models/classroom.dart';
import 'package:mobile/presentation/main/dashboard_screen.dart';
import 'package:mobile/repositories/class_repository.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:mobile/services/class_provider.dart';
import 'package:provider/provider.dart';

import 'session_pipeline_test.dart';

class _FakeClassRepoForSyncTest extends ClassRepository {
  Map<String, List<Classroom>>? resultToReturn;
  Object? exceptionToThrow;
  int getMyClassesCallCount = 0;

  _FakeClassRepoForSyncTest({this.resultToReturn, this.exceptionToThrow});

  @override
  Future<Map<String, List<Classroom>>> getMyClasses() async {
    getMyClassesCallCount++;
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return resultToReturn ?? {'owned': [], 'joined': []};
  }
}

AuthProvider _createTestStudentAuth() {
  final fakeUser = FakeUser(uid: 'mhs_sync_test', email: 'mhs@farlean.edu');
  final mockAuth = MockAuthService(
    mockCurrentUser: fakeUser,
    mockProfileToReturn: const AppUser(
      uid: 'mhs_sync_test',
      name: 'Mahasiswa Sync Test',
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

  group('Classroom Model & Membership Status Tests', () {
    test('Classroom parses membership_status and exposes isMembershipPending / isMembershipActive', () {
      final activeClass = Classroom.fromMap({
        'name': 'Kelas Algoritma',
        'teacher_id': 'guru_1',
        'status': 'Active',
        'membership_status': 'active',
      }, id: 'c_act');

      expect(activeClass.membershipStatus, equals('active'));
      expect(activeClass.isMembershipActive, isTrue);
      expect(activeClass.isMembershipPending, isFalse);

      final pendingClass = Classroom.fromMap({
        'name': 'Kelas Jaringan',
        'teacher_id': 'guru_2',
        'status': 'Active',
        'membership_status': 'pending',
      }, id: 'c_pend');

      expect(pendingClass.membershipStatus, equals('pending'));
      expect(pendingClass.isMembershipActive, isFalse);
      expect(pendingClass.isMembershipPending, isTrue);

      final defaultClass = Classroom.fromMap({
        'name': 'Kelas Default',
        'teacher_id': 'guru_3',
        'status': 'Active',
      }, id: 'c_def');

      expect(defaultClass.membershipStatus, isNull);
      expect(defaultClass.isMembershipActive, isTrue);
      expect(defaultClass.isMembershipPending, isFalse);
    });
  });

  group('DashboardScreen Class Synchronization & Pending Guard Widget Tests', () {
    testWidgets('1. Mahasiswa yang bergabung ke kelas aktif melihat kartu kelas dan bukan kartu kosong', (tester) async {
      final auth = _createTestStudentAuth();
      final activeJoinedClass = const Classroom(
        id: 'c_joined_active',
        name: 'Pemrograman Mobile Terapan',
        code: 'MOBIL123',
        teacherId: 'guru_mobile',
        status: 'Active',
        membershipStatus: 'active',
      );

      final fakeRepo = _FakeClassRepoForSyncTest(
        resultToReturn: {
          'owned': [],
          'joined': [activeJoinedClass],
        },
      );
      final classProvider = ClassProvider(classRepository: fakeRepo);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: auth),
              ChangeNotifierProvider<ClassProvider>.value(value: classProvider),
            ],
            child: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan kartu kelas ter-render dengan nama dan kode
      expect(find.text('Pemrograman Mobile Terapan'), findsOneWidget);
      expect(find.text('MOBIL123'), findsOneWidget);
      expect(find.text('Buka Kelas'), findsOneWidget);

      // Kartu kosong "Belum tergabung ke kelas pembelajaran" TIDAK boleh muncul
      expect(find.text('Belum tergabung ke kelas pembelajaran.'), findsNothing);
    });

    testWidgets('2. Mahasiswa yang status keanggotaannya pending melihat badge Menunggu Persetujuan dan tombol dicegah navigasi', (tester) async {
      final auth = _createTestStudentAuth();
      final pendingJoinedClass = const Classroom(
        id: 'c_joined_pending',
        name: 'Kecerdasan Buatan Lanjut',
        code: 'AIADVANCED',
        teacherId: 'guru_ai',
        status: 'Active',
        membershipStatus: 'pending',
      );

      final fakeRepo = _FakeClassRepoForSyncTest(
        resultToReturn: {
          'owned': [],
          'joined': [pendingJoinedClass],
        },
      );
      final classProvider = ClassProvider(classRepository: fakeRepo);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: auth),
              ChangeNotifierProvider<ClassProvider>.value(value: classProvider),
            ],
            child: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kecerdasan Buatan Lanjut'), findsOneWidget);
      // Badge khusus pending muncul
      expect(find.text('Menunggu Persetujuan'), findsOneWidget);
      expect(find.text('Menunggu'), findsOneWidget);

      // Klik tombol Menunggu
      await tester.tap(find.widgetWithText(ElevatedButton, 'Menunggu'));
      await tester.pumpAndSettle();

      // SnackBar informasi muncul dan mencegah crash permission-denied
      expect(find.text('Permintaan bergabung masih menunggu persetujuan pengajar kelas.'), findsOneWidget);
    });

    testWidgets('3. Kegagalan memuat data kelas menampilkan pesan error eksplisit dan tombol Coba Lagi', (tester) async {
      final auth = _createTestStudentAuth();
      final fakeRepo = _FakeClassRepoForSyncTest(
        exceptionToThrow: StateError('Koneksi internet bermasalah'),
      );
      final classProvider = ClassProvider(classRepository: fakeRepo);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: auth),
              ChangeNotifierProvider<ClassProvider>.value(value: classProvider),
            ],
            child: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Layar error eksplisit tampil
      expect(find.text('Gagal Memuat Kelas'), findsOneWidget);
      expect(find.textContaining('Koneksi internet bermasalah'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);

      // Tentu saja TIDAK menyamarkan error sebagai belum bergabung
      expect(find.text('Belum tergabung ke kelas pembelajaran.'), findsNothing);
    });
  });
}

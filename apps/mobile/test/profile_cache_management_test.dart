import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/models/classroom.dart';
import 'package:mobile/presentation/main/main_shell.dart';
import 'package:mobile/presentation/main/profile_screen.dart';
import 'package:mobile/repositories/attempt_repository.dart';
import 'package:mobile/repositories/class_repository.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:mobile/services/class_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'session_pipeline_test.dart';

class MockAttemptRepoForCache extends AttemptRepository {
  final bool Function() hasActiveCallback;

  MockAttemptRepoForCache({required this.hasActiveCallback});

  @override
  Future<bool> hasActiveOngoingAttempt({
    required String userId,
    Duration maxAge = const Duration(hours: 3),
  }) async {
    return hasActiveCallback();
  }
}

class FakeClassRepoForCache extends ClassRepository {
  final Map<String, List<Classroom>> userClasses;

  FakeClassRepoForCache({required this.userClasses});

  @override
  Future<Map<String, List<Classroom>>> getMyClasses() async => userClasses;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Profile Cache Management Tests (G4)', () {
    late FakeUser fakeUser;
    late MockAuthService mockAuth;
    late AuthProvider authProvider;
    late ClassProvider classProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'farlean_selected_class_id': 'class_123'});
      fakeUser = FakeUser(uid: 'user_cache_01', email: 'user@farlean.edu');
      mockAuth = MockAuthService(
        mockCurrentUser: fakeUser,
        mockProfileToReturn: const AppUser(
          uid: 'user_cache_01',
          name: 'Siswa Farlean',
          email: 'user@farlean.edu',
          accountType: AccountType.mahasiswa,
          role: UserRole.user,
        ),
      );
      authProvider = AuthProvider(authService: mockAuth);

      final classRepo = FakeClassRepoForCache(
        userClasses: {
          'owned': [],
          'joined': [
            Classroom(id: 'class_123', name: 'Pemrograman Web', code: 'WEB456', teacherId: 't1', status: 'Active'),
          ],
        },
      );
      classProvider = ClassProvider(classRepository: classRepo);
      await classProvider.loadClasses();
      MainShell.activeClassId = 'class_123';
    });

    Widget createTestWidget({required AttemptRepository attemptRepo}) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<ClassProvider>.value(value: classProvider),
          ],
          child: ProfileScreen(
            userRepository: null,
            attemptRepository: attemptRepo,
          ),
        ),
      );
    }

    testWidgets('1. Menu Penyimpanan & Cache tampil dan membuka dialog dengan metrik jujur', (tester) async {
      final attemptRepo = MockAttemptRepoForCache(hasActiveCallback: () => false);

      await tester.pumpWidget(createTestWidget(attemptRepo: attemptRepo));
      await tester.pumpAndSettle();

      expect(find.text('Penyimpanan & Cache'), findsOneWidget);

      await tester.tap(find.text('Penyimpanan & Cache'));
      await tester.pumpAndSettle();

      expect(find.text('Cache Gambar di Memori (RAM)'), findsOneWidget);
      expect(find.textContaining('belum ada gambar dimuat di memori'), findsOneWidget);
      expect(find.text('Pilihan Kelas Aktif Tersimpan'), findsOneWidget);
      expect(find.textContaining('Pemrograman Web (WEB456)'), findsOneWidget);
      expect(find.text('Tutup'), findsOneWidget);
    });

    testWidgets('2. Jika kuis aktif sedang berlangsung, reset kelas aktif DIBLOKIR demi keamanan', (tester) async {
      final attemptRepo = MockAttemptRepoForCache(hasActiveCallback: () => true);

      await tester.pumpWidget(createTestWidget(attemptRepo: attemptRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Penyimpanan & Cache'));
      await tester.pumpAndSettle();

      // Scroll SingleChildScrollView agar tombol terlihat jelas
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -200));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset Pilihan Kelas Aktif'));
      await tester.pumpAndSettle();

      // Dialog pemblokiran muncul
      expect(find.text('Kuis Sedang Dikerjakan'), findsOneWidget);
      expect(find.textContaining('Tidak dapat mereset kelas aktif: Anda sedang memiliki kuis yang sedang dikerjakan'), findsOneWidget);
      expect(find.text('Mengerti'), findsOneWidget);

      // Kelas aktif tetap tidak berubah
      expect(classProvider.selectedClassId, equals('class_123'));
      expect(MainShell.activeClassId, equals('class_123'));
    });

    testWidgets('3. Jika verifikasi kuis gagal (offline), reset kelas aktif DIBLOKIR demi keamanan jawaban', (tester) async {
      final attemptRepo = MockAttemptRepoForCache(
        hasActiveCallback: () => throw Exception('Network unreachable'),
      );

      await tester.pumpWidget(createTestWidget(attemptRepo: attemptRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Penyimpanan & Cache'));
      await tester.pumpAndSettle();

      // Scroll SingleChildScrollView agar tombol terlihat jelas
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -200));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset Pilihan Kelas Aktif'));
      await tester.pumpAndSettle();

      // Dialog pemblokiran offline muncul
      expect(find.text('Perangkat Offline'), findsOneWidget);
      expect(find.textContaining('Untuk keamanan jawaban kuis Anda, reset kelas aktif ditunda'), findsOneWidget);
      expect(find.text('Mengerti'), findsOneWidget);

      // Kelas aktif tetap tidak berubah
      expect(classProvider.selectedClassId, equals('class_123'));
    });

    testWidgets('4. Jika tidak ada kuis aktif, reset kelas aktif berhasil menyinkronkan state dan SharedPreferences', (tester) async {
      final attemptRepo = MockAttemptRepoForCache(hasActiveCallback: () => false);

      await tester.pumpWidget(createTestWidget(attemptRepo: attemptRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Penyimpanan & Cache'));
      await tester.pumpAndSettle();

      // Scroll SingleChildScrollView agar tombol terlihat jelas
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -200));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset Pilihan Kelas Aktif'));
      await tester.pumpAndSettle();

      expect(find.text('Reset Pilihan Kelas?'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Reset'));
      await tester.pumpAndSettle();

      // State ClassProvider dan MainShell.activeClassId tersinkronisasi menjadi null
      expect(classProvider.selectedClassId, isNull);
      expect(MainShell.activeClassId, isNull);

      // SharedPreferences key terhapus
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('farlean_selected_class_id'), isNull);

      // Feedback SnackBar muncul
      expect(find.text('Pilihan kelas aktif berhasil direset.'), findsOneWidget);
    });
  });
}

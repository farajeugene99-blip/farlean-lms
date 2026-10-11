import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/models/classroom.dart';
import 'package:mobile/presentation/main/main_shell.dart';
import 'package:mobile/presentation/main/profile_screen.dart';
import 'package:mobile/repositories/attempt_repository.dart';
import 'package:mobile/repositories/class_repository.dart';
import 'package:mobile/repositories/user_repository.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:mobile/services/class_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'session_pipeline_test.dart';

class MockAttemptRepoForLogout extends AttemptRepository {
  final bool Function() hasActiveCallback;

  MockAttemptRepoForLogout({required this.hasActiveCallback});

  @override
  Future<bool> hasActiveOngoingAttempt({
    required String userId,
    Duration maxAge = const Duration(hours: 3),
  }) async {
    return hasActiveCallback();
  }
}

class FakeClassRepoForIsolation extends ClassRepository {
  final Map<String, List<Classroom>> userClasses;

  FakeClassRepoForIsolation({required this.userClasses});

  @override
  Future<Map<String, List<Classroom>>> getMyClasses() async => userClasses;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProfileScreen Logout & Multi-Account Isolation Tests (G1)', () {
    late FakeUser fakeUserA;
    late MockAuthService mockAuthA;
    late AuthProvider authProviderA;
    late ClassProvider classProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'farlean_selected_class_id': 'class_A'});
      fakeUserA = FakeUser(uid: 'user_A', email: 'userA@farlean.edu');
      mockAuthA = MockAuthService(
        mockCurrentUser: fakeUserA,
        mockProfileToReturn: AppUser(
          uid: 'user_A',
          name: 'Pengguna A',
          email: 'userA@farlean.edu',
          accountType: AccountType.mahasiswa,
          role: UserRole.user,
        ),
      );
      authProviderA = AuthProvider(authService: mockAuthA);

      final classRepoA = FakeClassRepoForIsolation(
        userClasses: {
          'owned': [],
          'joined': [
            Classroom(id: 'class_A', name: 'Kelas Pengguna A', code: 'CLA123', teacherId: 't1', status: 'Active'),
          ],
        },
      );
      classProvider = ClassProvider(classRepository: classRepoA);
      await classProvider.loadClasses();
      MainShell.activeClassId = 'class_A';
    });

    Widget createProfileWidget({
      required AttemptRepository attemptRepo,
      double textScale = 1.0,
      Size size = const Size(360, 640),
    }) {
      return MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          padding: const EdgeInsets.only(bottom: 24), // Gesture bar inset
        ),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: authProviderA),
              ChangeNotifierProvider<ClassProvider>.value(value: classProvider),
            ],
            child: ProfileScreen(
              userRepository: UserRepository(),
              attemptRepository: attemptRepo,
            ),
          ),
        ),
      );
    }

    testWidgets('1. Header logout icon dan tombol merah bawah keduanya tampil', (tester) async {
      final attemptRepo = MockAttemptRepoForLogout(hasActiveCallback: () => false);

      await tester.pumpWidget(createProfileWidget(attemptRepo: attemptRepo));
      await tester.pumpAndSettle();

      // Ikon di AppBar
      expect(find.byTooltip('Keluar'), findsOneWidget);
      // Scroll down untuk melihat tombol di bawah ListView
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('Keluar dari Akun'), findsOneWidget);
      expect(find.byIcon(Icons.logout_rounded), findsNWidgets(2));
    });

    testWidgets('2. Menekan tombol keluar memunculkan dialog konfirmasi', (tester) async {
      final attemptRepo = MockAttemptRepoForLogout(hasActiveCallback: () => false);

      await tester.pumpWidget(createProfileWidget(attemptRepo: attemptRepo));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keluar dari Akun'));
      await tester.pumpAndSettle();

      expect(find.text('Keluar dari Akun?'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);

      // Batal menutup dialog tanpa logout
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.text('Keluar dari Akun?'), findsNothing);
      expect(authProviderA.isAuthenticated, isTrue);
    });

    testWidgets('3. Muncul peringatan kuis aktif jika ada attempt in_progress yang belum selesai', (tester) async {
      final attemptRepo = MockAttemptRepoForLogout(hasActiveCallback: () => true);

      await tester.pumpWidget(createProfileWidget(attemptRepo: attemptRepo));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keluar dari Akun'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Anda memiliki kuis yang sedang dikerjakan'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('4. Muncul peringatan offline jika pemeriksaan kuis gagal karena jaringan, dan tetap boleh keluar', (tester) async {
      final attemptRepo = MockAttemptRepoForLogout(
        hasActiveCallback: () => throw Exception('Network unreachable / offline'),
      );

      await tester.pumpWidget(createProfileWidget(attemptRepo: attemptRepo));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keluar dari Akun'));
      await tester.pumpAndSettle();

      expect(find.textContaining('karena perangkat sedang offline'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);
    });

    testWidgets('5. Permission-denied TIDAK memicu peringatan offline palsu', (tester) async {
      final attemptRepo = MockAttemptRepoForLogout(
        hasActiveCallback: () => throw FirebaseException(plugin: 'firestore', code: 'permission-denied'),
      );

      await tester.pumpWidget(createProfileWidget(attemptRepo: attemptRepo));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keluar dari Akun'));
      await tester.pumpAndSettle();

      // Tidak boleh menampilkan peringatan offline palsu
      expect(find.textContaining('karena perangkat sedang offline'), findsNothing);
      expect(find.textContaining('Anda memiliki kuis yang sedang dikerjakan'), findsNothing);
      expect(find.text('Apakah Anda yakin ingin keluar dari sesi Farlean LMS di perangkat ini?'), findsOneWidget);
    });

    testWidgets('6. Konfirmasi keluar membersihkan ClassProvider, activeClassId, dan signOut', (tester) async {
      final attemptRepo = MockAttemptRepoForLogout(hasActiveCallback: () => false);

      expect(classProvider.selectedClassId, equals('class_A'));
      expect(MainShell.activeClassId, equals('class_A'));

      await tester.pumpWidget(createProfileWidget(attemptRepo: attemptRepo));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keluar dari Akun'));
      await tester.pumpAndSettle();

      // Tap 'Keluar' pada dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Keluar'));
      await tester.pumpAndSettle();

      // Verifikasi pembersihan total
      expect(classProvider.selectedClassId, isNull);
      expect(classProvider.joinedClasses, isEmpty);
      expect(MainShell.activeClassId, isNull);
      expect(authProviderA.isAuthenticated, isFalse);

      // Verifikasi SharedPreferences key terhapus
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('farlean_selected_class_id'), isNull);
    });

    testWidgets('7. Isolasi multi-akun: Akun B login tidak melihat kelas atau pilihan milik Akun A', (tester) async {
      final attemptRepo = MockAttemptRepoForLogout(hasActiveCallback: () => false);

      await tester.pumpWidget(createProfileWidget(attemptRepo: attemptRepo));
      await tester.pumpAndSettle();

      // Akun A logout via AppBar action
      await tester.tap(find.byTooltip('Keluar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Keluar'));
      await tester.pumpAndSettle();

      // Simulasi Akun B login pada perangkat yang sama
      final classRepoB = FakeClassRepoForIsolation(
        userClasses: {
          'owned': [],
          'joined': [
            Classroom(id: 'class_B', name: 'Kelas Pengguna B', code: 'CLB456', teacherId: 't2', status: 'Active'),
          ],
        },
      );
      final classProviderB = ClassProvider(classRepository: classRepoB);
      await classProviderB.loadClasses();

      // Verifikasi Akun B tidak mewarisi class_A milik Akun A
      expect(classProviderB.selectedClassId, equals('class_B'));
      expect(classProviderB.joinedClasses.map((c) => c.id), contains('class_B'));
      expect(classProviderB.joinedClasses.any((c) => c.id == 'class_A'), isFalse);
    });

    testWidgets('8. Uji layout responsif pada layar sempit (262px, 320px) dan textScale 1.5 tanpa overflow', (tester) async {
      final attemptRepo = MockAttemptRepoForLogout(hasActiveCallback: () => false);

      // Test 262px width (narrow constraint)
      await tester.pumpWidget(createProfileWidget(
        attemptRepo: attemptRepo,
        size: const Size(262, 500),
        textScale: 1.5,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(find.text('Keluar dari Akun'), findsOneWidget);

      // Test 320px landscape (320 height x 600 width)
      await tester.pumpWidget(createProfileWidget(
        attemptRepo: attemptRepo,
        size: const Size(600, 320),
        textScale: 1.0,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

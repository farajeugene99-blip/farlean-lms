import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/presentation/main/profile_screen.dart';
import 'package:mobile/repositories/attempt_repository.dart';
import 'package:mobile/repositories/user_repository.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:mobile/services/class_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'session_pipeline_test.dart';

class _FakeUserRepository extends UserRepository {
  String? currentNimNip = '12345678';
  String? currentName = 'Budi Mahasiswa';
  bool shouldThrow = false;
  String? lastUpdatedName;
  String? lastUpdatedNimNip;

  _FakeUserRepository();

  @override
  Future<String?> getPrivateIdentity(String uid) async => currentNimNip;

  @override
  Future<bool> setPrivateIdentity(String uid, String nimNip) async {
    if (shouldThrow) throw Exception('Simulated Firestore error');
    lastUpdatedNimNip = nimNip;
    currentNimNip = nimNip;
    return true;
  }

  @override
  Future<bool> updateName(String uid, String newName, {String? photoUrl}) async {
    if (shouldThrow) throw Exception('Simulated Firestore error');
    lastUpdatedName = newName;
    currentName = newName;
    return true;
  }
}

class _MockAttemptRepo extends AttemptRepository {
  @override
  Future<bool> hasActiveOngoingAttempt({required String userId, Duration maxAge = const Duration(hours: 3)}) async {
    return false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProfileScreen Edit Name & NIM Dialogs Tests', () {
    late FakeUser fakeUser;
    late MockAuthService mockAuth;
    late AuthProvider authProvider;
    late _FakeUserRepository fakeUserRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      fakeUser = FakeUser(uid: 'user_edit_01', email: '25050974183@mhs.unesa.ac.id', displayName: 'Budi Mahasiswa');
      mockAuth = MockAuthService(
        mockCurrentUser: fakeUser,
        mockProfileToReturn: const AppUser(
          uid: 'user_edit_01',
          name: 'Budi Mahasiswa',
          email: '25050974183@mhs.unesa.ac.id',
          accountType: AccountType.mahasiswa,
          role: UserRole.user,
        ),
      );
      authProvider = AuthProvider(authService: mockAuth);
      await authProvider.refreshSession();
      fakeUserRepo = _FakeUserRepository();
    });

    Widget createTestWidget() {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<ClassProvider>(create: (_) => ClassProvider()),
          ],
          child: ProfileScreen(
            userRepository: fakeUserRepo,
            attemptRepository: _MockAttemptRepo(),
          ),
        ),
      );
    }

    testWidgets('1. Dialog Ubah Nama membuka, memvalidasi input, dan memperbarui nama tanpa error', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Budi Mahasiswa'), findsOneWidget);

      // Tap icon edit pertama (di samping nama)
      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();

      expect(find.text('Ubah Nama Lengkap'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Simpan'), findsOneWidget);

      // Ubah teks nama
      final textField = find.byType(TextFormField);
      await tester.enterText(textField, 'Budi Santoso Baru');
      await tester.pump();

      // Tap Simpan
      await tester.tap(find.widgetWithText(ElevatedButton, 'Simpan'));
      await tester.pumpAndSettle();

      // Dialog tertutup, nama terupdate di repository
      expect(fakeUserRepo.lastUpdatedName, equals('Budi Santoso Baru'));
      expect(find.text('Nama profil berhasil diperbarui.'), findsOneWidget);
    });

    testWidgets('2. Dialog Ubah Nama menampilkan pesan error jika repository gagal', (tester) async {
      fakeUserRepo.shouldThrow = true;

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();

      final textField = find.byType(TextFormField);
      await tester.enterText(textField, 'Nama Gagal');
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Simpan'));
      await tester.pumpAndSettle();

      // Dialog tetap terbuka dan menampilkan error
      expect(find.textContaining('Gagal memperbarui nama:'), findsOneWidget);

      // Batalkan dialog
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.text('Ubah Nama Lengkap'), findsNothing);
    });

    testWidgets('3. Dialog Ubah NIM membuka, memvalidasi input, dan memperbarui state NIM tanpa error', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verifikasi identitas awal tampil
      expect(find.text('12345678'), findsOneWidget);

      // Tap icon edit kedua (pada baris NIM)
      await tester.tap(find.byIcon(Icons.edit_outlined).last);
      await tester.pumpAndSettle();

      expect(find.text('Nomor Induk (NIM)'), findsWidgets);
      expect(find.widgetWithText(ElevatedButton, 'Simpan'), findsOneWidget);

      // Ubah nomor NIM
      final textField = find.byType(TextFormField);
      await tester.enterText(textField, '25050974183');
      await tester.pump();

      // Tap Simpan
      await tester.tap(find.widgetWithText(ElevatedButton, 'Simpan'));
      await tester.pumpAndSettle();

      // Dialog tertutup, NIM terupdate di repository dan di layar profil
      expect(fakeUserRepo.lastUpdatedNimNip, equals('25050974183'));
      expect(find.text('25050974183'), findsOneWidget);
      expect(find.text('NIM berhasil disimpan di private identity.'), findsOneWidget);
    });

    testWidgets('4. Dialog Ubah NIM menampilkan pesan error jika repository gagal', (tester) async {
      fakeUserRepo.shouldThrow = true;

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined).last);
      await tester.pumpAndSettle();

      final textField = find.byType(TextFormField);
      await tester.enterText(textField, '99999999');
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Simpan'));
      await tester.pumpAndSettle();

      // Error message muncul di dalam dialog
      expect(find.textContaining('Gagal menyimpan NIM:'), findsOneWidget);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      // Dialog ditutup, hanya ListTile di ProfileScreen yang tersisa
      expect(find.widgetWithText(ElevatedButton, 'Simpan'), findsNothing);
    });

    testWidgets('5. AppBar ProfileScreen tidak memiliki tombol logout lagi', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // AppBar hanya menampilkan judul
      expect(find.text('Profil Pengguna'), findsOneWidget);
      expect(find.descendant(of: find.byType(AppBar), matching: find.byIcon(Icons.logout_rounded)), findsNothing);
    });
  });
}

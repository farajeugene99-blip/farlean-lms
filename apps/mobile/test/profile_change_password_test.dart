import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/presentation/main/profile_screen.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:mobile/services/class_provider.dart';
import 'package:provider/provider.dart';

import 'session_pipeline_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Profile Change Password Tests (G3)', () {
    late FakeUser fakeUser;
    late MockAuthService mockAuth;
    late AuthProvider authProvider;

    setUp(() {
      fakeUser = FakeUser(uid: 'user_pw_01', email: 'user@farlean.edu');
      mockAuth = MockAuthService(
        mockCurrentUser: fakeUser,
        mockProfileToReturn: const AppUser(
          uid: 'user_pw_01',
          name: 'Budi Test',
          email: 'user@farlean.edu',
          accountType: AccountType.mahasiswa,
          role: UserRole.user,
        ),
      );
      authProvider = AuthProvider(authService: mockAuth);
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
          child: const ProfileScreen(userRepository: null),
        ),
      );
    }

    testWidgets('1. Menu Keamanan & Kata Sandi disembunyikan jika akun bukan email/password', (tester) async {
      mockAuth.mockHasPasswordProvider = false;

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Keamanan & Kata Sandi'), findsNothing);
    });

    testWidgets('2. Menu Keamanan & Kata Sandi tampil untuk akun email/password dan membuka dialog', (tester) async {
      mockAuth.mockHasPasswordProvider = true;

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Keamanan & Kata Sandi'), findsOneWidget);

      await tester.tap(find.text('Keamanan & Kata Sandi'));
      await tester.pumpAndSettle();

      expect(find.text('Ubah Kata Sandi'), findsOneWidget);
      expect(find.text('Kata Sandi Saat Ini'), findsOneWidget);
      expect(find.text('Kata Sandi Baru (Min. 8 Karakter)'), findsOneWidget);
      expect(find.text('Konfirmasi Kata Sandi Baru'), findsOneWidget);
      expect(find.text('Lupa kata sandi saat ini?'), findsOneWidget);
    });

    testWidgets('3. Validasi aturan UI: sandi baru minimal 8 karakter dan konfirmasi harus cocok', (tester) async {
      mockAuth.mockHasPasswordProvider = true;

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keamanan & Kata Sandi'));
      await tester.pumpAndSettle();

      // Isi kata sandi saat ini (akun lama 6 char diterima)
      await tester.enterText(find.widgetWithText(TextFormField, 'Kata Sandi Saat Ini'), '123456');
      // Isi kata sandi baru terlalu pendek (< 8)
      await tester.enterText(find.widgetWithText(TextFormField, 'Kata Sandi Baru (Min. 8 Karakter)'), 'pendek');
      await tester.enterText(find.widgetWithText(TextFormField, 'Konfirmasi Kata Sandi Baru'), 'berbeda123');

      await tester.tap(find.text('Simpan Sandi'));
      await tester.pumpAndSettle();

      expect(find.text('Kata sandi baru minimal 8 karakter.'), findsOneWidget);
      expect(find.text('Konfirmasi kata sandi tidak cocok'), findsOneWidget);
      expect(mockAuth.changePasswordCallCount, equals(0));
    });

    testWidgets('4. Error wrong-password atau invalid-credential menampilkan pesan kesalahan yang ramah', (tester) async {
      mockAuth.mockHasPasswordProvider = true;
      mockAuth.mockChangePasswordException = FirebaseAuthException(
        code: 'invalid-credential',
        message: 'Invalid credential supplied',
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keamanan & Kata Sandi'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Kata Sandi Saat Ini'), 'salahsandi1');
      await tester.enterText(find.widgetWithText(TextFormField, 'Kata Sandi Baru (Min. 8 Karakter)'), 'sandibaru123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Konfirmasi Kata Sandi Baru'), 'sandibaru123');

      await tester.tap(find.text('Simpan Sandi'));
      await tester.pumpAndSettle();

      expect(mockAuth.changePasswordCallCount, equals(1));
      expect(find.text('Kata sandi saat ini yang Anda masukkan salah.'), findsOneWidget);
      // Dialog tidak tertutup saat terjadi error
      expect(find.text('Ubah Kata Sandi'), findsOneWidget);
    });

    testWidgets('5. Sukses mengubah kata sandi menutup modal dan menampilkan SnackBar sukses', (tester) async {
      mockAuth.mockHasPasswordProvider = true;
      mockAuth.mockChangePasswordException = null;

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keamanan & Kata Sandi'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Kata Sandi Saat Ini'), 'sandilama1');
      await tester.enterText(find.widgetWithText(TextFormField, 'Kata Sandi Baru (Min. 8 Karakter)'), 'sandibaru123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Konfirmasi Kata Sandi Baru'), 'sandibaru123');

      await tester.tap(find.text('Simpan Sandi'));
      await tester.pumpAndSettle();

      expect(mockAuth.changePasswordCallCount, equals(1));
      expect(mockAuth.lastCurrentPassword, equals('sandilama1'));
      expect(mockAuth.lastNewPassword, equals('sandibaru123'));
      // Modal tertutup
      expect(find.text('Ubah Kata Sandi'), findsNothing);
      expect(find.text('Kata sandi berhasil diperbarui untuk akun ini.'), findsOneWidget);
    });
  });
}

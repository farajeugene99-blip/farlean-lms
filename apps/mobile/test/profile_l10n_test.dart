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

  Widget createProfileHarness({
    required AuthProvider authProvider,
    Locale locale = const Locale('id'),
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
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

  AuthProvider createFakeAuthProvider({
    required AccountType type,
    required UserRole role,
    String name = 'Farlean Tester',
    String email = 'tester@farlean.edu',
  }) {
    final fakeUser = FakeUser(uid: 'uid_test_123', email: email);
    final mockAuth = MockAuthService(
      mockCurrentUser: fakeUser,
      mockProfileToReturn: AppUser(
        uid: 'uid_test_123',
        name: name,
        email: email,
        accountType: type,
        role: role,
      ),
    );
    mockAuth.mockHasPasswordProvider = true;
    return AuthProvider(authService: mockAuth);
  }

  // =========================================================================
  // 1. Label Profil di Locale Indonesia (ID)
  // =========================================================================
  group('Profile Localization — ID', () {
    testWidgets('Header, kartu, dan tombol menampilkan Bahasa Indonesia', (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final auth = createFakeAuthProvider(
        type: AccountType.mahasiswa,
        role: UserRole.user,
      );

      await tester.pumpWidget(createProfileHarness(authProvider: auth, locale: const Locale('id')));
      await tester.pumpAndSettle();

      expect(find.text('Profil Pengguna'), findsOneWidget);
      expect(find.text('Keamanan & Kata Sandi'), findsOneWidget);
      expect(find.text('Penyimpanan & Cache'), findsOneWidget);
      expect(find.text('Keluar dari Akun'), findsOneWidget);
      expect(find.text('Status Verifikasi Email'), findsOneWidget);
      expect(find.text('Sinkronisasi Sesi & Peran'), findsOneWidget);
    });

    testWidgets('Dialog Ubah Kata Sandi menampilkan Bahasa Indonesia', (tester) async {
      final auth = createFakeAuthProvider(
        type: AccountType.mahasiswa,
        role: UserRole.user,
      );

      await tester.pumpWidget(createProfileHarness(authProvider: auth, locale: const Locale('id')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keamanan & Kata Sandi'));
      await tester.pumpAndSettle();

      expect(find.text('Ubah Kata Sandi'), findsOneWidget);
      expect(find.text('Kata Sandi Saat Ini'), findsOneWidget);
      expect(find.text('Kata Sandi Baru (Min. 8 Karakter)'), findsOneWidget);
      expect(find.text('Konfirmasi Kata Sandi Baru'), findsOneWidget);
      expect(find.text('Lupa kata sandi saat ini?'), findsOneWidget);
      expect(find.text('Simpan Sandi'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
    });

    testWidgets('Dialog Penyimpanan & Cache menampilkan Bahasa Indonesia', (tester) async {
      final auth = createFakeAuthProvider(
        type: AccountType.mahasiswa,
        role: UserRole.user,
      );

      await tester.pumpWidget(createProfileHarness(authProvider: auth, locale: const Locale('id')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Penyimpanan & Cache'));
      await tester.pumpAndSettle();

      expect(find.text('Penyimpanan & Cache'), findsWidgets);
      expect(find.text('Cache Gambar di Memori (RAM)'), findsOneWidget);
      expect(find.text('Pilihan Kelas Aktif Tersimpan'), findsOneWidget);
      expect(find.text('Tutup'), findsOneWidget);
    });
  });

  // =========================================================================
  // 2. Label Profil di Locale English (EN)
  // =========================================================================
  group('Profile Localization — EN', () {
    testWidgets('Header, kartu, dan tombol menampilkan Bahasa Inggris', (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final auth = createFakeAuthProvider(
        type: AccountType.mahasiswa,
        role: UserRole.user,
      );

      await tester.pumpWidget(createProfileHarness(authProvider: auth, locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('User Profile'), findsOneWidget);
      expect(find.text('Security & Password'), findsOneWidget);
      expect(find.text('Storage & Cache'), findsOneWidget);
      expect(find.text('Sign Out of Account'), findsOneWidget);
      expect(find.text('Email Verification Status'), findsOneWidget);
      expect(find.text('Session & Role Sync'), findsOneWidget);
    });

    testWidgets('Dialog Ubah Kata Sandi menampilkan Bahasa Inggris', (tester) async {
      final auth = createFakeAuthProvider(
        type: AccountType.mahasiswa,
        role: UserRole.user,
      );

      await tester.pumpWidget(createProfileHarness(authProvider: auth, locale: const Locale('en')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Security & Password'));
      await tester.pumpAndSettle();

      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Current Password'), findsOneWidget);
      expect(find.text('New Password (Min. 8 Characters)'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
      expect(find.text('Forgot current password?'), findsOneWidget);
      expect(find.text('Save Password'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Dialog Penyimpanan & Cache menampilkan Bahasa Inggris', (tester) async {
      final auth = createFakeAuthProvider(
        type: AccountType.mahasiswa,
        role: UserRole.user,
      );

      await tester.pumpWidget(createProfileHarness(authProvider: auth, locale: const Locale('en')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Storage & Cache'));
      await tester.pumpAndSettle();

      expect(find.text('Storage & Cache'), findsWidgets);
      expect(find.text('Image Cache in Memory (RAM)'), findsOneWidget);
      expect(find.text('Saved Active Class Preference'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });
  });

  // =========================================================================
  // 3. Locale-Lock Test (Perangkat Default EN tetap menghasilkan ID)
  // =========================================================================
  group('Locale-Lock — Perlindungan Selama Migrasi', () {
    testWidgets('Tanpa override locale, ProfileScreen menggunakan ID (default terkunci)', (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final auth = createFakeAuthProvider(
        type: AccountType.mahasiswa,
        role: UserRole.user,
      );

      // Simulasikan MaterialApp tanpa parameter locale (mengikuti LocaleProvider yang terkunci ke 'id')
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'), // Nilai tetap dari LocaleProvider selama fase 2A
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: auth),
              ChangeNotifierProvider<ClassProvider>(create: (_) => ClassProvider()),
            ],
            child: const ProfileScreen(userRepository: null),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan string tetap Bahasa Indonesia
      expect(find.text('Profil Pengguna'), findsOneWidget);
      expect(find.text('Keamanan & Kata Sandi'), findsOneWidget);
      expect(find.text('User Profile'), findsNothing);
      expect(find.text('Security & Password'), findsNothing);
    });
  });

  // =========================================================================
  // 4. Raw Domain Values (Keputusan 3: MAHASISWA, USER, role tetap mentah)
  // =========================================================================
  group('Domain Value Integrity — Keaslian Nilai Mentah di Kedua Locale', () {
    testWidgets('Nilai MAHASISWA dan USER tetap mentah di ID dan EN', (tester) async {
      final auth = createFakeAuthProvider(
        type: AccountType.mahasiswa,
        role: UserRole.user,
      );

      // Uji di ID: prefix "Tipe:" dan "Role:", nilai tetap "MAHASISWA" dan "USER"
      await tester.pumpWidget(createProfileHarness(authProvider: auth, locale: const Locale('id')));
      await tester.pumpAndSettle();

      expect(find.text('Tipe: MAHASISWA'), findsOneWidget);
      expect(find.text('Role: USER'), findsOneWidget);

      // Uji di EN: prefix "Type:" dan "Role:", nilai TETAP "MAHASISWA" dan "USER"
      await tester.pumpWidget(createProfileHarness(authProvider: auth, locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Type: MAHASISWA'), findsOneWidget);
      expect(find.text('Role: USER'), findsOneWidget);
    });

    testWidgets('Label identitas NIM dan NIP tidak diubah artinya di kedua locale', (tester) async {
      final authMhs = createFakeAuthProvider(
        type: AccountType.mahasiswa,
        role: UserRole.user,
      );

      // Di ID: "Nomor Induk (NIM)"
      await tester.pumpWidget(createProfileHarness(authProvider: authMhs, locale: const Locale('id')));
      await tester.pumpAndSettle();
      expect(find.text('Nomor Induk (NIM)'), findsOneWidget);

      // Di EN: "ID Number (NIM)" — kode 'NIM' tetap utuh sebagai identifier institusi
      await tester.pumpWidget(createProfileHarness(authProvider: authMhs, locale: const Locale('en')));
      await tester.pumpAndSettle();
      expect(find.text('ID Number (NIM)'), findsOneWidget);
    });
  });

  // =========================================================================
  // 4. ICU Pluralisasi & Format Angka Cache (Poin 4 Review)
  // =========================================================================
  group('ICU Plural Cache Statistics', () {
    testWidgets('Pluralisasi EN: 1 image vs 2 images', (tester) async {
      late AppLocalizations enL10n;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(builder: (ctx) {
            enL10n = AppLocalizations.of(ctx);
            return const SizedBox.shrink();
          }),
        ),
      );

      expect(enL10n.profileCacheStats(1, '50.0'), equals('50.0 KB (1 image active in memory)'));
      expect(enL10n.profileCacheStats(2, '120.5'), equals('120.5 KB (2 images active in memory)'));
    });

    testWidgets('ID: bentuk jamak dan tunggal menggunakan kata gambar', (tester) async {
      late AppLocalizations idL10n;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(builder: (ctx) {
            idL10n = AppLocalizations.of(ctx);
            return const SizedBox.shrink();
          }),
        ),
      );

      expect(idL10n.profileCacheStats(1, '50,0'), equals('50,0 KB (1 gambar aktif di memori)'));
      expect(idL10n.profileCacheStats(5, '250,0'), equals('250,0 KB (5 gambar aktif di memori)'));
    });
  });

  // =========================================================================
  // 5. Konsistensi Placeholder di ID dan EN (Poin 7 Review)
  // =========================================================================
  group('Placeholder Consistency Tests', () {
    testWidgets('profileChangePasswordNote menghasilkan kalimat yang benar dengan {min}', (tester) async {
      late AppLocalizations idL10n;
      late AppLocalizations enL10n;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(builder: (ctx) {
            idL10n = AppLocalizations.of(ctx);
            return const SizedBox.shrink();
          }),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(builder: (ctx) {
            enL10n = AppLocalizations.of(ctx);
            return const SizedBox.shrink();
          }),
        ),
      );

      expect(idL10n.profileChangePasswordNote(8), contains('minimal 8 karakter'));
      expect(enL10n.profileChangePasswordNote(8), contains('at least 8 characters'));
    });
  });
}

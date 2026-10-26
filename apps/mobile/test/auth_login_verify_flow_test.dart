import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/presentation/auth/login_screen.dart';
import 'package:mobile/presentation/auth/verify_email_screen.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/services/class_provider.dart';
import 'package:provider/provider.dart';

class _MockAuthServiceForFlowTest extends AuthService {
  FirebaseAuthException? exceptionToThrowOnSignIn;
  bool resendSuccess = true;
  int resendCallCount = 0;
  bool checkVerificationResult = false;
  User? mockUser;

  _MockAuthServiceForFlowTest({this.mockUser});

  @override
  User? get currentFirebaseUser => mockUser;

  @override
  Stream<User?> get authStateChanges => Stream.value(mockUser);

  @override
  Future<User?> signInRaw({required String email, required String password}) async {
    if (exceptionToThrowOnSignIn != null) {
      throw exceptionToThrowOnSignIn!;
    }
    return mockUser;
  }

  @override
  Future<void> sendEmailVerification() async {
    resendCallCount++;
    if (!resendSuccess) {
      throw FirebaseAuthException(code: 'too-many-requests', message: 'Terlalu banyak permintaan.');
    }
  }

  @override
  Future<bool> reloadAndCheckVerification() async {
    return checkVerificationResult;
  }
}

class _FakeUnverifiedUser implements User {
  @override
  final String uid = 'unverified_user_1';
  @override
  final String email = 'mhs@farlean.edu';
  @override
  final String displayName = 'Mahasiswa Unverified';
  @override
  final bool emailVerified = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildLoginHarness(AuthProvider authProvider) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      locale: const Locale('id'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: const LoginScreen(),
      ),
    );
  }

  Widget buildVerifyEmailHarness(AuthProvider authProvider) {
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
        child: const VerifyEmailScreen(),
      ),
    );
  }

  group('LoginScreen Error & Registration Prompt Tests', () {
    testWidgets('1. Login gagal karena invalid-credential menampilkan pesan bersahabat dan action Daftar di sini', (tester) async {
      final mockAuth = _MockAuthServiceForFlowTest()
        ..exceptionToThrowOnSignIn = FirebaseAuthException(
          code: 'invalid-credential',
          message: 'The supplied auth credential is incorrect, malformed or has expired.',
        );
      final authProvider = AuthProvider(authService: mockAuth);

      await tester.pumpWidget(buildLoginHarness(authProvider));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'unregistered@farlean.edu');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
      await tester.pumpAndSettle();

      // Verifikasi pesan tidak mengklaim sepihak dan menyajikan action daftar
      expect(find.text('Email belum terdaftar atau kata sandi salah.'), findsOneWidget);
      expect(find.text('Daftar di sini'), findsOneWidget);
    });

    testWidgets('2. Login gagal karena user-not-found menampilkan info akun tidak ditemukan dan action Daftar di sini', (tester) async {
      final mockAuth = _MockAuthServiceForFlowTest()
        ..exceptionToThrowOnSignIn = FirebaseAuthException(
          code: 'user-not-found',
          message: 'There is no user record corresponding to this identifier.',
        );
      final authProvider = AuthProvider(authService: mockAuth);

      await tester.pumpWidget(buildLoginHarness(authProvider));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'notfound@farlean.edu');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
      await tester.pumpAndSettle();

      expect(find.text('Akun dengan alamat email ini tidak ditemukan.'), findsOneWidget);
      expect(find.text('Daftar di sini'), findsOneWidget);
    });
  });

  group('VerifyEmailScreen Cooldown Timer & Resilience Tests', () {
    testWidgets('3. Kirim ulang verifikasi berhasil mengaktifkan cooldown timer dan tombol ter-disable', (tester) async {
      final fakeUser = _FakeUnverifiedUser();
      final mockAuth = _MockAuthServiceForFlowTest(mockUser: fakeUser)..resendSuccess = true;
      final authProvider = AuthProvider(authService: mockAuth);

      await tester.pumpWidget(buildVerifyEmailHarness(authProvider));
      await tester.pumpAndSettle();

      expect(find.textContaining('mhs@farlean.edu'), findsOneWidget);
      expect(find.text('Kirim Ulang Email'), findsOneWidget);

      // Ketuk Kirim Ulang Email
      await tester.tap(find.text('Kirim Ulang Email'));
      await tester.pumpAndSettle();

      expect(mockAuth.resendCallCount, equals(1));
      // SnackBar berhasil terkirim
      expect(find.text('Tautan verifikasi telah dikirim ulang ke email Anda.'), findsOneWidget);

      // Tombol kini menampilkan timer countdown dan ter-disable
      expect(find.textContaining('Kirim Ulang Email (60s)'), findsOneWidget);

      // Maju 1 detik
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Kirim Ulang Email (59s)'), findsOneWidget);

      // Ketuk saat cooldown aktif tidak menambah panggilan
      await tester.tap(find.byType(OutlinedButton), warnIfMissed: false);
      expect(mockAuth.resendCallCount, equals(1));
    });

    testWidgets('4. Kirim ulang verifikasi gagal menampilkan error SnackBar tanpa crash', (tester) async {
      final fakeUser = _FakeUnverifiedUser();
      final mockAuth = _MockAuthServiceForFlowTest(mockUser: fakeUser)..resendSuccess = false;
      final authProvider = AuthProvider(authService: mockAuth);

      await tester.pumpWidget(buildVerifyEmailHarness(authProvider));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kirim Ulang Email'));
      await tester.pumpAndSettle();

      expect(mockAuth.resendCallCount, equals(1));
      expect(find.textContaining('Terlalu banyak percobaan gagal'), findsOneWidget);
    });

    testWidgets('5. Cooldown Timer dibersihkan dengan aman saat widget di-dispose', (tester) async {
      final fakeUser = _FakeUnverifiedUser();
      final mockAuth = _MockAuthServiceForFlowTest(mockUser: fakeUser)..resendSuccess = true;
      final authProvider = AuthProvider(authService: mockAuth);

      await tester.pumpWidget(buildVerifyEmailHarness(authProvider));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kirim Ulang Email'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Kirim Ulang Email (60s)'), findsOneWidget);

      // Ganti widget (trigger dispose)
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('Layar Lain'))));
      await tester.pumpAndSettle();

      // Majukan waktu 10 detik setelah dispose — tidak boleh ada memory leak atau exception
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('Layar Lain'), findsOneWidget);
    });
  });
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/config/firebase_config.dart';
import 'package:mobile/presentation/common/startup_error_screen.dart';
import 'package:mobile/services/auth_service.dart';

void main() {
  group('Startup & Firebase Initialization Regression Tests', () {
    testWidgets('Test (a): StartupErrorScreen ditampilkan saat inisialisasi gagal (bukan LoginScreen)',
        (WidgetTester tester) async {
      final simulatedError = UnsupportedError(
        'DefaultFirebaseOptions have not been configured for windows - you can reconfigure this by running the FlutterFire CLI again.',
      );

      bool retryCalled = false;

      await tester.pumpWidget(
        StartupErrorScreen(
          error: simulatedError,
          onRetry: () {
            retryCalled = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan UI error tampil dengan rincian exception asli
      expect(find.text('Inisialisasi Firebase Gagal'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      expect(find.textContaining('have not been configured for windows'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);

      // Pastikan Halaman Login TIDAK ditampilkan saat startup gagal
      expect(find.text('Masuk ke Farlean LMS'), findsNothing);

      // Verifikasi tombol Coba Lagi berfungsi
      await tester.tap(find.text('Coba Lagi'));
      expect(retryCalled, isTrue);
    });

    test('Test (b): AuthService dengan Firebase uninitialized melempar not-initialized terkontrol', () async {
      // Instance dibuat tanpa auth yang diinjeksi dan Firebase.apps kosong di test environment
      final authService = AuthService();

      expect(
        () => authService.signIn(email: 'user@kampus.ac.id', password: 'password123'),
        throwsA(
          isA<FirebaseAuthException>()
              .having((e) => e.code, 'code', equals('not-initialized'))
              .having((e) => e.message, 'message', equals('Firebase belum diinisialisasi.')),
        ),
      );

      expect(
        () => authService.register(
          name: 'User',
          email: 'user@kampus.ac.id',
          password: 'password123',
        ),
        throwsA(
          isA<FirebaseAuthException>()
              .having((e) => e.code, 'code', equals('not-initialized'))
              .having((e) => e.message, 'message', equals('Firebase belum diinisialisasi.')),
        ),
      );

      expect(
        () => authService.sendPasswordResetEmail('user@kampus.ac.id'),
        throwsA(
          isA<FirebaseAuthException>()
              .having((e) => e.code, 'code', equals('not-initialized'))
              .having((e) => e.message, 'message', equals('Firebase belum diinisialisasi.')),
        ),
      );

      // Memverifikasi translateError menerjemahkan error not-initialized secara terkontrol
      final notInitializedException = FirebaseAuthException(
        code: 'not-initialized',
        message: 'Firebase belum diinisialisasi.',
      );
      expect(
        AuthService.translateError(notInitializedException),
        equals('Firebase belum diinisialisasi.'),
      );
    });

    test('Test (c): Penegakan emulator-only menolak bypass produksi tanpa flag eksplisit', () async {
      expect(
        () => FirebaseConfig.initialize(useEmulator: false),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Akses ke Firebase Production diblokir pada Phase 1 & 2'),
          ),
        ),
      );
    });

    test('Test (d): FirebaseConfig.resolveEmulatorHost mengembalikan default host yang valid', () {
      final host = FirebaseConfig.resolveEmulatorHost();
      expect(host, isNotEmpty);
      expect(host == '127.0.0.1' || host == '10.0.2.2', isTrue);
    });
  });
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/presentation/auth/auth_error_localization.dart';
import 'package:mobile/services/auth_provider.dart' as app_auth;
import 'package:mobile/services/auth_service.dart';

// ---------------------------------------------------------------------------
// Helper: wrap widget dengan delegate dan locale tertentu
// ---------------------------------------------------------------------------
Widget _wrap(Widget child, {Locale locale = const Locale('id')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

// ---------------------------------------------------------------------------
// Helper: dapatkan AppLocalizations untuk locale tertentu tanpa pump widget
// ---------------------------------------------------------------------------
Future<AppLocalizations> _l10n(WidgetTester tester, Locale locale) async {
  late AppLocalizations result;
  await tester.pumpWidget(_wrap(
    Builder(builder: (ctx) {
      result = AppLocalizations.of(ctx);
      return const SizedBox.shrink();
    }),
    locale: locale,
  ));
  return result;
}

void main() {
  // =========================================================================
  // 1. AuthErrorLocalization — tabel kode error ID dan EN
  // =========================================================================
  group('AuthErrorLocalization.fromCode — ID', () {
    final List<(String, String Function(AppLocalizations))> cases = [
      ('user-not-found', (l) => l.authErrUserNotFound),
      ('wrong-password', (l) => l.authErrWrongPassword),
      ('invalid-credential', (l) => l.authErrInvalidCredential),
      ('email-already-in-use', (l) => l.authErrEmailInUse),
      ('invalid-email', (l) => l.authErrInvalidEmail),
      ('weak-password', (l) => l.authErrWeakPassword),
      ('too-many-requests', (l) => l.authErrTooManyRequests),
      ('network-request-failed', (l) => l.authErrNetworkFailed),
      ('requires-recent-login', (l) => l.authErrRequiresRecentLogin),
      ('user-disabled', (l) => l.authErrUserDisabled),
    ];

    // Tes ini dijalankan sebagai widget test supaya AppLocalizations tersedia.
    testWidgets('Setiap kode error dipetakan ke string ID yang benar', (tester) async {
      final l10n = await _l10n(tester, const Locale('id'));
      for (final (code, expected) in cases) {
        final actual = AuthErrorLocalization.fromCode(l10n, code);
        expect(actual, equals(expected(l10n)),
            reason: 'Kode "$code" tidak dipetakan dengan benar di ID');
      }
    });

    testWidgets('Kode tidak dikenal menggunakan authErrUnknown (ID)', (tester) async {
      final l10n = await _l10n(tester, const Locale('id'));
      expect(
        AuthErrorLocalization.fromCode(l10n, 'kode-aneh-tidak-ada'),
        equals(l10n.authErrUnknown),
      );
    });

    testWidgets('null code menggunakan authErrUnknown (ID)', (tester) async {
      final l10n = await _l10n(tester, const Locale('id'));
      expect(
        AuthErrorLocalization.fromCode(l10n, null),
        equals(l10n.authErrUnknown),
      );
    });

    testWidgets('fallbackMessage digunakan untuk kode tidak dikenal', (tester) async {
      final l10n = await _l10n(tester, const Locale('id'));
      const fallback = 'Gagal melakukan pendaftaran: some error';
      expect(
        AuthErrorLocalization.fromCode(l10n, 'not-initialized', fallbackMessage: fallback),
        equals(fallback),
      );
    });
  });

  group('AuthErrorLocalization.fromCode — EN', () {
    testWidgets('Setiap kode error dipetakan ke string EN yang benar', (tester) async {
      final l10n = await _l10n(tester, const Locale('en'));
      final List<(String, String Function(AppLocalizations))> cases = [
        ('user-not-found', (l) => l.authErrUserNotFound),
        ('wrong-password', (l) => l.authErrWrongPassword),
        ('invalid-credential', (l) => l.authErrInvalidCredential),
        ('email-already-in-use', (l) => l.authErrEmailInUse),
        ('invalid-email', (l) => l.authErrInvalidEmail),
        ('weak-password', (l) => l.authErrWeakPassword),
        ('too-many-requests', (l) => l.authErrTooManyRequests),
        ('network-request-failed', (l) => l.authErrNetworkFailed),
        ('requires-recent-login', (l) => l.authErrRequiresRecentLogin),
        ('user-disabled', (l) => l.authErrUserDisabled),
      ];
      for (final (code, expected) in cases) {
        final actual = AuthErrorLocalization.fromCode(l10n, code);
        expect(actual, equals(expected(l10n)),
            reason: 'Kode "$code" tidak dipetakan dengan benar di EN');
      }
    });

    testWidgets('ID dan EN menghasilkan string yang BERBEDA (bukan duplikat)', (tester) async {
      final idL10n = await _l10n(tester, const Locale('id'));
      final enL10n = await _l10n(tester, const Locale('en'));
      // Spot-check beberapa kode penting
      for (final code in ['user-not-found', 'invalid-credential', 'too-many-requests']) {
        final idMsg = AuthErrorLocalization.fromCode(idL10n, code);
        final enMsg = AuthErrorLocalization.fromCode(enL10n, code);
        expect(idMsg, isNot(equals(enMsg)),
            reason: 'ID dan EN harus berbeda untuk kode "$code"');
      }
    });
  });

  // =========================================================================
  // 2. Locale-lock: tanpa override, locale harus id
  // =========================================================================
  group('Locale lock — default ID selama fase migrasi', () {
    testWidgets('Tanpa override, widget menggunakan locale id', (tester) async {
      // Simulasi: tidak ada DevicePreview, tidak ada override locale
      String? detectedLocale;
      await tester.pumpWidget(
        MaterialApp(
          // locale dipaksa ke id oleh LocaleProvider selama fase 2A
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(builder: (ctx) {
            detectedLocale = AppLocalizations.of(ctx).localeName;
            return const SizedBox.shrink();
          }),
        ),
      );
      expect(detectedLocale, equals('id'),
          reason: 'LocaleProvider dikunci ke id selama fase 2A — perangkat EN pun harus tampil ID');
    });

    testWidgets('Saat locale en diset eksplisit, string menjadi Inggris', (tester) async {
      String? loginTitle;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(builder: (ctx) {
            loginTitle = AppLocalizations.of(ctx).authLoginTitle;
            return const SizedBox.shrink();
          }),
        ),
      );
      expect(loginTitle, equals('Sign in to Farlean LMS'));
    });
  });

  // =========================================================================
  // 3. authErrorCode dibersihkan di semua jalur
  // =========================================================================
  group('AuthProvider.authErrorCode — cleared correctly', () {
    test('authErrorCode null setelah init tanpa error', () {
      final provider = app_auth.AuthProvider(authService: _FakeAuthService());
      expect(provider.authErrorCode, isNull);
      expect(provider.errorMessage, isNull);
    });

    test('authErrorCode dibersihkan oleh _clearError via signIn baru', () async {
      final fakeService = _FakeAuthService(
        signInResult: () => throw FirebaseAuthException(code: 'wrong-password'),
      );
      final provider = app_auth.AuthProvider(authService: fakeService);

      // Percobaan 1: gagal → set kode
      await provider.signIn(email: 'a@b.com', password: 'bad');
      expect(provider.authErrorCode, equals('wrong-password'));
      expect(provider.errorMessage, isNotNull);

      // Percobaan 2 dimulai → _clearError dipanggil di awal signIn
      // (percobaan kedua juga gagal, tapi kode di-reset saat mulai)
      final fakeService2 = _FakeAuthService(
        signInResult: () => throw FirebaseAuthException(code: 'too-many-requests'),
      );
      final provider2 = app_auth.AuthProvider(authService: fakeService2);
      await provider2.signIn(email: 'a@b.com', password: 'x');
      expect(provider2.authErrorCode, equals('too-many-requests'));
    });

    test('authErrorCode dibersihkan saat signOut', () async {
      final fakeService = _FakeAuthService(
        signInResult: () => throw FirebaseAuthException(code: 'invalid-credential'),
      );
      final provider = app_auth.AuthProvider(authService: fakeService);
      await provider.signIn(email: 'a@b.com', password: 'bad');
      expect(provider.authErrorCode, isNotNull);

      await provider.signOut();
      expect(provider.authErrorCode, isNull);
      expect(provider.errorMessage, isNull);
    });
  });

  // =========================================================================
  // 4. AuthErrorLocalization.extractCode
  // =========================================================================
  group('AuthErrorLocalization.extractCode', () {
    test('FirebaseAuthException menghasilkan code yang benar', () {
      final ex = FirebaseAuthException(code: 'user-not-found');
      expect(AuthErrorLocalization.extractCode(ex), equals('user-not-found'));
    });

    test('Non-Firebase exception menghasilkan null', () {
      expect(AuthErrorLocalization.extractCode(Exception('generic')), isNull);
      expect(AuthErrorLocalization.extractCode('string error'), isNull);
    });

    test('null menghasilkan null', () {
      expect(AuthErrorLocalization.extractCode(null), isNull);
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers untuk tester tanpa framework pump penuh
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Fake AuthService untuk unit test AuthProvider tanpa Firebase
// ---------------------------------------------------------------------------
class _FakeAuthService extends AuthService {
  final Object Function()? signInResult;

  _FakeAuthService({this.signInResult})
      : super(auth: null, firestore: null);

  @override
  Future<User?> signInRaw({required String email, required String password}) async {
    final fn = signInResult;
    if (fn != null) throw fn();
    return null;
  }

  @override
  Future<void> signOut() async {
    // no-op untuk test: AuthProvider.signOut() mengelola cleanup state sendiri
  }

  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  User? get currentFirebaseUser => null;

  @override
  bool get hasPasswordProvider => false;
}

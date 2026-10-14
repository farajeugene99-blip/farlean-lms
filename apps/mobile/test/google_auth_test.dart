import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/presentation/auth/login_screen.dart';
import 'package:mobile/presentation/auth/register_screen.dart';
import 'package:mobile/presentation/common/google_logo.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:provider/provider.dart';

class _FakeIdTokenResult implements IdTokenResult {
  @override
  final Map<String, dynamic>? claims;
  @override
  final String token = 'mock_token';

  _FakeIdTokenResult({this.claims});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirebaseUser implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName;
  @override
  final bool emailVerified = true;

  _FakeFirebaseUser({
    required this.uid,
    this.email,
    this.displayName,
  });

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async => 'mock_token_$uid';

  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async {
    return _FakeIdTokenResult(claims: const {'role': 'USER'});
  }

  @override
  Future<void> reload() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockAuthServiceForGoogle extends AuthService {
  bool signInWithGoogleCalled = false;
  bool signOutCalled = false;
  AppUser? mockUserToReturn;
  User? mockFirebaseUser;
  Exception? exceptionToThrow;

  _MockAuthServiceForGoogle({
    this.mockUserToReturn,
    this.exceptionToThrow,
  }) : super(auth: null, firestore: null);

  @override
  User? get currentFirebaseUser => mockFirebaseUser;

  @override
  Future<AppUser?> getUserProfile(String uid) async => mockUserToReturn;

  @override
  Future<AppUser?> signInWithGoogle() async {
    signInWithGoogleCalled = true;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    if (mockUserToReturn != null) {
      mockFirebaseUser ??= _FakeFirebaseUser(
        uid: mockUserToReturn!.uid,
        email: mockUserToReturn!.email,
        displayName: mockUserToReturn!.name,
      );
    }
    return mockUserToReturn;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    mockFirebaseUser = null;
  }
}

Widget _buildTestWidget(Widget child, AuthProvider authProvider) {
  return MaterialApp(
    locale: const Locale('id'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.lightTheme,
    home: ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: child,
    ),
  );
}

void main() {
  group('Google Sign-In & Sign-Out Unit & Widget Tests', () {
    test('1. signInWithGoogle sukses memuat profil dan memperbarui state', () async {
      final mockService = _MockAuthServiceForGoogle(
        mockUserToReturn: const AppUser(
          uid: 'google_uid_01',
          name: 'Google User',
          email: 'user@google.com',
          accountType: AccountType.umum,
          role: UserRole.user,
        ),
      );
      final provider = AuthProvider(authService: mockService);

      final result = await provider.signInWithGoogle();

      expect(result, isTrue);
      expect(mockService.signInWithGoogleCalled, isTrue);
      expect(provider.appUser?.name, equals('Google User'));
      expect(provider.errorMessage, isNull);
    });

    test('2. signInWithGoogle dibatalkan pengguna (null) kembali bersih tanpa error', () async {
      final mockService = _MockAuthServiceForGoogle(mockUserToReturn: null);
      final provider = AuthProvider(authService: mockService);

      final result = await provider.signInWithGoogle();

      expect(result, isFalse);
      expect(mockService.signInWithGoogleCalled, isTrue);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.authErrorCode, isNull);
    });

    test('3. signInWithGoogle melempar error tertangani ramah pengguna', () async {
      final mockService = _MockAuthServiceForGoogle(
        exceptionToThrow: Exception('Gagal komunikasi Google'),
      );
      final provider = AuthProvider(authService: mockService);

      final result = await provider.signInWithGoogle();

      expect(result, isFalse);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNotNull);
    });

    test('4. signOut memanggil GoogleSignIn.signOut tanpa error', () async {
      final mockService = _MockAuthServiceForGoogle();
      final provider = AuthProvider(authService: mockService);

      await provider.signOut();

      expect(mockService.signOutCalled, isTrue);
      expect(provider.isAuthenticated, isFalse);
    });

    testWidgets('5. LoginScreen menampilkan tombol "Masuk dengan Google" dan GoogleLogo', (tester) async {
      final mockService = _MockAuthServiceForGoogle();
      final provider = AuthProvider(authService: mockService);

      await tester.pumpWidget(_buildTestWidget(const LoginScreen(), provider));
      await tester.pumpAndSettle();

      expect(find.text('Masuk dengan Google'), findsOneWidget);
      expect(find.byType(GoogleLogo), findsOneWidget);
      expect(find.text('atau'), findsOneWidget);

      await tester.tap(find.text('Masuk dengan Google'));
      await tester.pump();

      expect(mockService.signInWithGoogleCalled, isTrue);
    });

    testWidgets('6. RegisterScreen menampilkan tombol "Daftar dengan Google" dan GoogleLogo', (tester) async {
      final mockService = _MockAuthServiceForGoogle();
      final provider = AuthProvider(authService: mockService);

      await tester.pumpWidget(_buildTestWidget(const RegisterScreen(), provider));
      await tester.pumpAndSettle();

      expect(find.text('Daftar dengan Google'), findsOneWidget);
      expect(find.byType(GoogleLogo), findsOneWidget);
      expect(find.text('atau'), findsOneWidget);

      await tester.tap(find.text('Daftar dengan Google'));
      await tester.pump();

      expect(mockService.signInWithGoogleCalled, isTrue);
    });
  });
}

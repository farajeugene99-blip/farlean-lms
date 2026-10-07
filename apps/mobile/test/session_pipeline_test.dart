import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:mobile/services/auth_service.dart';

class FakeUser implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName;
  @override
  final bool emailVerified;

  FakeUser({
    required this.uid,
    this.email,
    this.displayName,
    this.emailVerified = true,
  });

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async => 'mock_token_$uid';

  @override
  Future<void> reload() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAuthService extends AuthService {
  User? mockCurrentUser;
  AppUser? mockProfileToReturn;
  Exception? mockExceptionToThrow;
  int getUserProfileCallCount = 0;
  int callBootstrapCallCount = 0;
  final StreamController<User?> _authController = StreamController<User?>.broadcast();

  MockAuthService({this.mockCurrentUser, this.mockProfileToReturn});

  @override
  User? get currentFirebaseUser => mockCurrentUser;

  @override
  Stream<User?> get authStateChanges => _authController.stream;

  void emitUser(User? user) {
    mockCurrentUser = user;
    _authController.add(user);
  }

  @override
  Future<AppUser?> getUserProfile(String uid) async {
    getUserProfileCallCount++;
    if (mockExceptionToThrow != null) {
      throw mockExceptionToThrow!;
    }
    return mockProfileToReturn;
  }

  @override
  Future<void> callBootstrap({required String token, String? name}) async {
    callBootstrapCallCount++;
  }

  @override
  Future<void> signOut() async {
    mockCurrentUser = null;
    _authController.add(null);
  }
}

void main() {
  group('Session Pipeline & Generation Counter Tests', () {
    test('Successful profile load transitions to ProfileStatus.loaded with exact role & accountType', () async {
      final fakeUser = FakeUser(uid: 'guru_123', email: 'guru@dosen.farlean.edu');
      const guruUser = AppUser(
        uid: 'guru_123',
        name: 'Dosen Guru',
        email: 'guru@dosen.farlean.edu',
        accountType: AccountType.dosen,
        role: UserRole.guru,
      );

      final mockService = MockAuthService(
        mockCurrentUser: fakeUser,
        mockProfileToReturn: guruUser,
      );

      final provider = AuthProvider(authService: mockService);
      // Wait for session load triggered on init or call refreshSession
      await provider.refreshSession();

      // State harus loaded dengan data profil yang tepat
      expect(provider.profileStatus, equals(ProfileStatus.loaded));
      expect(provider.appUser, isNotNull);
      expect(provider.appUser?.role, equals(UserRole.guru));
      expect(provider.appUser?.accountType, equals(AccountType.dosen));
      expect(provider.profileErrorMessage, isNull);
    });

    test('Profile not found does NOT fallback to UMUM/USER, but sets ProfileStatus.error', () async {
      final fakeUser = FakeUser(uid: 'missing_user', email: 'user@farlean.edu');
      final mockService = MockAuthService(
        mockCurrentUser: fakeUser,
        mockProfileToReturn: null, // Dokumen belum ada
      );

      final provider = AuthProvider(authService: mockService);
      await provider.refreshSession();

      // TIDAK BOLEH fallback ke UMUM/USER!
      expect(provider.profileStatus, equals(ProfileStatus.error));
      expect(provider.appUser, isNull);
      expect(provider.profileErrorReason, equals(ProfileErrorReason.notFound));
      expect(provider.profileErrorMessage, contains('Profil pengguna belum berhasil dimuat'));
    });

    test('Generation counter invalidates in-flight fetch when signOut is called', () async {
      final fakeUser = FakeUser(uid: 'slow_user', email: 'slow@farlean.edu');
      final mockService = MockAuthService(mockCurrentUser: fakeUser);

      // Simulasi fetch yang lambat
      mockService.mockProfileToReturn = const AppUser(
        uid: 'slow_user',
        name: 'Slow User',
        email: 'slow@farlean.edu',
        accountType: AccountType.mahasiswa,
        role: UserRole.user,
      );

      final provider = AuthProvider(authService: mockService);
      final initialGen = provider.sessionGeneration;

      // Panggil signOut
      await provider.signOut();

      // Pastikan generation counter naik
      expect(provider.sessionGeneration, greaterThan(initialGen));
      expect(provider.profileStatus, equals(ProfileStatus.initial));
      expect(provider.appUser, isNull);
    });

    test('Account Type UMUM with role GURU preserves role GURU in loaded state', () async {
      final fakeUser = FakeUser(uid: 'umum_guru_99', email: 'instruktur@gmail.com');
      const umumGuru = AppUser(
        uid: 'umum_guru_99',
        name: 'Instruktur Umum',
        email: 'instruktur@gmail.com',
        accountType: AccountType.umum,
        role: UserRole.guru,
      );

      final mockService = MockAuthService(
        mockCurrentUser: fakeUser,
        mockProfileToReturn: umumGuru,
      );

      final provider = AuthProvider(authService: mockService);
      await provider.refreshSession();

      expect(provider.profileStatus, equals(ProfileStatus.loaded));
      expect(provider.appUser?.accountType, equals(AccountType.umum));
      expect(provider.appUser?.role, equals(UserRole.guru));
    });
  });
}

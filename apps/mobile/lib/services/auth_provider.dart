import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import 'auth_service.dart';

enum ProfileStatus {
  initial,
  loading,
  loaded,
  error,
}

enum ProfileErrorReason {
  none,
  notFound,
  permissionDenied,
  network,
  unknown,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  StreamSubscription<User?>? _authSubscription;

  User? _firebaseUser;
  AppUser? _appUser;
  bool _isLoading = false;
  String? _errorMessage;
  // Kode error Firebase Auth terakhir — dipakai layer UI untuk lokalisasi pesan.
  // Dibersihkan bersama _errorMessage di _clearError() dan saat operasi baru dimulai.
  String? _authErrorCode;

  int _sessionGeneration = 0;
  ProfileStatus _profileStatus = ProfileStatus.initial;
  ProfileErrorReason _profileErrorReason = ProfileErrorReason.none;
  String? _profileErrorMessage;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService() {
    _init();
  }

  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  // Kode error Firebase Auth terakhir (null jika tidak ada error atau bukan FirebaseAuthException).
  String? get authErrorCode => _authErrorCode;

  ProfileStatus get profileStatus => _profileStatus;
  ProfileErrorReason get profileErrorReason => _profileErrorReason;
  String? get profileErrorMessage => _profileErrorMessage;
  int get sessionGeneration => _sessionGeneration;
  bool get isRoleOutOfSync => _appUser?.isRoleOutOfSync ?? false;
  bool get hasPasswordProvider => _authService.hasPasswordProvider;

  bool get isAuthenticated => _firebaseUser != null;
  bool get isEmailVerified => _firebaseUser?.emailVerified ?? false;

  void _init() {
    _firebaseUser = _authService.currentFirebaseUser;
    if (_firebaseUser != null) {
      _loadSession();
    }
    _authSubscription = _authService.authStateChanges.listen((user) async {
      if (user == null) {
        _sessionGeneration++;
        _firebaseUser = null;
        _appUser = null;
        _profileStatus = ProfileStatus.initial;
        _profileErrorReason = ProfileErrorReason.none;
        _profileErrorMessage = null;
        _errorMessage = null;     // bersihkan error saat sesi berakhir
        _authErrorCode = null;    // bersihkan kode agar tidak bocor ke login berikutnya
        notifyListeners();
      } else {
        if (_firebaseUser?.uid != user.uid || _profileStatus == ProfileStatus.initial) {
          _firebaseUser = user;
          await _loadSession();
        }
      }
    });
  }

  /// Pipeline tunggal pemuatan sesi pengguna
  Future<void> _loadSession({bool forceRefresh = false}) async {
    _sessionGeneration++;
    final currentGen = _sessionGeneration;

    final user = _authService.currentFirebaseUser;
    if (user == null) {
      _firebaseUser = null;
      _appUser = null;
      _profileStatus = ProfileStatus.initial;
      _profileErrorReason = ProfileErrorReason.none;
      _profileErrorMessage = null;
      notifyListeners();
      return;
    }

    _firebaseUser = user;
    _profileStatus = ProfileStatus.loading;
    _profileErrorReason = ProfileErrorReason.none;
    _profileErrorMessage = null;
    notifyListeners();

    try {
      // 1. Dapatkan token & Custom Claims pengguna
      final tokenResult = await user.getIdTokenResult(forceRefresh);
      if (currentGen != _sessionGeneration) return;

      final token = tokenResult.token;
      final rawClaimsRole = tokenResult.claims?['role'] as String?;
      final claimsRole = rawClaimsRole != null ? UserRole.fromString(rawClaimsRole) : null;

      // 2. Sinkronisasi via bootstrap Admin SDK
      if (token != null) {
        await _authService.callBootstrap(token: token, name: user.displayName);
        if (currentGen != _sessionGeneration) return;
      }

      // 3. Ambil profil dari Firestore
      AppUser? profile;
      try {
        profile = await _authService.getUserProfile(user.uid);
      } on FirebaseException catch (fe) {
        if (currentGen != _sessionGeneration) return;
        if (fe.code == 'permission-denied') {
          debugPrint('⚠️ [AuthProvider] permission-denied saat baca profil. Mencoba user.reload() & getIdToken(true)...');
          try {
            await user.reload();
            final freshToken = await user.getIdToken(true);
            if (currentGen != _sessionGeneration) return;
            if (freshToken != null) {
              await _authService.callBootstrap(token: freshToken, name: user.displayName);
              if (currentGen != _sessionGeneration) return;
            }
            profile = await _authService.getUserProfile(user.uid);
          } catch (retryErr) {
            debugPrint('⚠️ [AuthProvider] Retry permission-denied gagal: $retryErr');
          }
        } else if (fe.code == 'unavailable') {
          _appUser = null;
          _profileStatus = ProfileStatus.error;
          _profileErrorReason = ProfileErrorReason.network;
          _profileErrorMessage = 'Koneksi ke database gagal. Periksa jaringan internet atau emulator Anda.';
          notifyListeners();
          return;
        } else {
          debugPrint('⚠️ [AuthProvider] FirebaseException: ${fe.code} - ${fe.message}');
        }
      } catch (err) {
        if (currentGen != _sessionGeneration) return;
        debugPrint('⚠️ [AuthProvider] Error membaca profil: $err');
      }

      if (currentGen != _sessionGeneration) return;

      // 4. Jika profil masih null (dokumen belum dibuat / not-found):
      if (profile == null) {
        debugPrint('⚠️ [AuthProvider] Dokumen profil belum ada. Mencoba bootstrap ulang...');
        try {
          final retryToken = await user.getIdToken(true);
          if (currentGen != _sessionGeneration) return;
          if (retryToken != null) {
            await _authService.callBootstrap(token: retryToken, name: user.displayName);
            if (currentGen != _sessionGeneration) return;
            profile = await _authService.getUserProfile(user.uid);
          }
        } catch (retryErr) {
          debugPrint('⚠️ [AuthProvider] Retry bootstrap gagal: $retryErr');
        }
      }

      if (currentGen != _sessionGeneration) return;

      // 5. Evaluasi hasil profil (JANGAN FALLBACK KE UMUM/USER!)
      if (profile != null) {
        _appUser = profile.copyWith(claimsRole: claimsRole);
        _profileStatus = ProfileStatus.loaded;
        _profileErrorReason = ProfileErrorReason.none;
        _profileErrorMessage = null;
      } else {
        _appUser = null;
        _profileStatus = ProfileStatus.error;
        _profileErrorReason = ProfileErrorReason.notFound;
        _profileErrorMessage = 'Profil pengguna belum berhasil dimuat. Silakan tekan tombol Coba Lagi.';
      }
    } catch (e) {
      if (currentGen != _sessionGeneration) return;
      _appUser = null;
      _profileStatus = ProfileStatus.error;
      _profileErrorReason = ProfileErrorReason.unknown;
      _profileErrorMessage = 'Terjadi kesalahan saat memuat profil: $e';
    }

    notifyListeners();
  }

  /// Masuk dengan proteksi anti-duplicate submit dan pipeline sesi terpusat
  Future<bool> signIn({required String email, required String password}) async {
    if (_isLoading) return false;
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.signInRaw(email: email, password: password);
      if (user == null) {
        _setLoading(false);
        return false;
      }
      _firebaseUser = user;
      await _loadSession(forceRefresh: true);
      _setLoading(false);
      return _profileStatus == ProfileStatus.loaded;
    } catch (e) {
      _setError(AuthService.translateError(e), code: _extractCode(e));
      _setLoading(false);
      return false;
    }
  }

  /// Pendaftaran dengan proteksi anti-duplicate submit
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (_isLoading) return false;
    _setLoading(true);
    _clearError();

    try {
      await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      _firebaseUser = _authService.currentFirebaseUser;
      await _loadSession(forceRefresh: true);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(AuthService.translateError(e), code: _extractCode(e));
      _setLoading(false);
      return false;
    }
  }

  /// Pengecekan ulang verifikasi email + penyegaran token
  Future<bool> checkEmailVerification() async {
    if (_isLoading) return false;
    _setLoading(true);
    _clearError();

    try {
      final isVerified = await _authService.reloadAndCheckVerification();
      if (isVerified) {
        await _loadSession(forceRefresh: true);
      }
      _setLoading(false);
      return isVerified;
    } catch (e) {
      _setError(AuthService.translateError(e), code: _extractCode(e));
      _setLoading(false);
      return false;
    }
  }

  /// Penyegaran manual sesi pengguna dan token
  Future<void> refreshSession() async {
    await _loadSession(forceRefresh: true);
  }

  /// Mencoba ulang memuat sesi jika sebelumnya terjadi kegagalan
  Future<void> retryLoadSession() async {
    await _loadSession(forceRefresh: true);
  }

  /// Kirim ulang email verifikasi
  Future<bool> resendVerificationEmail() async {
    try {
      await _authService.sendEmailVerification();
      return true;
    } catch (e) {
      _setError(AuthService.translateError(e), code: _extractCode(e));
      return false;
    }
  }

  /// Permintaan reset kata sandi
  Future<bool> sendPasswordReset(String email) async {
    if (_isLoading) return false;
    _setLoading(true);
    _clearError();

    try {
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(AuthService.translateError(e), code: _extractCode(e));
      _setLoading(false);
      return false;
    }
  }

  /// Mengubah kata sandi pengguna terautentikasi
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _authService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  /// Keluar dari akun dengan pembatalan generasi sesi
  Future<void> signOut() async {
    _sessionGeneration++;
    _setLoading(true);
    _clearError(); // bersihkan error lama agar tidak bocor ke layar berikutnya
    try {
      await _authService.signOut();
      _firebaseUser = null;
      _appUser = null;
      _profileStatus = ProfileStatus.initial;
      _profileErrorReason = ProfileErrorReason.none;
      _profileErrorMessage = null;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _setError(String msg, {String? code}) {
    _errorMessage = msg;
    _authErrorCode = code;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    _authErrorCode = null;
  }

  /// Mengekstrak kode error dari FirebaseAuthException/FirebaseException secara aman.
  /// Mengembalikan null untuk error lain (misalnya SocketException, generic Exception).
  static String? _extractCode(dynamic error) {
    try {
      // FirebaseAuthException dan FirebaseException keduanya punya field `code`.
      // Cek via dynamic agar helper ini tidak bergantung pada import firebase_auth.
      // ignore: avoid_dynamic_calls
      return (error as dynamic).code as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

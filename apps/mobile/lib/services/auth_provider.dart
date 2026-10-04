import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import 'auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  StreamSubscription<User?>? _authSubscription;

  User? _firebaseUser;
  AppUser? _appUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService() {
    _init();
  }

  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _firebaseUser != null;
  bool get isEmailVerified => _firebaseUser?.emailVerified ?? false;

  void _init() {
    _firebaseUser = _authService.currentFirebaseUser;
    _authSubscription = _authService.authStateChanges.listen((user) async {
      _firebaseUser = user;
      if (user != null) {
        await _fetchAppUserProfile(user.uid);
      } else {
        _appUser = null;
      }
      notifyListeners();
    });
  }

  Future<void> _fetchAppUserProfile(String uid) async {
    try {
      final profile = await _authService.getUserProfile(uid);
      if (profile != null) {
        _appUser = profile;
      } else {
        // Fallback display profile jika Firestore belum sync
        _appUser = AppUser(
          uid: uid,
          name: _firebaseUser?.displayName ?? 'Pengguna',
          email: _firebaseUser?.email ?? '',
          accountType: AccountType.umum,
          role: UserRole.user,
        );
      }
    } catch (e) {
      debugPrint('Catatan ambil profil di auth provider: $e');
    }
  }

  /// Masuk dengan proteksi anti-duplicate submit
  Future<bool> signIn({required String email, required String password}) async {
    if (_isLoading) return false;
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.signIn(email: email, password: password);
      _appUser = user;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(AuthService.translateError(e));
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
      final user = await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      _appUser = user;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(AuthService.translateError(e));
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
      if (_firebaseUser != null) {
        await _fetchAppUserProfile(_firebaseUser!.uid);
      }
      _setLoading(false);
      return isVerified;
    } catch (e) {
      _setError(AuthService.translateError(e));
      _setLoading(false);
      return false;
    }
  }

  /// Kirim ulang email verifikasi
  Future<bool> resendVerificationEmail() async {
    try {
      await _authService.sendEmailVerification();
      return true;
    } catch (e) {
      _setError(AuthService.translateError(e));
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
      _setError(AuthService.translateError(e));
      _setLoading(false);
      return false;
    }
  }

  /// Keluar dari akun
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _firebaseUser = null;
      _appUser = null;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final http.Client _httpClient;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    http.Client? httpClient,
  })  : _auth = auth ?? (Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null),
        _firestore = firestore ?? (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null),
        _httpClient = httpClient ?? http.Client();

  User? get currentFirebaseUser => _auth?.currentUser;
  Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? const Stream.empty();

  /// Registrasi akun baru dengan Firebase Auth, kirim email verifikasi, dan bootstrap dokumen users/{uid}
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw FirebaseAuthException(
        code: 'not-initialized',
        message: 'Firebase belum diinisialisasi.',
      );
    }

    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-null',
          message: 'Gagal membuat pengguna baru.',
        );
      }

      await user.updateDisplayName(name.trim());
      await user.sendEmailVerification();

      // Panggil backend bootstrap untuk membuat users/{uid} dengan Admin SDK
      final token = await user.getIdToken();
      if (token != null) {
        await _callBootstrap(token: token, name: name.trim());
      }

      return AppUser(
        uid: user.uid,
        name: name.trim(),
        email: user.email ?? email.trim(),
        accountType: AccountType.umum, // Default sebelum email diverifikasi
        role: UserRole.user,
        mfaEnabled: false,
      );
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'Gagal melakukan pendaftaran: $e',
      );
    }
  }

  /// Masuk dengan email dan kata sandi dan mengembalikan User Firebase
  Future<User?> signInRaw({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw FirebaseAuthException(
        code: 'not-initialized',
        message: 'Firebase belum diinisialisasi.',
      );
    }
    final credential = await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return credential.user;
  }

  /// Masuk dengan email dan kata sandi
  Future<AppUser?> signIn({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw FirebaseAuthException(
        code: 'not-initialized',
        message: 'Firebase belum diinisialisasi.',
      );
    }

    try {
      final user = await signInRaw(email: email, password: password);
      if (user == null) return null;

      // Panggil bootstrap untuk update last_active dan sync account_type
      final token = await user.getIdToken();
      if (token != null) {
        await _callBootstrap(token: token);
      }

      return await getUserProfile(user.uid);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'Gagal masuk: $e',
      );
    }
  }

  /// Mengirim ulang email verifikasi
  Future<void> sendEmailVerification() async {
    final user = _auth?.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Reload user dan perbarui token untuk mengatasi token stale setelah verifikasi
  /// Sesuai Acceptance Criteria: reload() -> getIdToken(true) -> sync bootstrap
  Future<bool> reloadAndCheckVerification() async {
    final user = _auth?.currentUser;
    if (user == null) return false;

    await user.reload();
    final freshUser = _auth?.currentUser;
    if (freshUser == null) return false;

    if (freshUser.emailVerified) {
      final freshToken = await freshUser.getIdToken(true);
      if (freshToken != null) {
        await _callBootstrap(token: freshToken);
      }
      return true;
    }

    return false;
  }

  /// Mengirim email pemulihan kata sandi
  Future<void> sendPasswordResetEmail(String email) async {
    final auth = _auth;
    if (auth == null) {
      throw FirebaseAuthException(
        code: 'not-initialized',
        message: 'Firebase belum diinisialisasi.',
      );
    }
    await auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Keluar dari sesi aplikasi
  Future<void> signOut() async {
    await _auth?.signOut();
  }

  /// Mengambil profil lengkap pengguna dari Firestore users/{uid}
  /// Melempar FirebaseException jika terjadi kesalahan otorisasi (permission-denied) atau jaringan (unavailable)
  Future<AppUser?> getUserProfile(String uid) async {
    final firestore = _firestore;
    if (firestore == null) return null;

    try {
      final doc = await firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    } on FirebaseException catch (e) {
      debugPrint('⚠️ [AuthService] FirebaseException saat baca profil: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Catatan baca profil Firestore: $e');
      rethrow;
    }
  }

  /// Memanggil endpoint serverless bootstrap Admin SDK secara aman
  Future<void> callBootstrap({required String token, String? name}) async {
    await _callBootstrap(token: token, name: name);
  }

  Future<void> _callBootstrap({required String token, String? name}) async {
    try {
      final uri = Uri.parse(ApiConfig.bootstrapUrl);
      final response = await _httpClient.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(name != null ? {'name': name} : {}),
      );

      if (response.statusCode != 200) {
        debugPrint('⚠️ [Bootstrap API] Response code ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('⚠️ [Bootstrap API Note] Gagal menghubungi endpoint bootstrap lokal: $e');
    }
  }

  /// Menerjemahkan kode error Firebase Auth ke pesan Bahasa Indonesia yang ramah pengguna
  static String translateError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'Akun dengan alamat email ini tidak ditemukan.';
        case 'wrong-password':
          return 'Kata sandi yang Anda masukkan salah.';
        case 'invalid-credential':
          return 'Email atau kata sandi yang dimasukkan tidak sesuai.';
        case 'email-already-in-use':
          return 'Alamat email ini sudah terdaftar. Silakan gunakan menu Masuk.';
        case 'invalid-email':
          return 'Format alamat email tidak valid.';
        case 'weak-password':
          return 'Kata sandi terlalu lemah. Gunakan minimal 6 karakter.';
        case 'too-many-requests':
          return 'Terlalu banyak percobaan gagal. Silakan tunggu beberapa saat lagi.';
        case 'network-request-failed':
          return 'Koneksi ke emulator/server Firebase gagal. Pastikan Firebase Emulator aktif dan dapat dijangkau dari perangkat Anda.';
        case 'user-disabled':
          return 'Akun ini telah dinonaktifkan oleh administrator.';
        default:
          return error.message ?? 'Terjadi kesalahan otentikasi. Silakan coba lagi.';
      }
    }
    return error?.toString() ?? 'Terjadi kesalahan sistem.';
  }
}

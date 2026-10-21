import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final http.Client _httpClient;
  final GoogleSignIn _googleSignIn;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    http.Client? httpClient,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? (Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null),
        _firestore = firestore ?? (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null),
        _httpClient = httpClient ?? http.Client(),
        _googleSignIn = googleSignIn ?? GoogleSignIn();

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
        await _callBootstrap(token: token, name: name.trim(), completeProfile: true);
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

  /// Memeriksa apakah pengguna saat ini menggunakan penyedia autentikasi password (email/password)
  bool get hasPasswordProvider {
    final user = _auth?.currentUser;
    if (user == null) return false;
    if (user.providerData.isEmpty) return user.email != null && user.email!.isNotEmpty;
    return user.providerData.any((info) => info.providerId == 'password');
  }

  /// Mengubah kata sandi pengguna terautentikasi dengan re-autentikasi kredensial lama
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final auth = _auth;
    final user = auth?.currentUser;
    if (auth == null || user == null) {
      throw FirebaseAuthException(
        code: 'not-initialized',
        message: 'Pengguna belum terautentikasi.',
      );
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Pengguna tidak memiliki alamat email valid.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  /// Masuk dengan Google Sign-In, verifikasi kredensial ke Firebase Auth,
  /// dan bootstrap profil pengguna di server secara idempoten.
  /// Mengembalikan null jika pengguna membatalkan proses pemilihan akun Google.
  Future<AppUser?> signInWithGoogle() async {
    final auth = _auth;
    if (auth == null) {
      throw FirebaseAuthException(
        code: 'not-initialized',
        message: 'Firebase belum diinisialisasi.',
      );
    }

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Pengguna membatalkan dialog pemilihan akun Google
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-null',
          message: 'Gagal mengotentikasi pengguna Google.',
        );
      }

      // Panggil backend bootstrap untuk memastikan dokumen users/{uid} terbuat / terupdate
      final token = await user.getIdToken();
      if (token != null) {
        await _callBootstrap(
          token: token,
          name: user.displayName ?? googleUser.displayName,
          photoUrl: user.photoURL ?? googleUser.photoUrl,
        );
      }

      return await getUserProfile(user.uid);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'Gagal masuk dengan Google: $e',
      );
    }
  }

  /// Keluar dari sesi aplikasi (Firebase Auth & Google Sign-In)
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Catatan Google signOut: $e');
    }
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
  Future<void> callBootstrap({
    required String token,
    String? name,
    String? photoUrl,
    bool? completeProfile,
    String? nimNip,
  }) async {
    await _callBootstrap(
      token: token,
      name: name,
      photoUrl: photoUrl,
      completeProfile: completeProfile,
      nimNip: nimNip,
    );
  }

  Future<void> _callBootstrap({
    required String token,
    String? name,
    String? photoUrl,
    bool? completeProfile,
    String? nimNip,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.bootstrapUrl);
      final body = <String, dynamic>{};
      if (name != null && name.trim().isNotEmpty) body['name'] = name.trim();
      if (photoUrl != null && photoUrl.trim().isNotEmpty) body['photoUrl'] = photoUrl.trim();
      if (completeProfile != null) body['completeProfile'] = completeProfile;
      if (nimNip != null && nimNip.trim().isNotEmpty) body['nimNip'] = nimNip.trim();

      final response = await _httpClient.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        debugPrint('⚠️ [Bootstrap API] Response code ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('⚠️ [Bootstrap API Note] Gagal menghubungi endpoint bootstrap: $e');
    }
  }

  /// Menerjemahkan kode error Firebase Auth ke pesan Bahasa Indonesia yang ramah pengguna
  static String translateError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'Akun dengan alamat email ini tidak ditemukan.';
        case 'wrong-password':
          return 'Kata sandi yang Anda masukkan salah. Jika sebelumnya Anda mendaftar dengan Google, silakan gunakan tombol Masuk dengan Google.';
        case 'invalid-credential':
          return 'Email atau kata sandi yang dimasukkan tidak sesuai. Jika sebelumnya Anda mendaftar dengan Google, silakan gunakan tombol Masuk dengan Google.';
        case 'account-exists-with-different-credential':
          return 'Alamat email ini sudah terdaftar menggunakan metode masuk lain. Silakan masuk menggunakan metode tersebut.';
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
        case 'requires-recent-login':
          return 'Sesi Anda telah kedaluwarsa. Harap keluar dan masuk kembali sebelum mengubah kata sandi.';
        case 'user-disabled':
          return 'Akun ini telah dinonaktifkan oleh administrator.';
        case 'google-sign-in-failed':
          return 'Gagal masuk dengan Google. Silakan coba lagi.';
        default:
          return error.message ?? 'Terjadi kesalahan otentikasi. Silakan coba lagi.';
      }
    }
    return error?.toString() ?? 'Terjadi kesalahan sistem.';
  }
}

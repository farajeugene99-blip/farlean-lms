import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/auth_service.dart';

void main() {
  group('AuthService.translateError Tests', () {
    test('user-not-found diterjemahkan ke pesan yang ramah pengguna', () {
      final error = FirebaseAuthException(code: 'user-not-found');
      expect(
        AuthService.translateError(error),
        equals('Akun dengan alamat email ini tidak ditemukan.'),
      );
    });

    test('wrong-password diterjemahkan dengan benar', () {
      final error = FirebaseAuthException(code: 'wrong-password');
      expect(
        AuthService.translateError(error),
        equals('Kata sandi yang Anda masukkan salah.'),
      );
    });

    test('invalid-credential diterjemahkan dengan benar', () {
      final error = FirebaseAuthException(code: 'invalid-credential');
      expect(
        AuthService.translateError(error),
        equals('Email atau kata sandi yang dimasukkan tidak sesuai.'),
      );
    });

    test('email-already-in-use diterjemahkan dengan benar', () {
      final error = FirebaseAuthException(code: 'email-already-in-use');
      expect(
        AuthService.translateError(error),
        equals('Alamat email ini sudah terdaftar. Silakan gunakan menu Masuk.'),
      );
    });

    test('weak-password diterjemahkan dengan benar', () {
      final error = FirebaseAuthException(code: 'weak-password');
      expect(
        AuthService.translateError(error),
        equals('Kata sandi terlalu lemah. Gunakan minimal 6 karakter.'),
      );
    });

    test('too-many-requests diterjemahkan dengan benar', () {
      final error = FirebaseAuthException(code: 'too-many-requests');
      expect(
        AuthService.translateError(error),
        equals('Terlalu banyak percobaan gagal. Silakan tunggu beberapa saat lagi.'),
      );
    });

    test('network-request-failed diterjemahkan dengan benar', () {
      final error = FirebaseAuthException(code: 'network-request-failed');
      expect(
        AuthService.translateError(error),
        equals('Koneksi internet bermasalah. Periksa jaringan Anda.'),
      );
    });
  });
}

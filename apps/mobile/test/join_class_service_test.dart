import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/join_class_service.dart';

void main() {
  group('JoinClassService Code Format Validation Tests', () {
    test('Kode kosong atau null menghasilkan pesan error', () {
      expect(
        JoinClassService.validateCodeFormat(null),
        equals('Kode kelas wajib diisi.'),
      );
      expect(
        JoinClassService.validateCodeFormat(''),
        equals('Kode kelas wajib diisi.'),
      );
      expect(
        JoinClassService.validateCodeFormat('   '),
        equals('Kode kelas wajib diisi.'),
      );
    });

    test('Panjang kode kurang dari 6 karakter menghasilkan error', () {
      expect(
        JoinClassService.validateCodeFormat('ABCDE'),
        equals('Panjang kode kelas harus antara 6 hingga 12 karakter.'),
      );
    });

    test('Panjang kode lebih dari 12 karakter menghasilkan error', () {
      expect(
        JoinClassService.validateCodeFormat('ABCDEFGHIJKLM'),
        equals('Panjang kode kelas harus antara 6 hingga 12 karakter.'),
      );
    });

    test('Karakter non-alfanumerik menghasilkan error format', () {
      expect(
        JoinClassService.validateCodeFormat('FARLEAN@1'),
        equals('Kode kelas hanya boleh mengandung huruf kapital dan angka.'),
      );
      expect(
        JoinClassService.validateCodeFormat('FAR LEAN1'),
        equals('Kode kelas hanya boleh mengandung huruf kapital dan angka.'),
      );
      expect(
        JoinClassService.validateCodeFormat('farlean#1'),
        equals('Kode kelas hanya boleh mengandung huruf kapital dan angka.'),
      );
    });

    test('Format valid (6 - 12 karakter alfanumerik) menghasilkan null', () {
      expect(JoinClassService.validateCodeFormat('FARLEAN1'), isNull);
      expect(JoinClassService.validateCodeFormat('ABC12345'), isNull);
      expect(JoinClassService.validateCodeFormat('KODEKELAS123'), isNull);
      expect(JoinClassService.validateCodeFormat('123456'), isNull);
    });

    test('joinClass melempar JoinClassException jika format tidak valid', () async {
      final service = JoinClassService();
      expect(
        () => service.joinClass('short'),
        throwsA(isA<JoinClassException>()),
      );
    });

    test('joinClass melempar JoinClassException jika user belum login', () async {
      final service = JoinClassService();
      expect(
        () => service.joinClass('FARLEAN1'),
        throwsA(isA<JoinClassException>()),
      );
    });
  });
}

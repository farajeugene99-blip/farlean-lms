import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/repositories/user_repository.dart';

void main() {
  group('UserRepository Validation Tests', () {
    late UserRepository repository;

    setUp(() {
      repository = UserRepository();
    });

    test('updateName melempar ArgumentError jika nama kosong', () async {
      expect(
        () => repository.updateName('uid_123', ''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => repository.updateName('uid_123', '   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('updateName melempar ArgumentError jika nama lebih dari 100 karakter', () async {
      final longName = 'A' * 101;
      expect(
        () => repository.updateName('uid_123', longName),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('setPrivateIdentity melempar ArgumentError jika NIM/NIP kosong', () async {
      expect(
        () => repository.setPrivateIdentity('uid_123', ''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => repository.setPrivateIdentity('uid_123', '   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('getUser mengembalikan null secara aman jika Firestore belum diinisialisasi', () async {
      final result = await repository.getUser('uid_123');
      expect(result, isNull);
    });

    test('getPrivateIdentity mengembalikan null secara aman jika Firestore belum diinisialisasi', () async {
      final result = await repository.getPrivateIdentity('uid_123');
      expect(result, isNull);
    });
  });
}

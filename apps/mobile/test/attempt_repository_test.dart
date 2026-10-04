import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/repositories/attempt_repository.dart';

void main() {
  group('AttemptRepository Validation Tests', () {
    late AttemptRepository repository;

    setUp(() {
      repository = AttemptRepository();
    });

    test('startAttempt melempar ArgumentError jika userId kosong', () async {
      expect(
        () => repository.startAttempt(
          userId: '',
          testId: 't1',
          classId: 'c1',
          attemptNo: 1,
          questionOrder: ['q1'],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('startAttempt melempar ArgumentError jika testId kosong', () async {
      expect(
        () => repository.startAttempt(
          userId: 'u1',
          testId: '',
          classId: 'c1',
          attemptNo: 1,
          questionOrder: ['q1'],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('startAttempt melempar ArgumentError jika questionOrder kosong', () async {
      expect(
        () => repository.startAttempt(
          userId: 'u1',
          testId: 't1',
          classId: 'c1',
          attemptNo: 1,
          questionOrder: [],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('getInProgressAttempt mengembalikan null secara aman saat Firestore uninitialized', () async {
      final attempt = await repository.getInProgressAttempt(
        userId: 'u1',
        testId: 't1',
      );
      expect(attempt, isNull);
    });

    test('getAttemptCount mengembalikan 0 secara aman saat Firestore uninitialized', () async {
      final count = await repository.getAttemptCount(
        userId: 'u1',
        testId: 't1',
      );
      expect(count, equals(0));
    });

    test('getAttempt mengembalikan null secara aman saat Firestore uninitialized', () async {
      final attempt = await repository.getAttempt('a1');
      expect(attempt, isNull);
    });
  });
}

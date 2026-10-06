import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/content_status.dart';
import 'package:mobile/models/posttest.dart';
import 'package:mobile/models/question.dart';
import 'package:mobile/repositories/posttest_repository.dart';

void main() {
  group('PosttestRepository & No-Key-Leak Validation Tests', () {
    late PosttestRepository repository;

    setUp(() {
      repository = PosttestRepository();
    });

    test('createPosttest melempar ArgumentError jika judul kosong', () async {
      final invalid = Posttest(
        id: 'post_01',
        classId: 'c1',
        meetingId: 'm1',
        title: '',
        duration: 20,
      );

      expect(
        () => repository.createPosttest(invalid),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createPosttest melempar ArgumentError jika durasi <= 0', () async {
      final invalid = Posttest(
        id: 'post_01',
        classId: 'c1',
        meetingId: 'm1',
        title: 'Post Test Evaluasi',
        duration: 0,
      );

      expect(
        () => repository.createPosttest(invalid),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createPosttest melempar ArgumentError jika max_attempts <= 0', () async {
      final invalid = Posttest(
        id: 'post_01',
        classId: 'c1',
        meetingId: 'm1',
        title: 'Post Test Evaluasi',
        duration: 20,
        maxAttempts: 0,
      );

      expect(
        () => repository.createPosttest(invalid),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('saveQuestionAndKey melempar ArgumentError jika opsi kosong atau index salah', () async {
      final invalidQ = Question(
        id: 'q1',
        text: 'Soal?',
        options: ['Opsi 1'], // Minimal 2 opsi
        points: 10,
      );

      expect(
        () => repository.saveQuestionAndKey(
          testId: 'post_01',
          question: invalidQ,
          correctOptionIndex: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );

      final validQ = Question(
        id: 'q1',
        text: 'Soal Sah?',
        options: ['A', 'B'],
        points: 10,
      );

      expect(
        () => repository.saveQuestionAndKey(
          testId: 'post_01',
          question: validQ,
          correctOptionIndex: 5, // Index di luar batas
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('NO-KEY-LEAK ENFORCEMENT: Dokumen soal client bebas dari kunci jawaban', () {
      final question = Question(
        id: 'q10',
        text: 'Manakah widget immutable?',
        options: ['StatefulWidget', 'StatelessWidget'],
        points: 20,
        tag: 'flutter',
      );

      final map = question.toMap();

      // Enforce: Kunci jawaban TIDAK PERNAH boleh ada di dokumen soal client
      expect(map.containsKey('correct_option'), isFalse);
      expect(map.containsKey('answer_key'), isFalse);
      expect(map.containsKey('explanation'), isFalse);
    });

    test('getPosttest mengembalikan null secara aman saat Firestore uninitialized', () async {
      final result = await repository.getPosttest('dummy_id');
      expect(result, isNull);
    });

    test('getQuestions mengembalikan list kosong secara aman saat Firestore uninitialized', () async {
      final result = await repository.getQuestions('dummy_id');
      expect(result, isEmpty);
    });

    test('updatePosttestStatus melempar StateError saat Firestore uninitialized', () async {
      expect(
        () => repository.updatePosttestStatus('p1', ContentStatus.published),
        throwsA(isA<StateError>()),
      );
    });
  });
}

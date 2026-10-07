import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/pretest.dart';
import 'package:mobile/models/question.dart';
import 'package:mobile/repositories/pretest_repository.dart';

void main() {
  group('PretestRepository & No-Key-Leak Validation Tests', () {
    late PretestRepository repository;

    setUp(() {
      repository = PretestRepository();
    });

    test('createPretest melempar ArgumentError jika judul kosong', () async {
      final invalidPretest = Pretest(
        id: 'p1',
        classId: 'c1',
        meetingId: 'm1',
        title: '',
        duration: 10,
        maxAttempts: 1,
      );

      expect(
        () => repository.createPretest(invalidPretest),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createPretest melempar ArgumentError jika durasi <= 0', () async {
      final invalidPretest = Pretest(
        id: 'p1',
        classId: 'c1',
        meetingId: 'm1',
        title: 'Pretest Sah',
        duration: 0,
        maxAttempts: 1,
      );

      expect(
        () => repository.createPretest(invalidPretest),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createPretest melempar ArgumentError jika max_attempts <= 0', () async {
      final invalidPretest = Pretest(
        id: 'p1',
        classId: 'c1',
        meetingId: 'm1',
        title: 'Pretest Sah',
        duration: 15,
        maxAttempts: 0,
      );

      expect(
        () => repository.createPretest(invalidPretest),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('saveQuestionAndKey melempar ArgumentError jika opsi kosong atau index salah', () async {
      final emptyOptionsQuestion = Question(
        id: 'q1',
        text: 'Soal tanpa opsi?',
        options: [],
      );

      expect(
        () => repository.saveQuestionAndKey(
          testId: 'p1',
          question: emptyOptionsQuestion,
          correctOptionIndex: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );

      final validQuestion = Question(
        id: 'q2',
        text: 'Soal dengan 2 opsi?',
        options: ['Opsi A', 'Opsi B'],
      );

      expect(
        () => repository.saveQuestionAndKey(
          testId: 'p1',
          question: validQuestion,
          correctOptionIndex: 5, // Out of bounds
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('NO-KEY-LEAK ENFORCEMENT: Dokumen soal client bebas dari kunci jawaban dan penjelasan', () {
      final question = Question(
        id: 'q_test_1',
        text: 'Berapa hasil 2 + 2?',
        type: QuestionType.multipleChoice,
        options: ['3', '4', '5'],
        points: 20,
        tag: 'math-basic',
      );

      final clientMap = question.toMap();

      // Cek bahwa TIDAK ADA informasi jawaban di data client
      expect(clientMap.containsKey('correct'), isFalse);
      expect(clientMap.containsKey('correct_option'), isFalse);
      expect(clientMap.containsKey('answer'), isFalse);
      expect(clientMap.containsKey('answer_key'), isFalse);
      expect(clientMap.containsKey('explanation'), isFalse);

      // Pastikan field publik lengkap
      expect(clientMap['text'], equals('Berapa hasil 2 + 2?'));
      expect(clientMap['options'], equals(['3', '4', '5']));
      expect(clientMap['points'], equals(20));
      expect(clientMap['tag'], equals('math-basic'));
    });

    test('getPretest mengembalikan null secara aman saat Firestore uninitialized', () async {
      final pretest = await repository.getPretest('p1');
      expect(pretest, isNull);
    });

    test('getQuestions mengembalikan list kosong secara aman saat Firestore uninitialized', () async {
      final questions = await repository.getQuestions('p1');
      expect(questions, isEmpty);
    });

    test('deleteQuestion melempar ArgumentError jika testId atau qid kosong', () async {
      expect(() => repository.deleteQuestion(testId: '', qid: 'q1'), throwsA(isA<ArgumentError>()));
      expect(() => repository.deleteQuestion(testId: 'p1', qid: ''), throwsA(isA<ArgumentError>()));
    });
  });
}

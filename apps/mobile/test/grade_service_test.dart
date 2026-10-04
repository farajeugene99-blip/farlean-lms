import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/grade_service.dart';

void main() {
  group('GradeService & GradeResult Tests', () {
    test('GradeResult.fromJson parsing handles normal and idempotent responses', () {
      final json = {
        'success': true,
        'attemptId': 'att_123',
        'score': 85.5,
        'pointsEarned': 17,
        'totalPoints': 20,
        'status': 'graded',
        'idempotent': true,
        'message': 'Hasil kuis telah dinilai sebelumnya.',
      };

      final result = GradeResult.fromJson(json);
      expect(result.success, isTrue);
      expect(result.attemptId, equals('att_123'));
      expect(result.score, equals(85.5));
      expect(result.pointsEarned, equals(17));
      expect(result.totalPoints, equals(20));
      expect(result.status, equals('graded'));
      expect(result.isIdempotent, isTrue);
    });

    test('submitAndGrade melempar GradeException jika attemptId kosong', () async {
      final service = GradeService();
      expect(
        () => service.submitAndGrade(''),
        throwsA(isA<GradeException>()),
      );
    });

    test('submitAndGrade melempar GradeException jika sesi belum login', () async {
      final service = GradeService();
      expect(
        () => service.submitAndGrade('attempt_01'),
        throwsA(isA<GradeException>()),
      );
    });
  });
}

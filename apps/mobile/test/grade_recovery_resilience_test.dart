import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/services/grade_service.dart';

void main() {
  group('GradeService Resilience & Recovery Unit Tests', () {
    test('1. Status 502/503/504 diklasifikasikan sebagai isUncertainResult = true tanpa FormatException', () async {
      for (final statusCode in [502, 503, 504]) {
        final mockClient = MockClient((request) async {
          return http.Response(
            '<html><body>$statusCode Gateway Error</body></html>',
            statusCode,
            headers: {'content-type': 'text/html'},
          );
        });

        final service = GradeService(
          httpClient: mockClient,
          tokenProvider: () async => 'mock_valid_token',
        );

        expect(
          () => service.submitAndGrade('att_test_123'),
          throwsA(
            isA<GradeException>()
                .having((e) => e.statusCode, 'statusCode', statusCode)
                .having((e) => e.isUncertainResult, 'isUncertainResult', isTrue)
                .having((e) => e.message, 'message', contains('$statusCode')),
          ),
        );
      }
    });

    test('2. Respon DEADLINE_PASSED dari server dipetakan ke GradeException.code', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"error": "Batas waktu pengerjaan (deadline) kuis telah berakhir.", "code": "DEADLINE_PASSED"}',
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = GradeService(
        httpClient: mockClient,
        tokenProvider: () async => 'mock_valid_token',
      );

      expect(
        () => service.submitAndGrade('att_test_expired'),
        throwsA(
          isA<GradeException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.code, 'code', 'DEADLINE_PASSED')
              .having((e) => e.isUncertainResult, 'isUncertainResult', isFalse),
        ),
      );
    });

    test('3. Respon sukses 200 menghasilkan GradeResult valid', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"success": true, "attemptId": "att_1", "score": 90.0, "pointsEarned": 90, "totalPoints": 100, "status": "graded", "idempotent": false}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = GradeService(
        httpClient: mockClient,
        tokenProvider: () async => 'mock_valid_token',
      );
      final result = await service.submitAndGrade('att_1');

      expect(result.success, isTrue);
      expect(result.score, 90.0);
      expect(result.status, 'graded');
    });

    test('4. http.ClientException dipetakan ke GradeException dengan isUncertainResult = true', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Failed to connect to host');
      });

      final service = GradeService(
        httpClient: mockClient,
        tokenProvider: () async => 'mock_valid_token',
      );

      expect(
        () => service.submitAndGrade('att_conn_err'),
        throwsA(
          isA<GradeException>()
              .having((e) => e.isUncertainResult, 'isUncertainResult', isTrue)
              .having((e) => e.message, 'message', contains('Failed to connect')),
        ),
      );
    });
  });
}

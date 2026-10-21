import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/presentation/ai/ai_tutor_screen.dart';
import 'package:mobile/services/ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiService 503 & Gateway Resilience Unit Tests (Masalah C)', () {
    test('1. AiException.toString() mengembalikan message bersih tanpa prefix nama kelas', () {
      const ex = AiException('Layanan AI tidak tersedia.', statusCode: 503, code: 'SERVICE_UNAVAILABLE');
      expect(ex.toString(), equals('Layanan AI tidak tersedia.'));
      expect(ex.toString().contains('AiException'), isFalse);
    });

    test('2. Response JSON 503 diekstrak menjadi AiException dengan pesan dari server', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"success": false, "error": "Layanan AI belum dikonfigurasi di server (GEMINI_API_KEY tidak ditemukan).", "message": "Layanan AI belum dikonfigurasi di server (GEMINI_API_KEY tidak ditemukan)."}',
          503,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AiService(
        httpClient: mockClient,
        tokenProvider: () async => 'mock_token',
      );

      expect(
        () => service.askTutor('Jelaskan OOP'),
        throwsA(
          isA<AiException>()
              .having((e) => e.statusCode, 'statusCode', 503)
              .having((e) => e.code, 'code', 'SERVICE_UNAVAILABLE')
              .having((e) => e.message, 'message', contains('Layanan AI belum dikonfigurasi')),
        ),
      );
    });

    test('3. Response HTML Gateway 502/503/504 ditangani secara aman tanpa FormatException crash', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '<html><body><h1>503 Service Unavailable</h1><p>Vercel Serverless Function Timeout</p></body></html>',
          503,
          headers: {'content-type': 'text/html'},
        );
      });

      final service = AiService(
        httpClient: mockClient,
        tokenProvider: () async => 'mock_token',
      );

      expect(
        () => service.askTutor('Jelaskan binary search'),
        throwsA(
          isA<AiException>()
              .having((e) => e.statusCode, 'statusCode', 503)
              .having((e) => e.code, 'code', 'SERVICE_UNAVAILABLE')
              .having((e) => e.message, 'message', contains('Layanan AI sedang tidak tersedia atau dalam pemeliharaan (503)')),
        ),
      );
    });

    test('4. Response 429 kuota habis menghasilkan AiException RATE_LIMIT_EXCEEDED', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"success": false, "error": "Batas kuota AI Tutor tercapai (10 pertanyaan / 15 menit)."}',
          429,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AiService(
        httpClient: mockClient,
        tokenProvider: () async => 'mock_token',
      );

      expect(
        () => service.askTutor('Tanya lagi'),
        throwsA(
          isA<AiException>()
              .having((e) => e.statusCode, 'statusCode', 429)
              .having((e) => e.code, 'code', 'RATE_LIMIT_EXCEEDED'),
        ),
      );
    });

    test('5. Response 429 dengan retryAfterSeconds dan resetAt diekstrak ke dalam AiException', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"success": false, "error": "Batas kuota harian tercapai.", "resetAt": 1761091200000, "retryAfterSeconds": 3600, "reason": "daily"}',
          429,
          headers: {'content-type': 'application/json', 'Retry-After': '3600'},
        );
      });

      final service = AiService(
        httpClient: mockClient,
        tokenProvider: () async => 'mock_token',
      );

      expect(
        () => service.askTutor('Tanya lagi'),
        throwsA(
          isA<AiException>()
              .having((e) => e.statusCode, 'statusCode', 429)
              .having((e) => e.retryAfterSeconds, 'retryAfterSeconds', 3600)
              .having((e) => e.resetAt, 'resetAt', 1761091200000)
              .having((e) => e.message, 'message', contains('Batas kuota harian tercapai.')),
        ),
      );
    });

    test('6. Response 200 dengan dual-tier quota diekstrak ke dalam AiResponse', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"success": true, "reply": "Halo!", "remainingQuota": 9, "remainingBurst": 9, "remainingDaily": 29}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AiService(
        httpClient: mockClient,
        tokenProvider: () async => 'mock_token',
      );

      final res = await service.askTutor('Halo');
      expect(res.success, isTrue);
      expect(res.content, equals('Halo!'));
      expect(res.remainingQuota, equals(9));
      expect(res.remainingBurst, equals(9));
      expect(res.remainingDaily, equals(29));
    });
  });

  group('AiTutorScreen 503 UI Error Rendering Tests (Masalah C)', () {
    testWidgets('Layar AI Tutor menampilkan gelembung pesan error ramah tanpa string "Bad state: "', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockClient = MockClient((request) async {
        return http.Response(
          '{"success": false, "error": "Layanan AI sedang dalam pemeliharaan server."}',
          503,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AiService(
        httpClient: mockClient,
        tokenProvider: () async => 'mock_token',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AiTutorScreen(aiService: service),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Bagaimana cara kerja caching?');
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pumpAndSettle();

      // Memastikan error dari 503 tampil bersih tanpa prefix teknis
      expect(find.text('Layanan AI sedang dalam pemeliharaan server.'), findsOneWidget);
      expect(find.textContaining('Bad state:'), findsNothing);
      expect(find.textContaining('StateError'), findsNothing);
      expect(find.textContaining('Exception:'), findsNothing);
    });
  });
}

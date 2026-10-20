import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/presentation/video/edit_video_dialog.dart';
import 'package:mobile/services/ai_service.dart';

class _FakeAiServiceForVideo extends AiService {
  @override
  Future<String> generateVideoDescription({
    required String title,
    String? courseName,
    String? meetingTitle,
    String? keywords,
    String? existingDescription,
  }) async {
    return 'Draf AI baru';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Video Editor Layout Overflow Tests (Masalah E)', () {
    testWidgets('EditVideoDialog does NOT throw 8.7 px RenderFlex overflow on narrow 320px viewport with textScale 1.5', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.5),
            ),
            child: Scaffold(
              body: Center(
                child: EditVideoDialog(
                  initialTitle: 'Judul Video Pembelajaran',
                  initialDescription: 'Deskripsi video awal',
                  aiService: _FakeAiServiceForVideo(),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verifikasi: Tidak ada RenderFlex overflow exception
      expect(tester.takeException(), isNull);
      expect(find.text('Edit Video Pembelajaran'), findsOneWidget);
      expect(find.text('Bantu Buat Draf (AI)'), findsOneWidget);
      expect(find.text('Deskripsi Video'), findsOneWidget);
    });
  });
}

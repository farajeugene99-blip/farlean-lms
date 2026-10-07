import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlutterQuill Localization Smoke Test', () {
    testWidgets('QuillSimpleToolbar renders without MissingFlutterQuillLocalizationException', (tester) async {
      final controller = QuillController.basic();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('id'),
            Locale('en'),
          ],
          locale: const Locale('id'),
          home: Scaffold(
            body: Column(
              children: [
                QuillSimpleToolbar(
                  controller: controller,
                  config: const QuillSimpleToolbarConfig(),
                ),
                Expanded(
                  child: QuillEditor.basic(
                    controller: controller,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Memastikan toolbar berhasil dirender tanpa melempar MissingFlutterQuillLocalizationException
      expect(find.byType(QuillSimpleToolbar), findsOneWidget);
      expect(find.byType(QuillEditor), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/presentation/common/startup_error_screen.dart';

void main() {
  group('StartupErrorScreen Localization Tests', () {
    testWidgets('1. StartupErrorScreen renders Indonesian UI by default or when locale is ID', (tester) async {
      await tester.pumpWidget(
        StartupErrorScreen(
          error: Exception('Simulated crash'),
          onRetry: () {},
          locale: const Locale('id'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Inisialisasi Firebase Gagal'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('2. StartupErrorScreen renders English UI when locale is EN', (tester) async {
      await tester.pumpWidget(
        StartupErrorScreen(
          error: Exception('Simulated crash'),
          onRetry: () {},
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Firebase Initialization Failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    test('3. ARB parity and accessors for StartupErrorScreen', () {
      final idL10n = lookupAppLocalizations(const Locale('id'));
      final enL10n = lookupAppLocalizations(const Locale('en'));

      expect(idL10n.startupFirebaseInitFailed, equals('Inisialisasi Firebase Gagal'));
      expect(enL10n.startupFirebaseInitFailed, equals('Firebase Initialization Failed'));

      expect(idL10n.labelRetry, equals('Coba Lagi'));
      expect(enL10n.labelRetry, equals('Retry'));
    });
  });
}

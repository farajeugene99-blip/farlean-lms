import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/presentation/main/dashboard_screen.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:mobile/services/class_provider.dart';
import 'package:provider/provider.dart';

import 'session_pipeline_test.dart';

void main() {
  group('DashboardScreen Error State Layout Tests', () {
    testWidgets('Renders profile error screen without BoxConstraints infinite width exception on narrow display (320px)', (tester) async {
      // Siapkan mock auth service dengan profile null
      final fakeUser = FakeUser(uid: 'err_user', email: 'err@farlean.edu');
      final mockAuth = MockAuthService(
        mockCurrentUser: fakeUser,
        mockProfileToReturn: null, // Memicu ProfileStatus.error
      );

      final authProvider = AuthProvider(authService: mockAuth);
      await authProvider.refreshSession();

      expect(authProvider.profileStatus, equals(ProfileStatus.error));

      // Set physical size sempit (misal mobile width 320 x 640)
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<ClassProvider>(create: (_) => ClassProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            locale: const Locale('id'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // PASTIKAN: Tidak ada BoxConstraints infinite width exception yang dilempar!
      expect(tester.takeException(), isNull);

      // Pastikan elemen UI error screen berhasil dirender
      expect(find.text('Profil Belum Berhasil Dimuat'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      // Uji tap tombol Coba Lagi
      await tester.tap(find.text('Coba Lagi'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}

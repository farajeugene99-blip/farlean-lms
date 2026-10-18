import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'app.dart';
import 'core/config/api_config.dart';
import 'core/config/firebase_config.dart';
import 'presentation/common/startup_error_screen.dart';
import 'services/locale_provider.dart';
import 'services/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    ApiConfig.validate();
    await FirebaseConfig.initialize();

    // Pre-load tema dan bahasa tersimpan sebelum runApp agar tidak terjadi white flash
    final themeProvider = ThemeProvider();
    await themeProvider.load();
    final localeProvider = LocaleProvider();
    await localeProvider.load();

    runApp(
      DevicePreview(
        enabled: kIsWeb && kDebugMode,
        builder: (context) => FarleanApp(
          themeProvider: themeProvider,
          localeProvider: localeProvider,
        ),
      ),
    );
  } catch (error, stackTrace) {
    debugPrint('🚨 [Fatal Startup] Firebase initialization failed: $error');
    runApp(
      StartupErrorScreen(
        error: error,
        stackTrace: stackTrace,
        onRetry: () => main(),
      ),
    );
  }
}
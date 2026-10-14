import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'app.dart';
import 'core/config/api_config.dart';
import 'core/config/firebase_config.dart';
import 'presentation/common/startup_error_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    ApiConfig.validate();
    await FirebaseConfig.initialize();
    runApp(
      DevicePreview(
        enabled: kIsWeb && kDebugMode,
        builder: (context) => const FarleanApp(),
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
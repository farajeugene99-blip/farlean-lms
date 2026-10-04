import 'package:flutter/material.dart';
import 'app.dart';
import 'core/config/firebase_config.dart';
import 'presentation/common/startup_error_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FirebaseConfig.initialize();
    runApp(const FarleanApp());
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

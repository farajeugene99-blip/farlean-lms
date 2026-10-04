import 'package:flutter/material.dart';
import 'app.dart';
import 'core/config/firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FirebaseConfig.initialize();
  } catch (e) {
    debugPrint('Firebase init note: $e');
  }
  runApp(const FarleanApp());
}



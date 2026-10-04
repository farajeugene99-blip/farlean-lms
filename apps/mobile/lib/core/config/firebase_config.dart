import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

class FirebaseConfig {
  static const int authEmulatorPort = 9099;
  static const int firestoreEmulatorPort = 8080;

  /// Inisialisasi Firebase dan arahkan ke Emulator jika dalam mode debug / testing.
  static Future<void> initialize({bool useEmulator = kDebugMode}) async {
    // Hindari inisialisasi ganda jika sudah aktif
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    if (useEmulator) {
      await setupEmulators();
    }
  }

  /// Menghubungkan client ke Firebase Emulator lokal
  static Future<void> setupEmulators() async {
    final String host = _resolveEmulatorHost();

    try {
      // 1. Auth Emulator
      await FirebaseAuth.instance.useAuthEmulator(host, authEmulatorPort);

      // 2. Firestore Emulator
      FirebaseFirestore.instance.useFirestoreEmulator(
        host,
        firestoreEmulatorPort,
        sslEnabled: false,
      );
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );

      debugPrint('🛡️ [FirebaseConfig] Terhubung ke Firebase Emulator di $host (Auth: $authEmulatorPort, Firestore: $firestoreEmulatorPort)');
    } catch (e) {
      debugPrint('⚠️ [FirebaseConfig] Gagal menghubungkan ke Emulator: $e');
    }
  }

  /// Android Emulator menggunakan loopback 10.0.2.2, sedangkan iOS/Desktop/Web menggunakan 127.0.0.1
  static String _resolveEmulatorHost() {
    if (kIsWeb) return '127.0.0.1';
    if (Platform.isAndroid) return '10.0.2.2';
    return '127.0.0.1';
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

class FirebaseConfig {
  static const int authEmulatorPort = 9099;
  static const int firestoreEmulatorPort = 8080;

  // Konfigurasi override dari --dart-define
  static const String _emulatorHostOverride = String.fromEnvironment('EMULATOR_HOST');
  static const bool _allowLiveProd = bool.fromEnvironment('ALLOW_PRODUCTION_MODE', defaultValue: false);

  /// Inisialisasi Firebase dan arahkan ke Emulator jika dalam mode debug / testing.
  static Future<void> initialize({bool useEmulator = kDebugMode}) async {
    // Penegakan Keputusan Phase 1: Emulator-only
    // Jangan izinkan akses live production tanpa flag eksplisit
    if (!useEmulator && !_allowLiveProd) {
      throw StateError(
        'Safety Guard: Akses ke Firebase Production diblokir pada Phase 1 & 2. '
        'Gunakan Firebase Emulator lokal atau sertakan flag --dart-define=ALLOW_PRODUCTION_MODE=true jika disengaja.',
      );
    }

    // 1. Inisialisasi Core (lempar exception jika platform tidak didukung atau config salah)
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // 2. Setup Emulator terisolasi (decoupled agar kegagalan hook emulator tidak menjatuhkan core)
    if (useEmulator) {
      await setupEmulators();
    }
  }

  /// Menghubungkan client ke Firebase Emulator lokal dengan penanganan terisolasi
  static Future<void> setupEmulators() async {
    final String host = resolveEmulatorHost();

    // A. Auth Emulator
    try {
      // Di Flutter Web, useAuthEmulator tidak mengembalikan Future
      await FirebaseAuth.instance.useAuthEmulator(host, authEmulatorPort);
      debugPrint('🛡️️ [FirebaseConfig] Auth Emulator aktif di $host:$authEmulatorPort');
    } catch (e) {
      debugPrint('🚨 [FirebaseConfig] Gagal hook Auth emulator: $e');
    }

    // B. Firestore Emulator
    try {
      FirebaseFirestore.instance.useFirestoreEmulator(
        host,
        firestoreEmulatorPort,
        sslEnabled: false,
      );
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
      debugPrint('🛡️ [FirebaseConfig] Firestore Emulator aktif di $host:$firestoreEmulatorPort');
    } catch (e) {
      debugPrint('🚨 [FirebaseConfig] Gagal hook Firestore emulator: $e');
    }
  }

  /// Menyelesaikan host emulator aman lintas platform (Web, Android, iOS, Desktop)
  static String resolveEmulatorHost() {
    if (_emulatorHostOverride.isNotEmpty) {
      return _emulatorHostOverride.trim();
    }
    // Wajib cek kIsWeb terlebih dahulu sebelum mengecek platform OS
    if (kIsWeb) return '127.0.0.1';
    
    // Gunakan defaultTargetPlatform agar aman tanpa import dart:io
    if (defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    }
    return '127.0.0.1';
  }
}
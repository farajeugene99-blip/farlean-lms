import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static const int backendPort = 3001;
  static const String productionBaseUrl = 'https://farlean-lms-backend.vercel.app';

  /// Memeriksa apakah compile-time environment secara eksplisit meminta mode development
  static bool get isExplicitDevelopment {
    const appEnv = String.fromEnvironment('APP_ENV', defaultValue: '');
    const useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);
    return appEnv == 'development' || useEmulator;
  }

  /// Mendapatkan Base URL backend Vercel / local serverless dev
  /// Default utama adalah Vercel HTTPS Production agar perangkat Android fisik
  /// tidak mencoba cleartext HTTP ke loopback/IP lokal saat debugging normal.
  /// Mendukung override melalui compile-time environment: --dart-define=API_BASE_URL=https://...
  static String get baseUrl {
    const definedUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    const appEnv = String.fromEnvironment('APP_ENV', defaultValue: '');
    const useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);

    // Penegakan Keamanan Release: Dilarang fallback ke loopback/cleartext HTTP di mode produksi
    if (kReleaseMode) {
      if (appEnv == 'development' || useEmulator) {
        throw StateError('Produksi Farlean LMS dilarang menggunakan konfigurasi development atau emulator.');
      }
      if (definedUrl.isNotEmpty) {
        if (!definedUrl.startsWith('https://')) {
          throw StateError('Produksi Farlean LMS mewajibkan API_BASE_URL menggunakan protokol HTTPS yang aman.');
        }
        return definedUrl;
      }
      return productionBaseUrl;
    }

    // Di Non-Release Mode (Debug / Profile / Test):
    if (definedUrl.isNotEmpty) {
      return definedUrl;
    }

    // Hanya fallback ke server lokal jika environment development diminta secara eksplisit
    if (isExplicitDevelopment) {
      if (kIsWeb) return 'http://127.0.0.1:$backendPort';
      if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:$backendPort';
      return 'http://127.0.0.1:$backendPort';
    }

    // Default utama: Backend Vercel Production HTTPS
    return productionBaseUrl;
  }

  /// Memvalidasi konfigurasi URL saat startup untuk memastikan kebijakan fail-closed
  /// melempar StateError segera jika konfigurasi rilis tidak lengkap atau tidak aman.
  static void validate() {
    final _ = baseUrl;
  }

  static String get bootstrapUrl => '$baseUrl/api/bootstrap';
  static String get joinClassUrl => '$baseUrl/api/join-class';
  static String get createClassUrl => '$baseUrl/api/create-class';
  static String get myClassesUrl => '$baseUrl/api/my-classes';
  static String get classMembersUrl => '$baseUrl/api/class-members';
  static String get classPurgeUrl => '$baseUrl/api/class-purge';
  static String get saveQuestionUrl => '$baseUrl/api/save-question';
  static String get deleteQuestionUrl => '$baseUrl/api/delete-question';
  static String get publishTestUrl => '$baseUrl/api/publish-test';
  static String get publishMeetingsUrl => '$baseUrl/api/publish-meetings';
  static String get gradeUrl => '$baseUrl/api/grade';
  static String get discussionThreadUrl => '$baseUrl/api/discussion-thread';
  static String get discussionReplyUrl => '$baseUrl/api/discussion-reply';
}

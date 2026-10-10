import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static const int backendPort = 3001;

  /// Mendapatkan Base URL backend Vercel / local serverless dev
  /// Mendukung override melalui compile-time environment: --dart-define=API_BASE_URL=https://...
  static String get baseUrl {
    const definedUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (definedUrl.isNotEmpty) {
      if (kReleaseMode && !definedUrl.startsWith('https://')) {
        throw StateError('Produksi Farlean LMS mewajibkan API_BASE_URL menggunakan protokol HTTPS yang aman.');
      }
      return definedUrl;
    }

    if (kIsWeb) return 'http://127.0.0.1:$backendPort';
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:$backendPort';
    return 'http://127.0.0.1:$backendPort';
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

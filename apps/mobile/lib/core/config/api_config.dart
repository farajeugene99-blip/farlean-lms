import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static const int backendPort = 3000;

  /// Mendapatkan Base URL backend Vercel / local serverless dev
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:$backendPort';
    if (Platform.isAndroid) return 'http://10.0.2.2:$backendPort';
    return 'http://127.0.0.1:$backendPort';
  }

  static String get bootstrapUrl => '$baseUrl/api/bootstrap';
  static String get joinClassUrl => '$baseUrl/api/join-class';
}

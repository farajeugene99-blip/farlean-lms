import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';

class GradeResult {
  final bool success;
  final String attemptId;
  final double score;
  final int pointsEarned;
  final int totalPoints;
  final String status;
  final String message;
  final bool isIdempotent;

  const GradeResult({
    required this.success,
    required this.attemptId,
    required this.score,
    required this.pointsEarned,
    required this.totalPoints,
    required this.status,
    required this.message,
    this.isIdempotent = false,
  });

  factory GradeResult.fromJson(Map<String, dynamic> json) {
    return GradeResult(
      success: json['success'] as bool? ?? false,
      attemptId: json['attemptId'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      pointsEarned: (json['pointsEarned'] as num?)?.toInt() ?? 0,
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'graded',
      message: json['message'] as String? ?? 'Kuis berhasil dinilai.',
      isIdempotent: json['idempotent'] as bool? ?? false,
    );
  }
}

class GradeException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final bool isUncertainResult;

  const GradeException(
    this.message, {
    this.statusCode,
    this.code,
    this.isUncertainResult = false,
  });

  @override
  String toString() => message;
}

class GradeService {
  final FirebaseAuth? _auth;
  final http.Client _httpClient;
  final Future<String?> Function()? _tokenProvider;

  GradeService({
    FirebaseAuth? auth,
    http.Client? httpClient,
    Future<String?> Function()? tokenProvider,
  })  : _auth = auth ?? (Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null),
        _httpClient = httpClient ?? http.Client(),
        _tokenProvider = tokenProvider;

  /// Mengirim attempt ke backend serverless /api/grade untuk dinilai secara transaksional
  Future<GradeResult> submitAndGrade(
    String attemptId, {
    bool autoSubmit = false,
    String? reason,
  }) async {
    final cleanAttemptId = attemptId.trim();
    if (cleanAttemptId.isEmpty) {
      throw const GradeException('attemptId tidak boleh kosong.');
    }

    final String? token;
    if (_tokenProvider != null) {
      token = await _tokenProvider();
    } else {
      final user = _auth?.currentUser;
      if (user == null) {
        throw const GradeException('Sesi Anda belum aktif. Harap masuk terlebih dahulu.');
      }
      token = await user.getIdToken(true);
    }

    if (token == null) {
      throw const GradeException('Gagal memperoleh token autentikasi valid.');
    }

    try {
      final uri = Uri.parse(ApiConfig.gradeUrl);
      final response = await _httpClient
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'attemptId': cleanAttemptId,
              if (autoSubmit) 'autoSubmit': true,
              if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
            }),
          )
          .timeout(const Duration(seconds: 35));

      // 1. Tangani status server perantara (502, 503, 504) sebelum jsonDecode untuk mencegah FormatException
      if (response.statusCode == 502 || response.statusCode == 503 || response.statusCode == 504) {
        throw GradeException(
          'Server perantara mengalami kendala (HTTP ${response.statusCode}).',
          statusCode: response.statusCode,
          isUncertainResult: true,
        );
      }

      // 2. Dekode JSON secara defensif
      Map<String, dynamic> data = const {};
      try {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {
        if (response.statusCode >= 500) {
          throw GradeException(
            'Server penilaian merespons dengan kendala internal (HTTP ${response.statusCode}).',
            statusCode: response.statusCode,
            isUncertainResult: true,
          );
        }
      }

      if (response.statusCode == 200 && data['success'] == true) {
        return GradeResult.fromJson(data);
      } else {
        final errorMsg = data['error'] as String? ?? 'Gagal menghitung nilai kuis (HTTP ${response.statusCode}).';
        final errorCode = data['code'] as String?;
        throw GradeException(
          errorMsg,
          statusCode: response.statusCode,
          code: errorCode,
          isUncertainResult: response.statusCode >= 500,
        );
      }
    } on TimeoutException {
      throw const GradeException(
        'Waktu tunggu koneksi penilaian habis (timeout).',
        isUncertainResult: true,
      );
    } on http.ClientException catch (e) {
      throw GradeException(
        'Gagal menghubungi server penilaian: ${e.message}',
        isUncertainResult: true,
      );
    } catch (e) {
      if (e is GradeException) rethrow;
      throw GradeException(
        'Koneksi ke server penilaian bermasalah: $e',
        isUncertainResult: true,
      );
    }
  }
}

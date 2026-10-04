import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
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

  const GradeException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class GradeService {
  final FirebaseAuth? _injectedAuth;
  final http.Client _httpClient;

  GradeService({
    FirebaseAuth? auth,
    http.Client? httpClient,
  })  : _injectedAuth = auth,
        _httpClient = httpClient ?? http.Client();

  FirebaseAuth? get _auth {
    if (_injectedAuth != null) return _injectedAuth;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  /// Mengirim attempt ke backend serverless /api/grade untuk dinilai secara transaksional
  Future<GradeResult> submitAndGrade(String attemptId) async {
    final cleanAttemptId = attemptId.trim();
    if (cleanAttemptId.isEmpty) {
      throw const GradeException('attemptId tidak boleh kosong.');
    }

    final user = _auth?.currentUser;
    if (user == null) {
      throw const GradeException('Sesi Anda belum aktif. Harap masuk terlebih dahulu.');
    }

    final token = await user.getIdToken(true);
    if (token == null) {
      throw const GradeException('Gagal memperoleh token autentikasi valid.');
    }

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/grade');
      final response = await _httpClient.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'attemptId': cleanAttemptId,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        return GradeResult.fromJson(data);
      } else {
        final errorMsg = data['error'] as String? ?? 'Gagal menghitung nilai kuis.';
        throw GradeException(errorMsg, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is GradeException) rethrow;
      throw GradeException('Koneksi ke server penilaian bermasalah: $e');
    }
  }
}

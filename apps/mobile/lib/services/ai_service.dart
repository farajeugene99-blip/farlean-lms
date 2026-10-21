import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';

class AiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final bool isExamLocked;
  final int? resetAt;
  final int? retryAfterSeconds;

  const AiException(
    this.message, {
    this.statusCode,
    this.code,
    this.isExamLocked = false,
    this.resetAt,
    this.retryAfterSeconds,
  });

  @override
  String toString() => message;
}

class AiResponse {
  final bool success;
  final String content;
  final int? remainingQuota;
  final int? remainingBurst;
  final int? remainingDaily;
  final bool isExamLocked;

  const AiResponse({
    required this.success,
    required this.content,
    this.remainingQuota,
    this.remainingBurst,
    this.remainingDaily,
    this.isExamLocked = false,
  });
}

class AiService {
  final FirebaseAuth? _auth;
  final http.Client _httpClient;
  final Future<String?> Function()? tokenProvider;

  AiService({
    FirebaseAuth? auth,
    http.Client? httpClient,
    this.tokenProvider,
  })  : _auth = auth ?? (Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null),
        _httpClient = httpClient ?? http.Client();

  Future<String?> _getToken() async {
    if (tokenProvider != null) {
      return tokenProvider!();
    }
    final user = _auth?.currentUser;
    if (user == null) return null;
    return user.getIdToken();
  }

  Map<String, dynamic>? _tryParseJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  /// Meminta bimbingan dari AI Tutor Pintar (Mahasiswa & Staf)
  Future<AiResponse> askTutor(
    String prompt, {
    String? classId,
    String? meetingId,
    String? materiId,
  }) async {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty) {
      throw const AiException('Pertanyaan tidak boleh kosong.', statusCode: 400);
    }

    final token = await _getToken();
    if (token == null) {
      throw const AiException('Sesi pengguna belum aktif. Silakan masuk terlebih dahulu.', statusCode: 401);
    }

    try {
      final payload = <String, dynamic>{
        'action': 'tutor',
        'prompt': cleanPrompt,
      };
      if (classId != null && classId.trim().isNotEmpty) {
        payload['classId'] = classId.trim();
      }
      if (meetingId != null && meetingId.trim().isNotEmpty) {
        payload['meetingId'] = meetingId.trim();
      }
      if (materiId != null && materiId.trim().isNotEmpty) {
        payload['materiId'] = materiId.trim();
      }

      final response = await _httpClient.post(
        Uri.parse(ApiConfig.aiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 25));

      final data = _tryParseJson(response.body);

      if (response.statusCode == 200 && data != null && data['success'] == true) {
        return AiResponse(
          success: true,
          content: data['reply'] as String? ?? '',
          remainingQuota: (data['remainingQuota'] as num?)?.toInt(),
          remainingBurst: (data['remainingBurst'] as num?)?.toInt(),
          remainingDaily: (data['remainingDaily'] as num?)?.toInt(),
        );
      }

      if (response.statusCode == 403 && data != null && data['isExamLocked'] == true) {
        return AiResponse(
          success: false,
          content: (data['error'] ?? data['message']) as String? ?? 'Fitur AI Tutor dinonaktifkan sementara saat Anda sedang menempuh sesi kuis/ujian.',
          isExamLocked: true,
        );
      }

      if (response.statusCode == 503 || response.statusCode == 502 || response.statusCode == 504) {
        final serverMsg = data != null ? (data['error'] ?? data['message']) : null;
        throw AiException(
          serverMsg?.toString() ?? 'Layanan AI sedang tidak tersedia atau dalam pemeliharaan (503). Harap coba beberapa saat lagi.',
          statusCode: response.statusCode,
          code: 'SERVICE_UNAVAILABLE',
        );
      }

      if (response.statusCode == 429) {
        final serverMsg = data != null ? (data['error'] ?? data['message']) : null;
        final resetAt = (data?['resetAt'] as num?)?.toInt();
        final retryAfterSeconds = (data?['retryAfterSeconds'] as num?)?.toInt();
        throw AiException(
          serverMsg?.toString() ?? 'Batas kuota AI tercapai. Harap tunggu beberapa saat sebelum mencoba kembali.',
          statusCode: 429,
          code: 'RATE_LIMIT_EXCEEDED',
          resetAt: resetAt,
          retryAfterSeconds: retryAfterSeconds,
        );
      }

      final errorMsg = data != null
          ? (data['error'] ?? data['message'] ?? 'Gagal menghubungi AI Tutor (${response.statusCode})')
          : 'Gagal menghubungi server AI (${response.statusCode})';
      throw AiException(errorMsg.toString(), statusCode: response.statusCode);
    } catch (e) {
      if (e is AiException) rethrow;
      debugPrint('AI Tutor error: $e');
      throw AiException(e.toString().replaceFirst('Exception: ', '').replaceFirst('Bad state: ', ''));
    }
  }

  /// Membuat draf deskripsi video pembelajaran (Dosen & Admin)
  Future<String> generateVideoDescription({
    required String title,
    String? courseName,
    String? meetingTitle,
    String? keywords,
    String? existingDescription,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw const AiException('Sesi pengguna belum aktif. Silakan masuk terlebih dahulu.', statusCode: 401);
    }

    try {
      final response = await _httpClient.post(
        Uri.parse(ApiConfig.aiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'action': 'video-description',
          'title': title,
          if (courseName != null && courseName.isNotEmpty) 'courseName': courseName,
          if (meetingTitle != null && meetingTitle.isNotEmpty) 'meetingTitle': meetingTitle,
          if (keywords != null && keywords.isNotEmpty) 'keywords': keywords,
          if (existingDescription != null && existingDescription.isNotEmpty) 'existingDescription': existingDescription,
        }),
      ).timeout(const Duration(seconds: 25));

      final data = _tryParseJson(response.body);

      if (response.statusCode == 200 && data != null && data['success'] == true) {
        return data['draftDescription'] as String? ?? '';
      }

      if (response.statusCode == 503 || response.statusCode == 502 || response.statusCode == 504) {
        final serverMsg = data != null ? (data['error'] ?? data['message']) : null;
        throw AiException(
          serverMsg?.toString() ?? 'Layanan AI Generator sedang tidak tersedia (503). Silakan coba lagi nanti.',
          statusCode: response.statusCode,
          code: 'SERVICE_UNAVAILABLE',
        );
      }

      if (response.statusCode == 429) {
        final serverMsg = data != null ? (data['error'] ?? data['message']) : null;
        final resetAt = (data?['resetAt'] as num?)?.toInt();
        final retryAfterSeconds = (data?['retryAfterSeconds'] as num?)?.toInt();
        throw AiException(
          serverMsg?.toString() ?? 'Batas penggunaan AI Video Generator tercapai. Silakan coba lagi nanti.',
          statusCode: 429,
          code: 'RATE_LIMIT_EXCEEDED',
          resetAt: resetAt,
          retryAfterSeconds: retryAfterSeconds,
        );
      }

      final errorMsg = data != null
          ? (data['error'] ?? data['message'] ?? 'Gagal membuat draf video (${response.statusCode})')
          : 'Gagal menghubungi server AI (${response.statusCode})';
      throw AiException(errorMsg.toString(), statusCode: response.statusCode);
    } catch (e) {
      if (e is AiException) rethrow;
      debugPrint('AI Video draft error: $e');
      throw AiException(e.toString().replaceFirst('Exception: ', '').replaceFirst('Bad state: ', ''));
    }
  }
}

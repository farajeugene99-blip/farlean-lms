import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';

class AiResponse {
  final bool success;
  final String content;
  final int? remainingQuota;
  final bool isExamLocked;

  const AiResponse({
    required this.success,
    required this.content,
    this.remainingQuota,
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

  /// Meminta bimbingan dari AI Tutor Pintar (Mahasiswa & Staf)
  Future<AiResponse> askTutor(String prompt) async {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty) {
      throw ArgumentError('Pertanyaan tidak boleh kosong.');
    }

    final token = await _getToken();
    if (token == null) {
      throw StateError('Sesi pengguna belum aktif.');
    }

    try {
      final response = await _httpClient.post(
        Uri.parse(ApiConfig.aiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'action': 'tutor',
          'prompt': cleanPrompt,
        }),
      ).timeout(const Duration(seconds: 25));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        return AiResponse(
          success: true,
          content: data['reply'] as String? ?? '',
          remainingQuota: (data['remainingQuota'] as num?)?.toInt(),
        );
      } else if (response.statusCode == 403 && data['isExamLocked'] == true) {
        return AiResponse(
          success: false,
          content: data['error'] as String? ?? 'AI dinonaktifkan saat ujian.',
          isExamLocked: true,
        );
      } else {
        final errorMsg = data['error'] as String? ?? 'Gagal menghubungi AI Tutor (${response.statusCode})';
        throw StateError(errorMsg);
      }
    } catch (e) {
      debugPrint('AI Tutor error: $e');
      rethrow;
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
      throw StateError('Sesi pengguna belum aktif.');
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

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        return data['draftDescription'] as String? ?? '';
      } else {
        final errorMsg = data['error'] as String? ?? 'Gagal membuat draf video (${response.statusCode})';
        throw StateError(errorMsg);
      }
    } catch (e) {
      debugPrint('AI Video draft error: $e');
      rethrow;
    }
  }
}

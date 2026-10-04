import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../models/class_member.dart';

class JoinClassResult {
  final bool success;
  final String classId;
  final String className;
  final MemberStatus status;
  final String message;

  const JoinClassResult({
    required this.success,
    required this.classId,
    required this.className,
    required this.status,
    required this.message,
  });

  bool get isActive => status == MemberStatus.active;
  bool get isPending => status == MemberStatus.pending;
}

class JoinClassException implements Exception {
  final String message;
  final int? statusCode;

  const JoinClassException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class JoinClassService {
  final FirebaseAuth? _auth;
  final http.Client _httpClient;

  JoinClassService({
    FirebaseAuth? auth,
    http.Client? httpClient,
  })  : _auth = auth ?? (Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null),
        _httpClient = httpClient ?? http.Client();

  /// Memvalidasi format kode kelas: 6-12 karakter alfanumerik kapital
  static String? validateCodeFormat(String? code) {
    if (code == null || code.trim().isEmpty) {
      return 'Kode kelas wajib diisi.';
    }
    final clean = code.trim().toUpperCase();
    if (clean.length < 6 || clean.length > 12) {
      return 'Panjang kode kelas harus antara 6 hingga 12 karakter.';
    }
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(clean)) {
      return 'Kode kelas hanya boleh mengandung huruf kapital dan angka.';
    }
    return null;
  }

  /// Bergabung ke dalam kelas melalui endpoint server-side terlindungi
  Future<JoinClassResult> joinClass(String rawCode) async {
    final validationError = validateCodeFormat(rawCode);
    if (validationError != null) {
      throw JoinClassException(validationError);
    }

    final normalizedCode = rawCode.trim().toUpperCase();
    final user = _auth?.currentUser;
    if (user == null) {
      throw const JoinClassException('Sesi Anda belum aktif. Silakan masuk terlebih dahulu.');
    }

    // Ambil fresh token untuk memastikan klaim dan status email terbarui
    final token = await user.getIdToken(true);
    if (token == null) {
      throw const JoinClassException('Gagal memperoleh token autentikasi yang valid.');
    }

    try {
      final uri = Uri.parse(ApiConfig.joinClassUrl);
      final response = await _httpClient.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'classCode': normalizedCode,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        return JoinClassResult(
          success: true,
          classId: data['classId'] as String? ?? '',
          className: data['className'] as String? ?? 'Kelas',
          status: MemberStatus.fromString(data['status'] as String?),
          message: data['message'] as String? ?? 'Berhasil memproses permintaan.',
        );
      } else {
        final errorMsg = data['error'] as String? ?? 'Gagal bergabung ke dalam kelas.';
        throw JoinClassException(errorMsg, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is JoinClassException) rethrow;
      throw JoinClassException('Koneksi ke server bermasalah: $e');
    }
  }
}

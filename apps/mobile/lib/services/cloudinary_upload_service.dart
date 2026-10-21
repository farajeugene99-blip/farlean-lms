import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';

class CloudinaryUploadException implements Exception {
  final String message;
  final int? statusCode;

  const CloudinaryUploadException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class CloudinaryUploadResult {
  final String secureUrl;
  final String fileName;
  final int sizeBytes;
  final String? format;
  final String? publicId;

  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.fileName,
    required this.sizeBytes,
    this.format,
    this.publicId,
  });

  /// Menyusun URL yang diperkaya metadata nama dan ukuran berkas (aman untuk `List<String>` di Firestore)
  String toEncodedUrl() {
    final cleanName = Uri.encodeComponent(fileName);
    return '$secureUrl#name=$cleanName&size=$sizeBytes';
  }

  /// Mem-parsing URL yang mungkin mengandung fragment metadata #name=...&size=...
  static Map<String, dynamic> parseEncodedUrl(String rawUrl) {
    try {
      final uri = Uri.parse(rawUrl);
      String originalUrl = rawUrl;
      String? parsedName;
      int? parsedSize;

      if (uri.hasFragment && uri.fragment.isNotEmpty) {
        originalUrl = rawUrl.split('#').first;
        final params = Uri.splitQueryString(uri.fragment);
        if (params.containsKey('name')) {
          parsedName = Uri.decodeComponent(params['name']!);
        }
        if (params.containsKey('size')) {
          parsedSize = int.tryParse(params['size']!);
        }
      }

      if (parsedName == null || parsedName.isEmpty) {
        final segments = uri.pathSegments;
        if (segments.isNotEmpty) {
          parsedName = Uri.decodeComponent(segments.last);
        } else {
          parsedName = 'lampiran';
        }
      }

      return {
        'url': originalUrl,
        'fileName': parsedName,
        'sizeBytes': parsedSize,
      };
    } catch (_) {
      return {
        'url': rawUrl,
        'fileName': 'lampiran',
        'sizeBytes': null,
      };
    }
  }
}

class CloudinaryUploadService {
  final FirebaseAuth? _auth;
  final http.Client _httpClient;
  final Future<String?> Function()? tokenProvider;

  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB limit

  CloudinaryUploadService({
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

  /// Memilih file dari perangkat fisik / web
  Future<PlatformFile?> pickDocumentFile({List<String>? allowedExtensions}) async {
    final extensions = allowedExtensions ?? ['pdf', 'doc', 'docx', 'zip'];
    return FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: extensions,
    );
  }

  /// Memilih gambar dari perangkat fisik / web
  Future<PlatformFile?> pickImageFile() async {
    return FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
  }

  /// Memvalidasi berkas sebelum diunggah
  Future<int> validateFile(PlatformFile file, {List<String>? allowedExtensions}) async {
    final size = file.lengthSync() ?? (await file.length()) ?? 0;
    if (size <= 0) {
      throw const CloudinaryUploadException('Berkas kosong tidak dapat diunggah.');
    }
    if (size > maxFileSizeBytes) {
      throw const CloudinaryUploadException('Ukuran berkas melebihi batas maksimal 10 MB.');
    }

    if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
      final ext = file.extension?.toLowerCase().replaceAll('.', '') ?? '';
      final isAllowed = allowedExtensions.any((e) => e.toLowerCase().replaceAll('.', '') == ext);
      if (!isAllowed) {
        throw CloudinaryUploadException(
          'Format berkas .$ext tidak didukung. Format yang diizinkan: ${allowedExtensions.join(', ')}.',
        );
      }
    }

    return size;
  }

  /// Mengunggah berkas ke Cloudinary via server signature /api/upload-sign
  Future<CloudinaryUploadResult> uploadFile({
    required PlatformFile file,
    required String folderType, // 'assignment_instructions', 'materials', 'images', 'assignments'
    String? classId,
    String? assignmentId,
    List<String>? allowedExtensions,
  }) async {
    final resolvedSize = await validateFile(file, allowedExtensions: allowedExtensions);

    final token = await _getToken();
    if (token == null) {
      throw const CloudinaryUploadException(
        'Sesi pengguna belum aktif. Silakan masuk terlebih dahulu.',
        statusCode: 401,
      );
    }

    // 1. Meminta Signature dari Backend
    Map<String, dynamic> signData;
    try {
      final signPayload = <String, dynamic>{
        'folderType': folderType,
        if (classId != null && classId.trim().isNotEmpty) 'classId': classId.trim(),
        if (assignmentId != null && assignmentId.trim().isNotEmpty) 'assignmentId': assignmentId.trim(),
      };

      final signRes = await _httpClient.post(
        Uri.parse(ApiConfig.uploadSignUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(signPayload),
      ).timeout(const Duration(seconds: 20));

      final bodyJson = jsonDecode(signRes.body);
      if (signRes.statusCode != 200 || bodyJson == null || bodyJson['success'] != true) {
        final errorMsg = bodyJson != null ? (bodyJson['error'] ?? bodyJson['message']) : null;
        throw CloudinaryUploadException(
          errorMsg?.toString() ?? 'Gagal mendapatkan izin tanda tangan unggahan (${signRes.statusCode}).',
          statusCode: signRes.statusCode,
        );
      }
      signData = bodyJson as Map<String, dynamic>;
    } catch (e) {
      if (e is CloudinaryUploadException) rethrow;
      throw CloudinaryUploadException('Gagal menghubungi server otentikasi unggahan: $e');
    }

    final uploadUrl = signData['uploadUrl'] as String? ?? 'https://api.cloudinary.com/v1_1/${signData['cloudName']}/auto/upload';
    final apiKey = signData['apiKey'] as String;
    final timestamp = signData['timestamp'].toString();
    final signature = signData['signature'] as String;
    final folder = signData['folder'] as String;

    // 2. Upload Multipart ke Cloudinary dengan Fallback Path -> Bytes
    try {
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.fields['api_key'] = apiKey;
      request.fields['timestamp'] = timestamp;
      request.fields['signature'] = signature;
      request.fields['folder'] = folder;

      final safeName = file.name.replaceAll(RegExp(r'[^\w\.\-\s]'), '_');

      // Penanganan PlatformFile.path null (Google Drive, Web, dll.)
      if (file.path != null && file.path!.isNotEmpty && !kIsWeb) {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          file.path!,
          filename: safeName,
        ));
      } else {
        final bytes = await file.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: safeName,
        ));
      }

      final streamedResponse = await _httpClient.send(request).timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      final uploadJson = jsonDecode(response.body);
      if (response.statusCode != 200 || uploadJson == null || uploadJson['secure_url'] == null) {
        final errorMsg = uploadJson?['error']?['message'] ?? 'Gagal mengunggah berkas ke penyimpanan Cloudinary (${response.statusCode}).';
        throw CloudinaryUploadException(errorMsg.toString(), statusCode: response.statusCode);
      }

      return CloudinaryUploadResult(
        secureUrl: uploadJson['secure_url'] as String,
        fileName: safeName,
        sizeBytes: (uploadJson['bytes'] as num?)?.toInt() ?? resolvedSize,
        format: uploadJson['format'] as String?,
        publicId: uploadJson['public_id'] as String?,
      );
    } catch (e) {
      if (e is CloudinaryUploadException) rethrow;
      throw CloudinaryUploadException('Gagal mengunggah berkas: $e');
    }
  }
}

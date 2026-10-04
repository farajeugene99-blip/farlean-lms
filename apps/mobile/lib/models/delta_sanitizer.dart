import 'dart:convert';

class DeltaSanitizationException implements Exception {
  final String message;
  const DeltaSanitizationException(this.message);

  @override
  String toString() => 'DeltaSanitizationException: $message';
}

class DeltaSanitizer {
  static const int maxDeltaSizeBytes = 512 * 1024; // 500 KB limit per materi

  /// Memvalidasi struktur Delta JSON sebelum disimpan atau di-render.
  /// Menolak:
  /// - Ukuran melebihi 500KB
  /// - Link berbahaya (javascript:, data:, vbscript:)
  /// - Gambar inline base64 (data:image/...)
  /// Mengembalikan pesan error jika tidak valid, atau null jika lolos sanitasi.
  static String? validate(dynamic delta) {
    if (delta == null) {
      return 'Konten Delta tidak boleh null.';
    }

    // 1. Validasi Ukuran Dokumen
    final rawJson = delta is String ? delta : jsonEncode(delta);
    if (utf8.encode(rawJson).length > maxDeltaSizeBytes) {
      return 'Ukuran konten materi melebihi batas maksimal 500KB.';
    }

    dynamic decoded = delta;
    if (delta is String) {
      try {
        decoded = jsonDecode(delta);
      } catch (e) {
        return 'Format JSON Delta tidak valid: $e';
      }
    }

    List ops;
    if (decoded is List) {
      ops = decoded;
    } else if (decoded is Map && decoded['ops'] is List) {
      ops = decoded['ops'] as List;
    } else {
      return 'Struktur Delta harus berupa array operasi (List of Ops).';
    }

    // 2. Periksa setiap operasi insert & attributes
    for (int i = 0; i < ops.length; i++) {
      final op = ops[i];
      if (op is! Map) {
        return 'Operasi Delta pada indeks $i tidak valid.';
      }

      final insert = op['insert'];
      if (insert == null) {
        return 'Operasi Delta pada indeks $i tidak memiliki field insert.';
      }

      // Validasi Embed Object (misal Image, Video)
      if (insert is Map) {
        // Cek gambar
        final image = insert['image'];
        if (image != null) {
          if (image is! String) {
            return 'URL gambar pada indeks $i harus berupa string.';
          }
          final trimmed = image.trim().toLowerCase();
          if (trimmed.startsWith('data:image')) {
            return 'Gambar base64 inline dilarang. Harap gunakan URL gambar Cloudinary.';
          }
          if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
            return 'URL gambar pada indeks $i tidak aman (harus diawali http:// atau https://).';
          }
        }

        // Cek video embed
        final video = insert['video'];
        if (video != null) {
          if (video is! String) {
            return 'URL video pada indeks $i harus berupa string.';
          }
          final trimmed = video.trim().toLowerCase();
          if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
            return 'URL video pada indeks $i tidak aman.';
          }
        }
      }

      // Validasi Atribut (misal Link)
      final attributes = op['attributes'];
      if (attributes is Map) {
        final link = attributes['link'];
        if (link != null) {
          if (link is! String) {
            return 'Atribut link pada indeks $i harus berupa string.';
          }
          final trimmed = link.trim().toLowerCase();
          if (trimmed.startsWith('javascript:') ||
              trimmed.startsWith('data:') ||
              trimmed.startsWith('vbscript:')) {
            return 'Skema link berbahaya terdeteksi pada indeks $i.';
          }
          if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
            return 'Link pada indeks $i harus diawali dengan http:// atau https://.';
          }
        }
      }
    }

    return null; // Valid
  }

  /// Memeriksa dan melempar Exception jika tidak valid
  static void sanitizeOrThrow(dynamic delta) {
    final error = validate(delta);
    if (error != null) {
      throw DeltaSanitizationException(error);
    }
  }
}

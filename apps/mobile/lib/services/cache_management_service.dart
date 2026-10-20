import 'dart:io' if (dart.library.html) 'dart:html';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

class CacheManagementService {
  static const Set<String> _safeExtensions = {
    '.tmp',
    '.temp',
    '.cache',
    '.part',
    '.pdf',
    '.doc',
    '.docx',
    '.zip',
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.mp4',
  };

  static const List<String> _protectedPathKeywords = [
    'flutter',
    'shader',
    'skia',
    'code_cache',
    'v8',
    'engine',
  ];

  /// Mengambil ukuran cache RAM saat ini dalam bytes
  int getRamCacheSizeBytes() {
    try {
      return PaintingBinding.instance.imageCache.currentSizeBytes;
    } catch (_) {
      return 0;
    }
  }

  /// Mengambil jumlah item cache gambar di RAM
  int getRamCacheCount() {
    try {
      return PaintingBinding.instance.imageCache.currentSize;
    } catch (_) {
      return 0;
    }
  }

  /// Membersihkan cache gambar di RAM
  void clearRamCache() {
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (e) {
      debugPrint('CacheManagementService: Gagal membersihkan RAM cache: $e');
    }
  }

  /// Memeriksa apakah path berkas aman untuk dihitung/dibersihkan dari systemTemp
  static bool isSafeTempFile(String path) {
    final lower = path.toLowerCase();
    for (final keyword in _protectedPathKeywords) {
      if (lower.contains(keyword)) return false;
    }
    for (final ext in _safeExtensions) {
      if (lower.endsWith(ext)) return true;
    }
    return false;
  }

  /// Mengambil total ukuran berkas sementara aman di Directory.systemTemp (dalam bytes)
  Future<int> getDiskTempSizeBytes() async {
    if (kIsWeb) return 0;

    try {
      final tempDir = Directory.systemTemp;
      if (!tempDir.existsSync()) return 0;

      int totalBytes = 0;
      await for (final entity in tempDir.list(recursive: true, followLinks: false)) {
        if (entity is File && isSafeTempFile(entity.path)) {
          try {
            totalBytes += await entity.length();
          } catch (_) {}
        }
      }
      return totalBytes;
    } catch (e) {
      debugPrint('CacheManagementService: Gagal menghitung disk temp size: $e');
      return 0;
    }
  }

  /// Membersihkan berkas sementara yang aman pada Directory.systemTemp
  /// Menghindari folder shader cache atau engine internal Flutter
  Future<int> clearDiskTempFiles() async {
    if (kIsWeb) return 0;

    int deletedCount = 0;
    try {
      final tempDir = Directory.systemTemp;
      if (!tempDir.existsSync()) return 0;

      await for (final entity in tempDir.list(recursive: true, followLinks: false)) {
        if (entity is File && isSafeTempFile(entity.path)) {
          try {
            await entity.delete();
            deletedCount++;
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('CacheManagementService: Gagal membersihkan disk temp files: $e');
    }
    return deletedCount;
  }

  /// Membersihkan seluruh cache (RAM dan safe disk temp)
  Future<void> clearAllCache() async {
    clearRamCache();
    await clearDiskTempFiles();
  }
}

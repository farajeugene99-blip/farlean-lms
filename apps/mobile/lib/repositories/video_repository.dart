import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/video_item.dart';

class VideoRepository {
  final FirebaseFirestore? _firestore;

  VideoRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  /// Mengambil data video berdasarkan ID
  Future<VideoItem?> getVideo(String videoId) async {
    final firestore = _firestore;
    if (firestore == null) return null;

    try {
      final doc = await firestore.collection('videos').doc(videoId).get();
      if (doc.exists) {
        return VideoItem.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Catatan baca video: $e');
      rethrow;
    }
    return null;
  }

  /// Membuat entri video pembelajaran baru
  Future<String> createVideo(VideoItem video) async {
    if (video.url.trim().isEmpty) {
      throw ArgumentError('URL video tidak boleh kosong.');
    }
    if (!video.url.startsWith('http://') && !video.url.startsWith('https://')) {
      throw ArgumentError('URL video harus diawali http:// atau https://');
    }

    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      final docRef = firestore.collection('videos').doc(video.id.isEmpty ? null : video.id);
      await docRef.set(video.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Gagal membuat video: $e');
      rethrow;
    }
  }

  /// Memperbarui informasi video pembelajaran
  Future<void> updateVideo(VideoItem video) async {
    if (video.url.trim().isEmpty) {
      throw ArgumentError('URL video tidak boleh kosong.');
    }

    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      await firestore.collection('videos').doc(video.id).update(video.toMap());
    } catch (e) {
      debugPrint('Gagal memperbarui video: $e');
      rethrow;
    }
  }

  /// Menghapus video pembelajaran (Guru/Admin)
  Future<void> deleteVideo(String videoId) async {
    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      await firestore.collection('videos').doc(videoId).delete();
    } catch (e) {
      debugPrint('Gagal menghapus video: $e');
      rethrow;
    }
  }
}

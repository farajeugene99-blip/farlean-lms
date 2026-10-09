import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/content_status.dart';
import '../models/delta_sanitizer.dart';
import '../models/material_content.dart';

class MaterialRepository {
  final FirebaseFirestore? _firestore;

  MaterialRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  /// Mengambil satu dokumen materi berdasarkan ID
  Future<MaterialContent?> getMaterial(String materiId) async {
    final firestore = _firestore;
    if (firestore == null) return null;

    try {
      final doc = await firestore.collection('materials').doc(materiId).get();
      if (doc.exists) {
        return MaterialContent.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Catatan baca materi: $e');
      rethrow;
    }
    return null;
  }

  /// Membuat materi baru (Guru/Admin)
  Future<String> createMaterial(MaterialContent material) async {
    if (material.title.trim().isEmpty) {
      throw ArgumentError('Judul materi tidak boleh kosong.');
    }
    // Validasi sanitasi Delta
    DeltaSanitizer.sanitizeOrThrow(material.content);

    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      final docRef = firestore.collection('materials').doc(material.id.isEmpty ? null : material.id);
      if (material.id.isNotEmpty) {
        final existing = await docRef.get();
        if (existing.exists) {
          throw StateError('Materi dengan ID ${material.id} sudah ada. Gunakan updateMaterial untuk mencegah penimpaan data.');
        }
      }
      await docRef.set(material.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Gagal membuat materi: $e');
      rethrow;
    }
  }

  /// Memperbarui isi materi dengan auto-increment versi
  Future<void> updateMaterial(MaterialContent material) async {
    if (material.id.trim().isEmpty) {
      throw ArgumentError('ID materi tidak boleh kosong untuk pembaruan.');
    }
    if (material.title.trim().isEmpty) {
      throw ArgumentError('Judul materi tidak boleh kosong.');
    }
    // Validasi sanitasi Delta
    DeltaSanitizer.sanitizeOrThrow(material.content);

    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      final docRef = firestore.collection('materials').doc(material.id);
      final existing = await docRef.get();
      if (!existing.exists) {
        throw StateError('Materi dengan ID ${material.id} tidak ditemukan untuk diperbarui.');
      }
      final currentVersion = (existing.data()?['version'] as num?)?.toInt() ?? material.version;

      final updates = material.toMap();
      updates['version'] = currentVersion + 1;
      updates['updated_at'] = FieldValue.serverTimestamp();

      await docRef.update(updates);
    } catch (e) {
      debugPrint('Gagal memperbarui materi: $e');
      rethrow;
    }
  }

  /// Memperbarui status publikasi materi (Draft -> Published -> Archived)
  Future<void> updateMaterialStatus(String materiId, ContentStatus status) async {
    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      await firestore.collection('materials').doc(materiId).update({
        'status': status.value,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Gagal mengubah status materi: $e');
      rethrow;
    }
  }

  /// Mencatat riwayat pembukaan materi oleh siswa (`materi_opened_at`)
  /// Bukti ini menjadi gate server-side sebelum siswa dapat mengerjakan kuis pretest
  Future<void> recordMateriOpened({
    required String classId,
    required String meetingId,
    required String materiId,
    required String uid,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      final viewRef = firestore
          .collection('meetings')
          .doc(meetingId)
          .collection('materi_views')
          .doc(uid);

      await viewRef.set({
        'materi_id': materiId,
        'user_id': uid,
        'opened_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Catatan pencatatan pembukaan materi: $e');
      rethrow;
    }
  }

  /// Memeriksa apakah siswa pernah membuka materi untuk pertemuan ini
  Future<bool> hasOpenedMateri({
    required String classId,
    required String meetingId,
    required String uid,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return false;

    try {
      final doc = await firestore
          .collection('meetings')
          .doc(meetingId)
          .collection('materi_views')
          .doc(uid)
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('Catatan cek pembukaan materi: $e');
      rethrow;
    }
  }
}

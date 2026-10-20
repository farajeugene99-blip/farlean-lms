import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/manual_book.dart';

class ManualBookRepository {
  final FirebaseFirestore? _firestore;

  ManualBookRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  /// Mengambil semua manual book untuk sistem (global) atau kelas
  /// Jika isAdmin == false, hanya mengembalikan dokumen berstatus 'Published' (menghindari PERMISSION_DENIED)
  Future<List<ManualBook>> getManualBooksByClass(String classId, {bool isAdmin = false}) async {
    final firestore = _firestore;
    if (firestore == null) return [];

    final targetClassId = (classId.isEmpty || classId == 'default_class') ? 'SYSTEM' : classId.trim();

    try {
      Query<Map<String, dynamic>> query = firestore
          .collection('manual_books')
          .where('class_id', isEqualTo: targetClassId);

      // Non-admin hanya boleh mengambil yang 'Published'
      if (!isAdmin) {
        query = query.where('status', isEqualTo: 'Published');
      }

      final snapshot = await query.get();

      final list = snapshot.docs.map((doc) => ManualBook.fromFirestore(doc)).toList();
      // Pengurutan in-memory di Dart (100% bebas dari kegagalan composite index Firestore)
      list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return list;
    } catch (e) {
      debugPrint('Catatan baca manual books: $e');
      rethrow;
    }
  }

  /// Mengambil satu manual book berdasarkan ID
  Future<ManualBook?> getManualBook(String id) async {
    final firestore = _firestore;
    if (firestore == null) return null;

    try {
      final doc = await firestore.collection('manual_books').doc(id).get();
      if (doc.exists) {
        return ManualBook.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Catatan baca manual book: $e');
      rethrow;
    }
    return null;
  }

  /// Menambahkan manual book baru (Admin untuk SYSTEM / Dosen untuk kelas)
  Future<String> createManualBook(ManualBook book) async {
    if (book.title.trim().isEmpty) {
      throw ArgumentError('Judul manual book tidak boleh kosong.');
    }
    if (book.fileUrl.trim().isEmpty || !book.fileUrl.trim().startsWith('https://')) {
      throw ArgumentError('URL berkas harus valid dan diawali https://');
    }

    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      final docRef =
          firestore.collection('manual_books').doc(book.id.isEmpty ? null : book.id);
      await docRef.set(book.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Gagal membuat manual book: $e');
      rethrow;
    }
  }

  /// Memperbarui informasi manual book (Admin / Guru)
  Future<void> updateManualBook(ManualBook book) async {
    if (book.id.trim().isEmpty) {
      throw ArgumentError('ID manual book tidak boleh kosong.');
    }

    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      await firestore.collection('manual_books').doc(book.id).update(book.toMap());
    } catch (e) {
      debugPrint('Gagal update manual book: $e');
      rethrow;
    }
  }

  /// Mengubah status publikasi manual book (Published / Draft / Archived)
  Future<void> updateStatus(String id, String status) async {
    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      await firestore.collection('manual_books').doc(id).update({
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
        if (status == 'Published') 'published_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Gagal update status manual book: $e');
      rethrow;
    }
  }

  /// Menghapus manual book (Admin untuk SYSTEM / Guru untuk kelas)
  Future<void> deleteManualBook(String id) async {
    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      await firestore.collection('manual_books').doc(id).delete();
    } catch (e) {
      debugPrint('Gagal menghapus manual book: $e');
      rethrow;
    }
  }
}

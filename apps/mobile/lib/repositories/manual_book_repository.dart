import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/manual_book.dart';

class ManualBookRepository {
  final FirebaseFirestore? _injectedFirestore;

  ManualBookRepository({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  FirebaseFirestore? get _firestore {
    if (_injectedFirestore != null) return _injectedFirestore;
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
  }

  /// Mengambil semua manual book untuk suatu kelas
  Future<List<ManualBook>> getManualBooksByClass(String classId) async {
    final firestore = _firestore;
    if (firestore == null) return [];

    try {
      final snapshot = await firestore
          .collection('manual_books')
          .where('class_id', isEqualTo: classId)
          .get();

      final list = snapshot.docs.map((doc) => ManualBook.fromFirestore(doc)).toList();
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

  /// Menambahkan manual book baru (Guru/Admin)
  Future<String> createManualBook(ManualBook book) async {
    if (book.title.trim().isEmpty) {
      throw ArgumentError('Judul manual book tidak boleh kosong.');
    }
    if (book.fileUrl.trim().isEmpty ||
        (!book.fileUrl.startsWith('http://') && !book.fileUrl.startsWith('https://'))) {
      throw ArgumentError('URL berkas harus valid dan diawali http:// atau https://');
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

  /// Menghapus manual book (Guru/Admin)
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

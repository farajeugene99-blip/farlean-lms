import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/content_status.dart';
import '../models/posttest.dart';
import '../models/question.dart';

class PosttestRepository {
  final FirebaseFirestore? _firestore;

  PosttestRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  /// Mengambil metadata kuis posttest
  Future<Posttest?> getPosttest(String testId) async {
    final firestore = _firestore;
    if (firestore == null) return null;

    try {
      final doc = await firestore.collection('posttests').doc(testId).get();
      if (doc.exists) {
        return Posttest.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Catatan baca posttest: $e');
      rethrow;
    }
    return null;
  }

  /// Mengambil daftar soal dari sub-koleksi posttests/{testId}/questions/{qid}
  /// ATURAN KEAMANAN (NO-KEY-LEAK):
  /// Soal yang dikembalikan tidak memuat kunci jawaban sama sekali.
  Future<List<Question>> getQuestions(String testId) async {
    final firestore = _firestore;
    if (firestore == null) return [];

    try {
      final snapshot = await firestore
          .collection('posttests')
          .doc(testId)
          .collection('questions')
          .get();

      return snapshot.docs.map((doc) => Question.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Catatan baca soal posttest: $e');
      rethrow;
    }
  }

  /// Membuat posttest baru (Guru/Admin)
  Future<String> createPosttest(Posttest posttest) async {
    if (posttest.title.trim().isEmpty) {
      throw ArgumentError('Judul posttest tidak boleh kosong.');
    }
    if (posttest.duration <= 0) {
      throw ArgumentError('Durasi posttest harus lebih besar dari 0 menit.');
    }
    if (posttest.maxAttempts <= 0) {
      throw ArgumentError('Batas percobaan (max_attempts) minimal 1.');
    }

    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      final docRef = firestore.collection('posttests').doc(posttest.id.isEmpty ? null : posttest.id);
      await docRef.set(posttest.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Gagal membuat posttest: $e');
      rethrow;
    }
  }

  /// Memperbarui metadata posttest (Guru/Admin)
  Future<void> updatePosttest(Posttest posttest) async {
    if (posttest.title.trim().isEmpty) {
      throw ArgumentError('Judul posttest tidak boleh kosong.');
    }

    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      await firestore.collection('posttests').doc(posttest.id).update(posttest.toMap());
    } catch (e) {
      debugPrint('Gagal memperbarui posttest: $e');
      rethrow;
    }
  }

  /// Memperbarui status posttest (Draft -> Published -> Archived)
  Future<void> updatePosttestStatus(String testId, ContentStatus status) async {
    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      await firestore.collection('posttests').doc(testId).update({
        'status': status.value,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Gagal mengubah status posttest: $e');
      rethrow;
    }
  }

  /// Menyimpan soal dan mengisolasi kunci jawaban ke koleksi rahasia `answer_keys`:
  /// - Soal ditulis ke: posttests/{testId}/questions/{qid}
  /// - Kunci jawaban ditulis ke: answer_keys/{testId}/items/{qid}
  Future<void> saveQuestionAndKey({
    required String testId,
    required Question question,
    required int correctOptionIndex,
    String? explanation,
  }) async {
    if (question.text.trim().isEmpty) {
      throw ArgumentError('Teks pertanyaan tidak boleh kosong.');
    }
    if (question.options.length < 2) {
      throw ArgumentError('Opsi pilihan jawaban minimal 2.');
    }
    if (correctOptionIndex < 0 || correctOptionIndex >= question.options.length) {
      throw ArgumentError('Indeks kunci jawaban tidak valid.');
    }

    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      final batch = firestore.batch();

      // 1. Tulis soal publik (tanpa kunci)
      final qDocRef = firestore
          .collection('posttests')
          .doc(testId)
          .collection('questions')
          .doc(question.id.isEmpty ? null : question.id);

      batch.set(qDocRef, question.toMap());

      // 2. Tulis kunci jawaban rahasia terisolasi di server
      final keyDocRef = firestore
          .collection('answer_keys')
          .doc(testId)
          .collection('items')
          .doc(qDocRef.id);

      batch.set(keyDocRef, {
        'qid': qDocRef.id,
        'correct_option': correctOptionIndex,
        'explanation': explanation,
        'points': question.points,
        'updated_at': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      debugPrint('Gagal menyimpan soal dan kunci posttest: $e');
      rethrow;
    }
  }
}

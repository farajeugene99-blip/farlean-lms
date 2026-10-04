import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/content_status.dart';
import '../models/pretest.dart';
import '../models/question.dart';

class PretestRepository {
  final FirebaseFirestore? _firestore;

  PretestRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  /// Mengambil metadata kuis pretest
  Future<Pretest?> getPretest(String testId) async {
    final firestore = _firestore;
    if (firestore == null) return null;

    try {
      final doc = await firestore.collection('pretests').doc(testId).get();
      if (doc.exists) {
        return Pretest.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Catatan baca pretest: $e');
      rethrow;
    }
    return null;
  }

  /// Mengambil daftar soal dari sub-koleksi pretests/{testId}/questions/{qid}
  /// ATURAN KEAMANAN (NO-KEY-LEAK):
  /// Soal yang dikembalikan tidak memuat kunci jawaban sama sekali.
  Future<List<Question>> getQuestions(String testId) async {
    final firestore = _firestore;
    if (firestore == null) return [];

    try {
      final snapshot = await firestore
          .collection('pretests')
          .doc(testId)
          .collection('questions')
          .get();

      return snapshot.docs.map((doc) => Question.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Catatan baca soal pretest: $e');
      rethrow;
    }
  }

  /// Membuat pretest baru (Guru/Admin)
  Future<String> createPretest(Pretest pretest) async {
    if (pretest.title.trim().isEmpty) {
      throw ArgumentError('Judul pretest tidak boleh kosong.');
    }
    if (pretest.duration <= 0) {
      throw ArgumentError('Durasi pretest harus lebih besar dari 0 menit.');
    }
    if (pretest.maxAttempts <= 0) {
      throw ArgumentError('Batas percobaan (max_attempts) minimal 1.');
    }

    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      final docRef = firestore.collection('pretests').doc(pretest.id.isEmpty ? null : pretest.id);
      await docRef.set(pretest.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Gagal membuat pretest: $e');
      rethrow;
    }
  }

  /// Memperbarui metadata pretest (Guru/Admin)
  Future<void> updatePretest(Pretest pretest) async {
    if (pretest.title.trim().isEmpty) {
      throw ArgumentError('Judul pretest tidak boleh kosong.');
    }

    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      await firestore.collection('pretests').doc(pretest.id).update(pretest.toMap());
    } catch (e) {
      debugPrint('Gagal memperbarui pretest: $e');
      rethrow;
    }
  }

  /// Memperbarui status pretest (Draft -> Published -> Archived)
  /// Larang hard delete jika sudah pernah ada attempt (hanya arsipkan)
  Future<void> updatePretestStatus(String testId, ContentStatus status) async {
    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      await firestore.collection('pretests').doc(testId).update({
        'status': status.value,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Gagal mengubah status pretest: $e');
      rethrow;
    }
  }

  /// Menyimpan soal dan mengisolasi kunci jawaban ke koleksi rahasia `answer_keys`:
  /// - Soal ditulis ke: pretests/{testId}/questions/{qid} (hanya text, options, points, tag)
  /// - Kunci jawaban ditulis ke: answer_keys/{testId}/items/{qid} (correct_option, explanation, points)
  Future<void> saveQuestionAndKey({
    required String testId,
    required Question question,
    required int correctOptionIndex,
    String? explanation,
  }) async {
    if (question.text.trim().isEmpty) {
      throw ArgumentError('Teks pertanyaan tidak boleh kosong.');
    }
    if (question.options.isEmpty) {
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
          .collection('pretests')
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
      debugPrint('Gagal menyimpan soal dan kunci: $e');
      rethrow;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/test_attempt.dart';

class AttemptRepository {
  final FirebaseFirestore? _firestore;

  AttemptRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  /// Mengambil attempt yang sedang berjalan (status == in_progress) untuk sesi recovery
  Future<TestAttempt?> getInProgressAttempt({
    required String userId,
    required String testId,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return null;

    try {
      final snapshot = await firestore
          .collection('attempts')
          .where('user_id', isEqualTo: userId)
          .where('test_id', isEqualTo: testId)
          .where('status', isEqualTo: AttemptStatus.inProgress.value)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return TestAttempt.fromFirestore(snapshot.docs.first);
      }
    } catch (e) {
      debugPrint('Catatan cek in-progress attempt: $e');
      rethrow;
    }
    return null;
  }

  /// Menghitung jumlah attempt yang telah dilakukan pengguna pada test ini
  Future<int> getAttemptCount({
    required String userId,
    required String testId,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return 0;

    try {
      final snapshot = await firestore
          .collection('attempts')
          .where('user_id', isEqualTo: userId)
          .where('test_id', isEqualTo: testId)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Catatan hitung attempt: $e');
      return 0;
    }
  }

  /// Memulai attempt baru:
  /// - Status: in_progress
  /// - started_at: serverTimestamp()
  /// - score: null (Client dilarang menulis skor)
  /// - question_order tersimpan permanen
  Future<TestAttempt> startAttempt({
    required String userId,
    required String testId,
    required String classId,
    required int attemptNo,
    required List<String> questionOrder,
    String kind = 'pretest',
  }) async {
    if (userId.trim().isEmpty) throw ArgumentError('userId tidak boleh kosong.');
    if (testId.trim().isEmpty) throw ArgumentError('testId tidak boleh kosong.');
    if (questionOrder.isEmpty) throw ArgumentError('Daftar soal (questionOrder) tidak boleh kosong.');

    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      final docRef = firestore.collection('attempts').doc();
      final attempt = TestAttempt(
        id: docRef.id,
        userId: userId,
        testId: testId,
        classId: classId,
        attemptNo: attemptNo,
        answers: const {},
        questionOrder: questionOrder,
        score: null,
        status: AttemptStatus.inProgress,
        startedAt: DateTime.now(),
        kind: kind,
      );

      final map = attempt.toMap();
      map['started_at'] = FieldValue.serverTimestamp();
      map['kind'] = kind;

      await docRef.set(map);
      return attempt;
    } catch (e) {
      debugPrint('Gagal memulai attempt: $e');
      rethrow;
    }
  }

  /// Autosave jawaban secara efisien:
  /// ATURAN KEAMANAN: Hanya mengupdate field `answers` dan `last_saved_at`
  /// Field `status`, `started_at`, dan `score` TIDAK disentuh.
  Future<void> autosaveAnswers({
    required String attemptId,
    required Map<String, dynamic> answers,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      await firestore.collection('attempts').doc(attemptId).update({
        'answers': answers,
        'last_saved_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Gagal autosave jawaban: $e');
      rethrow;
    }
  }

  /// Mengambil data attempt berdasarkan ID
  Future<TestAttempt?> getAttempt(String attemptId) async {
    final firestore = _firestore;
    if (firestore == null) return null;

    try {
      final doc = await firestore.collection('attempts').doc(attemptId).get();
      if (doc.exists) {
        return TestAttempt.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Catatan baca attempt: $e');
      rethrow;
    }
    return null;
  }
}

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../models/content_status.dart';
import '../models/pretest.dart';
import '../models/question.dart';

class PretestRepository {
  final FirebaseFirestore? _firestore;
  final http.Client _httpClient;
  final FirebaseAuth? _auth;

  PretestRepository({
    FirebaseFirestore? firestore,
    http.Client? httpClient,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null),
        _httpClient = httpClient ?? http.Client(),
        _auth = auth ?? (Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null);

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
  /// Soal yang bertanda soft-delete difilter keluar.
  Future<List<Question>> getQuestions(String testId) async {
    final firestore = _firestore;
    if (firestore == null) return [];

    try {
      final snapshot = await firestore
          .collection('pretests')
          .doc(testId)
          .collection('questions')
          .get();

      return snapshot.docs
          .where((doc) => doc.data()['deleted'] != true)
          .map((doc) => Question.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Catatan baca soal pretest: $e');
      rethrow;
    }
  }

  /// Membuat pretest baru
  Future<String> createPretest(Pretest pretest) async {
    if (pretest.title.trim().isEmpty) {
      throw ArgumentError('Judul pretest tidak boleh kosong.');
    }
    if (pretest.duration <= 0) {
      throw ArgumentError('Durasi pretest harus lebih besar dari 0.');
    }
    if (pretest.maxAttempts <= 0) {
      throw ArgumentError('Maksimal percobaan harus lebih besar dari 0.');
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

  /// Memperbarui metadata pretest
  Future<void> updatePretest(Pretest pretest) async {
    if (pretest.id.isEmpty) {
      throw ArgumentError('ID pretest tidak boleh kosong.');
    }
    if (pretest.title.trim().isEmpty) {
      throw ArgumentError('Judul pretest tidak boleh kosong.');
    }
    if (pretest.duration <= 0) {
      throw ArgumentError('Durasi pretest harus lebih besar dari 0.');
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

  /// Memperbarui status pretest
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

  /// Menyimpan soal dan kunci jawaban melalui Backend API (/api/save-question)
  /// - Menghindari error Firestore Rules L259/L291/L344 (karena kunci jawaban server-only)
  /// - Melakukan penulisan atomik soal dan kunci jawaban di server Admin SDK
  /// - Menjaga integritas versi soal saat ada kuis yang telah dikerjakan siswa
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

    final token = await _auth?.currentUser?.getIdToken();
    if (token == null && Firebase.apps.isNotEmpty) {
      throw StateError('Pengguna belum terautentikasi.');
    }

    final payload = {
      'testId': testId,
      if (question.id.isNotEmpty) 'qid': question.id,
      'text': question.text.trim(),
      'options': question.options,
      'correct_option': correctOptionIndex,
      'points': question.points,
      if (explanation != null && explanation.isNotEmpty) 'explanation': explanation.trim(),
    };

    final response = await _httpClient.post(
      Uri.parse(ApiConfig.saveQuestionUrl),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      try {
        final errJson = jsonDecode(response.body);
        throw Exception(errJson['error'] ?? 'Gagal menyimpan soal dan kunci jawaban.');
      } catch (e) {
        if (e is Exception && !e.toString().contains('FormatException')) rethrow;
        throw Exception('Gagal menyimpan soal: HTTP ${response.statusCode}');
      }
    }
  }

  /// Menghapus soal melalui Backend API (/api/delete-question)
  /// - Jika kuis belum pernah dikerjakan: hard-delete atomik soal dan kunci
  /// - Jika sudah ada attempt: soft-delete demi menjaga riwayat attempt siswa
  Future<void> deleteQuestion({
    required String testId,
    required String qid,
  }) async {
    if (testId.trim().isEmpty || qid.trim().isEmpty) {
      throw ArgumentError('testId dan qid tidak boleh kosong.');
    }

    final token = await _auth?.currentUser?.getIdToken();
    if (token == null && Firebase.apps.isNotEmpty) {
      throw StateError('Pengguna belum terautentikasi.');
    }

    final response = await _httpClient.post(
      Uri.parse(ApiConfig.deleteQuestionUrl),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'testId': testId.trim(),
        'qid': qid.trim(),
      }),
    );

    if (response.statusCode != 200) {
      try {
        final errJson = jsonDecode(response.body);
        throw Exception(errJson['error'] ?? 'Gagal menghapus soal.');
      } catch (e) {
        if (e is Exception && !e.toString().contains('FormatException')) rethrow;
        throw Exception('Gagal menghapus soal: HTTP ${response.statusCode}');
      }
    }
  }
}

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../models/content_status.dart';
import '../models/posttest.dart';
import '../models/question.dart';

class PosttestRepository {
  final FirebaseFirestore? _firestore;
  final http.Client _httpClient;
  final FirebaseAuth? _auth;

  PosttestRepository({
    FirebaseFirestore? firestore,
    http.Client? httpClient,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null),
        _httpClient = httpClient ?? http.Client(),
        _auth = auth ?? (Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null);

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
  /// Soal yang bertanda soft-delete difilter keluar.
  Future<List<Question>> getQuestions(String testId) async {
    final firestore = _firestore;
    if (firestore == null) return [];

    try {
      final snapshot = await firestore
          .collection('posttests')
          .doc(testId)
          .collection('questions')
          .get();

      return snapshot.docs
          .where((doc) => doc.data()['deleted'] != true)
          .map((doc) => Question.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Catatan baca soal posttest: $e');
      rethrow;
    }
  }

  /// Membuat posttest baru
  Future<String> createPosttest(Posttest posttest) async {
    if (posttest.title.trim().isEmpty) {
      throw ArgumentError('Judul posttest tidak boleh kosong.');
    }
    if (posttest.duration <= 0) {
      throw ArgumentError('Durasi posttest harus lebih besar dari 0.');
    }
    if (posttest.maxAttempts <= 0) {
      throw ArgumentError('Maksimal percobaan harus lebih besar dari 0.');
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

  /// Memperbarui metadata posttest
  Future<void> updatePosttest(Posttest posttest) async {
    if (posttest.id.isEmpty) {
      throw ArgumentError('ID posttest tidak boleh kosong.');
    }
    if (posttest.title.trim().isEmpty) {
      throw ArgumentError('Judul posttest tidak boleh kosong.');
    }
    if (posttest.duration <= 0) {
      throw ArgumentError('Durasi posttest harus lebih besar dari 0.');
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

  /// Memperbarui status posttest dengan validasi server-side via /api/publish-test
  Future<void> updatePosttestStatus(String testId, ContentStatus status) async {
    final token = await _auth?.currentUser?.getIdToken();
    if (token == null && Firebase.apps.isNotEmpty) {
      throw StateError('Pengguna belum terautentikasi.');
    }

    if (token != null) {
      final response = await _httpClient.post(
        Uri.parse(ApiConfig.publishTestUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'testId': testId.trim(),
          'status': status.value,
        }),
      );
      if (response.statusCode == 200) return;
      final errJson = jsonDecode(response.body);
      throw StateError(errJson['error'] ?? 'Gagal memperbarui status posttest.');
    }

    if (_firestore == null) throw StateError('Firestore belum diinisialisasi.');
  }

  /// Menyimpan soal dan kunci jawaban melalui Backend API (/api/save-question)
  /// - Menghindari error Firestore Rules L280/L291/L344 (karena kunci jawaban server-only)
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
        throw Exception(errJson['error'] ?? 'Gagal menyimpan soal dan kunci jawaban posttest.');
      } catch (e) {
        if (e is Exception && !e.toString().contains('FormatException')) rethrow;
        throw Exception('Gagal menyimpan soal posttest: HTTP ${response.statusCode}');
      }
    }
  }

  /// Menghapus soal melalui Backend API (/api/delete-question)
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
        throw Exception(errJson['error'] ?? 'Gagal menghapus soal posttest.');
      } catch (e) {
        if (e is Exception && !e.toString().contains('FormatException')) rethrow;
        throw Exception('Gagal menghapus soal: HTTP ${response.statusCode}');
      }
    }
  }
}

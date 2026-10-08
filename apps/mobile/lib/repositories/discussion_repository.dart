import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../models/discussion.dart';

class DiscussionRepository {
  final FirebaseFirestore? _firestore;
  final http.Client _httpClient;
  final FirebaseAuth? _auth;

  DiscussionRepository({
    FirebaseFirestore? firestore,
    http.Client? httpClient,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null),
        _httpClient = httpClient ?? http.Client(),
        _auth = auth ?? (Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null);

  /// Mengambil daftar thread diskusi di kelas tertentu dengan paginasi
  Future<List<Discussion>> getDiscussions({
    required String classId,
    bool isStaff = false,
    int limit = 20,
    DocumentSnapshot? startAfterDoc,
    bool filterUnanswered = false,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return [];

    try {
      Query<Map<String, dynamic>> query = firestore
          .collection('discussions')
          .where('class_id', isEqualTo: classId);

      // Siswa hanya melihat thread berstatus ACTIVE, Guru/Admin melihat semua
      if (!isStaff) {
        query = query.where('status', isEqualTo: DiscussionStatus.active.value);
      }

      // Filter kuis/diskusi yang belum dibalas
      if (filterUnanswered) {
        query = query.where('reply_count', isEqualTo: 0);
      }

      // Urutkan berdasarkan aktivitas terbaru
      query = query.orderBy('last_activity_at', descending: true);
      query = query.limit(limit);

      if (startAfterDoc != null) {
        query = query.startAfterDocument(startAfterDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Discussion.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Catatan ambil daftar diskusi: $e');
      rethrow;
    }
  }

  /// Mengambil satu dokumen diskusi berdasarkan ID
  Future<Discussion?> getDiscussion(String discussionId) async {
    final firestore = _firestore;
    if (firestore == null) return null;

    try {
      final doc = await firestore.collection('discussions').doc(discussionId).get();
      if (doc.exists) {
        return Discussion.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Catatan ambil detail diskusi: $e');
      rethrow;
    }
    return null;
  }

  /// Membuat thread diskusi baru melalui Backend API (Anti-Impersonasi & Rate Limit)
  Future<String> createThread({
    required String classId,
    required String title,
    required String body,
  }) async {
    if (classId.trim().isEmpty) throw ArgumentError('classId tidak boleh kosong.');
    if (title.trim().length < 3) throw ArgumentError('Judul minimal 3 karakter.');
    if (body.trim().length < 3) throw ArgumentError('Isi diskusi minimal 3 karakter.');

    final token = await _auth?.currentUser?.getIdToken();
    if (token == null && Firebase.apps.isNotEmpty) {
      throw StateError('Pengguna belum terautentikasi.');
    }

    final response = await _httpClient.post(
      Uri.parse(ApiConfig.discussionThreadUrl),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'classId': classId.trim(),
        'title': title.trim(),
        'body': body.trim(),
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return data['discussionId'] as String;
    } else {
      throw StateError(data['error'] ?? 'Gagal membuat diskusi.');
    }
  }

  /// Mengirim balasan melalui Backend API (Transaksi atomik increment & anti-impersonasi)
  Future<String> postReply({
    required String discussionId,
    required String body,
  }) async {
    if (discussionId.trim().isEmpty) throw ArgumentError('discussionId tidak boleh kosong.');
    if (body.trim().isEmpty) throw ArgumentError('Isi balasan tidak boleh kosong.');

    final token = await _auth?.currentUser?.getIdToken();
    if (token == null && Firebase.apps.isNotEmpty) {
      throw StateError('Pengguna belum terautentikasi.');
    }

    final response = await _httpClient.post(
      Uri.parse(ApiConfig.discussionReplyUrl),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'discussionId': discussionId.trim(),
        'body': body.trim(),
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return data['replyId'] as String;
    } else {
      throw StateError(data['error'] ?? 'Gagal mengirim balasan.');
    }
  }

  /// Mengambil daftar balasan untuk thread tertentu
  Future<List<DiscussionReply>> getReplies({
    required String discussionId,
    bool isStaff = false,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return [];

    try {
      final snapshot = await firestore
          .collection('discussions')
          .doc(discussionId)
          .collection('replies')
          .orderBy('created_at', descending: false)
          .get();

      return snapshot.docs
          .where((doc) => isStaff || doc.data()['status'] != DiscussionStatus.archived.value)
          .map((doc) => DiscussionReply.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Catatan ambil balasan diskusi: $e');
      rethrow;
    }
  }

  /// Mengupdate judul dan isi diskusi oleh pembuat thread (Client-Direct terproteksi rules)
  Future<void> updateThread({
    required String discussionId,
    required String title,
    required String body,
  }) async {
    if (title.trim().length < 3) throw ArgumentError('Judul minimal 3 karakter.');
    if (body.trim().length < 3) throw ArgumentError('Isi diskusi minimal 3 karakter.');

    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      await firestore.collection('discussions').doc(discussionId).update({
        'title': title.trim(),
        'body': body.trim(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Gagal update diskusi: $e');
      rethrow;
    }
  }

  /// Mengarsipkan thread diskusi (Moderasi Guru / Pengelola)
  Future<void> archiveThread({required String discussionId}) async {
    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      await firestore.collection('discussions').doc(discussionId).update({
        'status': DiscussionStatus.archived.value,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Gagal mengarsipkan diskusi: $e');
      rethrow;
    }
  }

  /// Mengarsipkan balasan diskusi (Moderasi Guru / Pengelola)
  Future<void> archiveReply({
    required String discussionId,
    required String replyId,
  }) async {
    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      await firestore
          .collection('discussions')
          .doc(discussionId)
          .collection('replies')
          .doc(replyId)
          .update({
        'status': DiscussionStatus.archived.value,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Gagal mengarsipkan balasan: $e');
      rethrow;
    }
  }
}

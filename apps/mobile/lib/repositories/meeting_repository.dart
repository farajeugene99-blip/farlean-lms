import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../models/content_status.dart';
import '../models/meeting.dart';

class MeetingRepository {
  final FirebaseFirestore? _firestore;
  final http.Client _httpClient;
  final FirebaseAuth? _auth;

  MeetingRepository({FirebaseFirestore? firestore, http.Client? httpClient, FirebaseAuth? auth})
      : _firestore = firestore ?? (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null),
        _httpClient = httpClient ?? http.Client(),
        _auth = auth ?? (Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null);

  /// Mengambil seluruh pertemuan dalam kelas terurut nomor pertemuan
  /// Jika isStaff == false (mahasiswa), hanya mengembalikan pertemuan berstatus Published
  Future<List<Meeting>> getMeetingsByClass(String classId, {bool isStaff = false}) async {
    final firestore = _firestore;
    if (firestore == null) return [];

    try {
      Query<Map<String, dynamic>> query = firestore
          .collection('meetings')
          .where('class_id', isEqualTo: classId);

      if (!isStaff) {
        query = query.where('status', whereIn: [ContentStatus.published.value, ContentStatus.scheduled.value]);
      }

      final snapshot = await query.get();
      final meetings = snapshot.docs.map((doc) => Meeting.fromFirestore(doc)).toList();

      // Urutkan berdasarkan nomor pertemuan
      meetings.sort((a, b) => a.number.compareTo(b.number));
      return meetings;
    } catch (e) {
      debugPrint('Catatan ambil pertemuan: $e');
      rethrow;
    }
  }

  /// Mengambil jumlah pertemuan aktual via agregasi Firestore count()
  Future<int> getMeetingCount(String classId, {bool isStaff = false}) async {
    final firestore = _firestore;
    if (firestore == null) return 0;

    try {
      Query<Map<String, dynamic>> query = firestore
          .collection('meetings')
          .where('class_id', isEqualTo: classId);

      if (!isStaff) {
        query = query.where('status', whereIn: [ContentStatus.published.value, ContentStatus.scheduled.value]);
      }

      final aggregateQuery = query.count();
      final snapshot = await aggregateQuery.get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Catatan getMeetingCount: $e');
      return 0;
    }
  }

  /// Mengambil satu pertemuan berdasarkan ID
  Future<Meeting?> getMeeting(String meetingId) async {
    final firestore = _firestore;
    if (firestore == null) return null;

    try {
      final doc = await firestore.collection('meetings').doc(meetingId).get();
      if (doc.exists) {
        return Meeting.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Catatan ambil detail pertemuan: $e');
      rethrow;
    }
    return null;
  }

  /// Membuat pertemuan baru (Role Guru/Admin)
  Future<String> createMeeting(Meeting meeting) async {
    if (meeting.title.trim().isEmpty) {
      throw ArgumentError('Judul pertemuan tidak boleh kosong.');
    }
    if (meeting.number <= 0) {
      throw ArgumentError('Nomor pertemuan harus lebih besar dari 0.');
    }

    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      final docRef = firestore.collection('meetings').doc(meeting.id.isEmpty ? null : meeting.id);
      await docRef.set(meeting.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Gagal membuat pertemuan: $e');
      rethrow;
    }
  }

  /// Memperbarui informasi pertemuan
  Future<void> updateMeeting(Meeting meeting) async {
    if (meeting.title.trim().isEmpty) {
      throw ArgumentError('Judul pertemuan tidak boleh kosong.');
    }

    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      await firestore.collection('meetings').doc(meeting.id).update(meeting.toUpdateMap());
    } catch (e) {
      debugPrint('Gagal memperbarui pertemuan: $e');
      rethrow;
    }
  }

  /// Memperbarui status siklus hidup pertemuan (Draft -> Scheduled -> Published -> Archived)
  Future<void> updateMeetingStatus(
    String meetingId,
    ContentStatus status, {
    DateTime? publishAt,
  }) async {
    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      final updates = <String, dynamic>{
        'status': status.value,
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (status == ContentStatus.scheduled && publishAt != null) {
        updates['publish_at'] = Timestamp.fromDate(publishAt);
      } else if (status == ContentStatus.published || status == ContentStatus.draft) {
        updates['publish_at'] = null;
      }

      await firestore.collection('meetings').doc(meetingId).update(updates);
    } catch (e) {
      debugPrint('Gagal mengubah status pertemuan: $e');
      rethrow;
    }
  }

  /// Menautkan referensi modul (pretest, materi, video, posttest, assignment) ke pertemuan
  Future<void> linkModule(
    String meetingId, {
    String? pretestId,
    String? materiId,
    String? videoId,
    String? posttestId,
    String? assignmentId,
    bool clearAssignment = false,
  }) async {
    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      final updates = <String, dynamic>{};
      if (pretestId != null) updates['pretest_id'] = pretestId;
      if (materiId != null) updates['materi_id'] = materiId;
      if (videoId != null) updates['video_id'] = videoId;
      if (posttestId != null) updates['posttest_id'] = posttestId;
      if (clearAssignment) {
        updates['assignment_id'] = FieldValue.delete();
      } else if (assignmentId != null) {
        updates['assignment_id'] = assignmentId;
      }

      if (updates.isNotEmpty) {
        await firestore.collection('meetings').doc(meetingId).update(updates);
      }
    } catch (e) {
      debugPrint('Gagal menautkan modul ke pertemuan: $e');
      rethrow;
    }
  }

  /// Memicu promosi pertemuan terjadwal yang sudah jatuh tempo via backend.
  /// Dipakai staf dari UI ("Sinkronkan jadwal") maupun otomatis setelah menjadwalkan.
  /// Mengembalikan jumlah pertemuan yang dipromosikan pada pemanggilan ini.
  Future<int> syncScheduledMeetings({String? classId}) async {
    final token = await _auth?.currentUser?.getIdToken();
    if (token == null && Firebase.apps.isNotEmpty) {
      throw StateError('Pengguna belum terautentikasi.');
    }

    final response = await _httpClient.post(
      Uri.parse(ApiConfig.publishMeetingsUrl),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        if (classId != null && classId.trim().isNotEmpty) 'classId': classId.trim(),
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return (data['promotedCount'] as num?)?.toInt() ?? 0;
    }
    throw StateError(data['error'] ?? 'Gagal menyinkronkan jadwal publikasi.');
  }

  /// Menghapus pertemuan
  Future<void> deleteMeeting(String meetingId) async {
    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      await firestore.collection('meetings').doc(meetingId).delete();
    } catch (e) {
      debugPrint('Gagal menghapus pertemuan: $e');
      rethrow;
    }
  }
}

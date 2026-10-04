import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/content_status.dart';
import '../models/meeting.dart';

class MeetingRepository {
  final FirebaseFirestore? _injectedFirestore;

  MeetingRepository({FirebaseFirestore? firestore})
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
        query = query.where('status', isEqualTo: ContentStatus.published.value);
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
      await firestore.collection('meetings').doc(meeting.id).update(meeting.toMap());
    } catch (e) {
      debugPrint('Gagal memperbarui pertemuan: $e');
      rethrow;
    }
  }

  /// Memperbarui status siklus hidup pertemuan (Draft -> Published -> Archived)
  Future<void> updateMeetingStatus(String meetingId, ContentStatus status) async {
    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      await firestore.collection('meetings').doc(meetingId).update({
        'status': status.value,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Gagal mengubah status pertemuan: $e');
      rethrow;
    }
  }

  /// Menautkan referensi modul (pretest, materi, video) ke pertemuan
  Future<void> linkModule(
    String meetingId, {
    String? pretestId,
    String? materiId,
    String? videoId,
  }) async {
    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      final updates = <String, dynamic>{};
      if (pretestId != null) updates['pretest_id'] = pretestId;
      if (materiId != null) updates['materi_id'] = materiId;
      if (videoId != null) updates['video_id'] = videoId;

      if (updates.isNotEmpty) {
        await firestore.collection('meetings').doc(meetingId).update(updates);
      }
    } catch (e) {
      debugPrint('Gagal menautkan modul ke pertemuan: $e');
      rethrow;
    }
  }
}

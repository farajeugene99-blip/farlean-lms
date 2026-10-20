import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/assignment.dart';
import '../models/assignment_submission.dart';

class AssignmentRepository {
  final FirebaseFirestore? _firestore;

  AssignmentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  /// Mengambil semua tugas pada suatu kelas
  Future<List<Assignment>> getAssignmentsByClass(String classId) async {
    final cleanClassId = classId.trim();
    if (cleanClassId.isEmpty || cleanClassId == 'default_class') return [];

    final firestore = _firestore;
    if (firestore == null) return [];

    try {
      final snapshot = await firestore
          .collection('classes')
          .doc(cleanClassId)
          .collection('assignments')
          .get();

      final list = snapshot.docs
          .map((doc) => Assignment.fromFirestore(doc, classId: cleanClassId))
          .toList();
      list.sort((a, b) => b.deadline.compareTo(a.deadline));
      return list;
    } catch (e) {
      debugPrint('Catatan baca assignments: $e');
      rethrow;
    }
  }

  /// Mengambil data satu tugas
  Future<Assignment?> getAssignment(String classId, String assignmentId) async {
    final cleanClassId = classId.trim();
    final cleanAssignmentId = assignmentId.trim();
    if (cleanClassId.isEmpty || cleanAssignmentId.isEmpty) return null;

    final firestore = _firestore;
    if (firestore == null) return null;

    try {
      final doc = await firestore
          .collection('classes')
          .doc(cleanClassId)
          .collection('assignments')
          .doc(cleanAssignmentId)
          .get();

      if (doc.exists) {
        return Assignment.fromFirestore(doc, classId: cleanClassId);
      }
    } catch (e) {
      debugPrint('Catatan baca assignment: $e');
      rethrow;
    }
    return null;
  }

  /// Mengambil tugas yang tertaut pada suatu pertemuan
  Future<Assignment?> getAssignmentByMeeting(String classId, String meetingId) async {
    final cleanClassId = classId.trim();
    final cleanMeetingId = meetingId.trim();
    if (cleanClassId.isEmpty || cleanMeetingId.isEmpty) return null;

    final firestore = _firestore;
    if (firestore == null) return null;

    try {
      final snapshot = await firestore
          .collection('classes')
          .doc(cleanClassId)
          .collection('assignments')
          .where('meeting_id', isEqualTo: cleanMeetingId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Assignment.fromFirestore(snapshot.docs.first, classId: cleanClassId);
      }
    } catch (e) {
      debugPrint('Catatan getAssignmentByMeeting: $e');
    }
    return null;
  }

  /// Membuat tugas baru (Guru) dengan sinkronisasi atomik ke dokumen pertemuan (jika tertaut)
  Future<String> createAssignment(Assignment assignment) async {
    if (assignment.title.trim().isEmpty) {
      throw ArgumentError('Judul tugas tidak boleh kosong.');
    }
    if (assignment.classId.trim().isEmpty) {
      throw ArgumentError('classId tidak boleh kosong.');
    }

    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      final docRef = firestore
          .collection('classes')
          .doc(assignment.classId.trim())
          .collection('assignments')
          .doc(assignment.id.isEmpty ? null : assignment.id);

      final batch = firestore.batch();
      batch.set(docRef, assignment.toMap());

      if (assignment.meetingId != null && assignment.meetingId!.trim().isNotEmpty) {
        final meetingRef = firestore.collection('meetings').doc(assignment.meetingId!.trim());
        batch.update(meetingRef, {
          'assignment_id': docRef.id,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      return docRef.id;
    } catch (e) {
      debugPrint('Gagal membuat assignment: $e');
      rethrow;
    }
  }

  /// Memperbarui tugas (Guru) dengan sinkronisasi pointer dua arah ke pertemuan baru & lama
  Future<void> updateAssignment(Assignment assignment, {String? previousMeetingId}) async {
    if (assignment.id.trim().isEmpty || assignment.classId.trim().isEmpty) {
      throw ArgumentError('ID tugas dan classId tidak boleh kosong.');
    }

    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      final docRef = firestore
          .collection('classes')
          .doc(assignment.classId.trim())
          .collection('assignments')
          .doc(assignment.id.trim());

      final batch = firestore.batch();
      batch.update(docRef, assignment.toMap());

      // Jika pertemuan berubah, bersihkan penunjuk pada pertemuan lama
      final prevMId = previousMeetingId?.trim();
      final newMId = assignment.meetingId?.trim();

      if (prevMId != null && prevMId.isNotEmpty && prevMId != newMId) {
        final oldMeetingRef = firestore.collection('meetings').doc(prevMId);
        batch.update(oldMeetingRef, {
          'assignment_id': FieldValue.delete(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      // Tautkan ke pertemuan baru jika ada
      if (newMId != null && newMId.isNotEmpty) {
        final newMeetingRef = firestore.collection('meetings').doc(newMId);
        batch.update(newMeetingRef, {
          'assignment_id': assignment.id.trim(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Gagal update assignment: $e');
      rethrow;
    }
  }

  /// Menghapus tugas (Guru) serta mereset field assignment_id pada pertemuan lama secara atomik
  Future<void> deleteAssignment(String classId, String assignmentId, {String? meetingId}) async {
    final cleanClassId = classId.trim();
    final cleanAssignmentId = assignmentId.trim();
    if (cleanClassId.isEmpty || cleanAssignmentId.isEmpty) {
      throw ArgumentError('ID tidak valid.');
    }

    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      String? targetMeetingId = meetingId?.trim();
      final docRef = firestore
          .collection('classes')
          .doc(cleanClassId)
          .collection('assignments')
          .doc(cleanAssignmentId);

      if (targetMeetingId == null || targetMeetingId.isEmpty) {
        final snap = await docRef.get();
        if (snap.exists) {
          targetMeetingId = snap.data()?['meeting_id'] as String?;
        }
      }

      final batch = firestore.batch();
      batch.delete(docRef);

      if (targetMeetingId != null && targetMeetingId.trim().isNotEmpty) {
        final meetingRef = firestore.collection('meetings').doc(targetMeetingId.trim());
        batch.update(meetingRef, {
          'assignment_id': FieldValue.delete(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Gagal delete assignment: $e');
      rethrow;
    }
  }

  /// Memeriksa apakah suatu tugas sudah memiliki setidaknya satu submission (anti-overwrite tipe tugas)
  Future<bool> hasSubmissions(String classId, String assignmentId) async {
    final cleanClassId = classId.trim();
    final cleanAssignmentId = assignmentId.trim();
    if (cleanClassId.isEmpty || cleanAssignmentId.isEmpty) return false;

    final firestore = _firestore;
    if (firestore == null) return false;

    try {
      final snap = await firestore
          .collection('classes')
          .doc(cleanClassId)
          .collection('assignments')
          .doc(cleanAssignmentId)
          .collection('submissions')
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Catatan cek hasSubmissions: $e');
      return false;
    }
  }

  /// Mengambil dokumen pengumpulan spesifik (oleh mahasiswa atau kelompok)
  Future<AssignmentSubmission?> getSubmission({
    required String classId,
    required String assignmentId,
    required String submissionId,
  }) async {
    final cleanClassId = classId.trim();
    final cleanAssignmentId = assignmentId.trim();
    final cleanSubmissionId = submissionId.trim();
    if (cleanClassId.isEmpty || cleanAssignmentId.isEmpty || cleanSubmissionId.isEmpty) return null;

    final firestore = _firestore;
    if (firestore == null) return null;

    try {
      final doc = await firestore
          .collection('classes')
          .doc(cleanClassId)
          .collection('assignments')
          .doc(cleanAssignmentId)
          .collection('submissions')
          .doc(cleanSubmissionId)
          .get();

      if (doc.exists) {
        return AssignmentSubmission.fromFirestore(
          doc,
          assignmentId: cleanAssignmentId,
          classId: cleanClassId,
        );
      }
    } catch (e) {
      debugPrint('Catatan baca submission: $e');
      rethrow;
    }
    return null;
  }

  /// Mengambil semua pengumpulan tugas (Dosen)
  Future<List<AssignmentSubmission>> getAllSubmissions({
    required String classId,
    required String assignmentId,
  }) async {
    final cleanClassId = classId.trim();
    final cleanAssignmentId = assignmentId.trim();
    if (cleanClassId.isEmpty || cleanAssignmentId.isEmpty) return [];

    final firestore = _firestore;
    if (firestore == null) return [];

    try {
      final snapshot = await firestore
          .collection('classes')
          .doc(cleanClassId)
          .collection('assignments')
          .doc(cleanAssignmentId)
          .collection('submissions')
          .get();

      final list = snapshot.docs
          .map((doc) => AssignmentSubmission.fromFirestore(
                doc,
                assignmentId: cleanAssignmentId,
                classId: cleanClassId,
              ))
          .toList();
      list.sort((a, b) => (b.submittedAt ?? DateTime(0)).compareTo(a.submittedAt ?? DateTime(0)));
      return list;
    } catch (e) {
      debugPrint('Catatan baca all submissions: $e');
      rethrow;
    }
  }

  /// Mengumpulkan tugas (Individu atau Kelompok)
  Future<void> submitAssignment(AssignmentSubmission submission) async {
    if (submission.fileUrl.trim().isEmpty || !submission.fileUrl.startsWith('https://')) {
      throw ArgumentError('URL berkas tugas harus valid (HTTPS).');
    }
    if (submission.id.trim().isEmpty) {
      throw ArgumentError('ID submission tidak boleh kosong.');
    }

    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      final docRef = firestore
          .collection('classes')
          .doc(submission.classId.trim())
          .collection('assignments')
          .doc(submission.assignmentId.trim())
          .collection('submissions')
          .doc(submission.id.trim());

      await docRef.set(submission.toMap(), SetOptions(merge: true));
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      // Clock skew resilience: jika HP mengira masih sempat tetapi jam server sudah melewati deadline
      if ((errStr.contains('permission-denied') || errStr.contains('insufficient-permission')) &&
          submission.status == SubmissionStatus.submitted) {
        try {
          final lateSubmission = AssignmentSubmission(
            id: submission.id,
            assignmentId: submission.assignmentId,
            classId: submission.classId,
            isGroup: submission.isGroup,
            studentUid: submission.studentUid,
            studentName: submission.studentName,
            groupId: submission.groupId,
            groupName: submission.groupName,
            contributorIds: submission.contributorIds,
            submittedByUid: submission.submittedByUid,
            submittedByName: submission.submittedByName,
            fileUrl: submission.fileUrl,
            fileName: submission.fileName,
            fileSize: submission.fileSize,
            note: submission.note,
            status: SubmissionStatus.late,
            submittedAt: submission.submittedAt,
          );
          final docRef = firestore
              .collection('classes')
              .doc(submission.classId.trim())
              .collection('assignments')
              .doc(submission.assignmentId.trim())
              .collection('submissions')
              .doc(submission.id.trim());
          await docRef.set(lateSubmission.toMap(), SetOptions(merge: true));
          return;
        } catch (_) {
          // Jika tetap gagal (misal allowLateSubmission == false), rethrow error asli
          rethrow;
        }
      }
      debugPrint('Gagal submit assignment: $e');
      rethrow;
    }
  }

  /// Memberikan nilai dan umpan balik (Dosen)
  Future<void> gradeSubmission({
    required String classId,
    required String assignmentId,
    required String submissionId,
    required double score,
    String? feedback,
    required String graderUid,
  }) async {
    if (score < 0 || score > 100) {
      throw ArgumentError('Nilai harus berada dalam rentang 0 hingga 100.');
    }

    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    try {
      final docRef = firestore
          .collection('classes')
          .doc(classId.trim())
          .collection('assignments')
          .doc(assignmentId.trim())
          .collection('submissions')
          .doc(submissionId.trim());

      await docRef.update({
        'status': SubmissionStatus.graded.value,
        'score': score,
        'feedback': feedback ?? '',
        'graded_by_uid': graderUid,
        'graded_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Gagal grade submission: $e');
      rethrow;
    }
  }
}

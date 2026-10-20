import 'package:cloud_firestore/cloud_firestore.dart';

enum SubmissionStatus {
  submitted('SUBMITTED'),
  late('LATE'),
  graded('GRADED');

  final String value;
  const SubmissionStatus(this.value);

  static SubmissionStatus fromString(String? val) {
    if (val == null || val.trim().isEmpty) return SubmissionStatus.submitted;
    final normalized = val.trim().toUpperCase();
    for (final e in SubmissionStatus.values) {
      if (e.value == normalized) return e;
    }
    return SubmissionStatus.submitted;
  }
}

class AssignmentSubmission {
  final String id;
  final String assignmentId;
  final String classId;
  final bool isGroup;
  final String? studentUid;
  final String? studentName;
  final String? groupId;
  final String? groupName;
  final List<String> contributorIds;
  final String submittedByUid;
  final String submittedByName;
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final String? note;
  final SubmissionStatus status;
  final double? score;
  final String? feedback;
  final String? gradedByUid;
  final DateTime? gradedAt;
  final DateTime? submittedAt;
  final DateTime? updatedAt;

  const AssignmentSubmission({
    required this.id,
    required this.assignmentId,
    required this.classId,
    required this.isGroup,
    this.studentUid,
    this.studentName,
    this.groupId,
    this.groupName,
    this.contributorIds = const [],
    required this.submittedByUid,
    required this.submittedByName,
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    this.note,
    this.status = SubmissionStatus.submitted,
    this.score,
    this.feedback,
    this.gradedByUid,
    this.gradedAt,
    this.submittedAt,
    this.updatedAt,
  });

  bool get isGraded => status == SubmissionStatus.graded && score != null;

  factory AssignmentSubmission.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String assignmentId,
    required String classId,
  }) {
    return AssignmentSubmission.fromMap(
      doc.data() ?? {},
      id: doc.id,
      assignmentId: assignmentId,
      classId: classId,
    );
  }

  factory AssignmentSubmission.fromMap(
    Map<String, dynamic> map, {
    required String id,
    required String assignmentId,
    required String classId,
  }) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final rawContributors = map['contributor_ids'];
    final List<String> contributors = [];
    if (rawContributors is List) {
      for (final c in rawContributors) {
        if (c != null) contributors.add(c.toString());
      }
    }

    return AssignmentSubmission(
      id: id,
      assignmentId: map['assignment_id'] as String? ?? assignmentId,
      classId: map['class_id'] as String? ?? classId,
      isGroup: map['is_group'] as bool? ?? false,
      studentUid: map['student_uid'] as String?,
      studentName: map['student_name'] as String?,
      groupId: map['group_id'] as String?,
      groupName: map['group_name'] as String?,
      contributorIds: contributors,
      submittedByUid: map['submitted_by_uid'] as String? ?? '',
      submittedByName: map['submitted_by_name'] as String? ?? 'Mahasiswa',
      fileUrl: map['file_url'] as String? ?? '',
      fileName: map['file_name'] as String? ?? 'berkas_tugas',
      fileSize: (map['file_size'] as num?)?.toInt() ?? 0,
      note: map['note'] as String?,
      status: SubmissionStatus.fromString(map['status'] as String?),
      score: (map['score'] as num?)?.toDouble(),
      feedback: map['feedback'] as String?,
      gradedByUid: map['graded_by_uid'] as String?,
      gradedAt: parseDate(map['graded_at']),
      submittedAt: parseDate(map['submitted_at']),
      updatedAt: parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assignment_id': assignmentId,
      'class_id': classId,
      'is_group': isGroup,
      if (studentUid != null) 'student_uid': studentUid,
      if (studentName != null) 'student_name': studentName,
      if (groupId != null) 'group_id': groupId,
      if (groupName != null) 'group_name': groupName,
      'contributor_ids': contributorIds,
      'submitted_by_uid': submittedByUid,
      'submitted_by_name': submittedByName,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size': fileSize,
      if (note != null && note!.trim().isNotEmpty) 'note': note,
      'status': status.value,
      if (score != null) 'score': score,
      if (feedback != null) 'feedback': feedback,
      if (gradedByUid != null) 'graded_by_uid': gradedByUid,
      if (gradedAt != null) 'graded_at': Timestamp.fromDate(gradedAt!),
      'submitted_at': submittedAt != null ? Timestamp.fromDate(submittedAt!) : FieldValue.serverTimestamp(),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }
}

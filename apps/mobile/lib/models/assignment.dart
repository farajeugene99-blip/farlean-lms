import 'package:cloud_firestore/cloud_firestore.dart';

class Assignment {
  final String id;
  final String classId;
  final String? meetingId;
  final String title;
  final String instructions;
  final DateTime deadline;
  final bool allowLateSubmission;
  final bool isGroupAssignment;
  final List<String> allowedFileTypes;
  final int maxFileSizeMb;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Assignment({
    required this.id,
    required this.classId,
    this.meetingId,
    required this.title,
    this.instructions = '',
    required this.deadline,
    this.allowLateSubmission = true,
    this.isGroupAssignment = false,
    this.allowedFileTypes = const ['pdf', 'doc', 'docx', 'zip'],
    this.maxFileSizeMb = 10,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPastDeadline => DateTime.now().isAfter(deadline);

  factory Assignment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc, {required String classId}) {
    return Assignment.fromMap(doc.data() ?? {}, id: doc.id, classId: classId);
  }

  factory Assignment.fromMap(Map<String, dynamic> map, {required String id, required String classId}) {
    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? fallback;
      return fallback;
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final rawTypes = map['allowed_file_types'];
    final List<String> allowedTypes = [];
    if (rawTypes is List) {
      for (final t in rawTypes) {
        if (t != null) allowedTypes.add(t.toString().toLowerCase().replaceAll('.', ''));
      }
    }

    return Assignment(
      id: id,
      classId: map['class_id'] as String? ?? classId,
      meetingId: map['meeting_id'] as String?,
      title: map['title'] as String? ?? 'Tugas',
      instructions: map['instructions'] as String? ?? '',
      deadline: parseDate(map['deadline'], DateTime.now().add(const Duration(days: 7))),
      allowLateSubmission: map['allow_late_submission'] as bool? ?? true,
      isGroupAssignment: map['is_group_assignment'] as bool? ?? false,
      allowedFileTypes: allowedTypes.isNotEmpty ? allowedTypes : const ['pdf', 'doc', 'docx', 'zip'],
      maxFileSizeMb: (map['max_file_size_mb'] as num?)?.toInt() ?? 10,
      createdAt: parseNullableDate(map['created_at']),
      updatedAt: parseNullableDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'class_id': classId,
      if (meetingId != null && meetingId!.trim().isNotEmpty) 'meeting_id': meetingId,
      'title': title,
      'instructions': instructions,
      'deadline': Timestamp.fromDate(deadline),
      'allow_late_submission': allowLateSubmission,
      'is_group_assignment': isGroupAssignment,
      'allowed_file_types': allowedFileTypes,
      'max_file_size_mb': maxFileSizeMb,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  Assignment copyWith({
    String? title,
    String? instructions,
    DateTime? deadline,
    bool? allowLateSubmission,
    bool? isGroupAssignment,
    List<String>? allowedFileTypes,
    int? maxFileSizeMb,
    String? meetingId,
    DateTime? updatedAt,
  }) {
    return Assignment(
      id: id,
      classId: classId,
      meetingId: meetingId ?? this.meetingId,
      title: title ?? this.title,
      instructions: instructions ?? this.instructions,
      deadline: deadline ?? this.deadline,
      allowLateSubmission: allowLateSubmission ?? this.allowLateSubmission,
      isGroupAssignment: isGroupAssignment ?? this.isGroupAssignment,
      allowedFileTypes: allowedFileTypes ?? this.allowedFileTypes,
      maxFileSizeMb: maxFileSizeMb ?? this.maxFileSizeMb,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

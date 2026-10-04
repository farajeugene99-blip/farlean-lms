import 'package:cloud_firestore/cloud_firestore.dart';
import 'content_status.dart';

class Pretest {
  final String id;
  final String classId;
  final String meetingId;
  final String title;
  final int duration; // durasi dalam menit
  final DateTime? deadline;
  final int maxAttempts;
  final ContentStatus status;

  const Pretest({
    required this.id,
    required this.classId,
    required this.meetingId,
    required this.title,
    this.duration = 15,
    this.deadline,
    this.maxAttempts = 1,
    this.status = ContentStatus.draft,
  });

  factory Pretest.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Pretest.fromMap(doc.data() ?? {}, id: doc.id);
  }

  factory Pretest.fromMap(Map<String, dynamic> map, {required String id}) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return Pretest(
      id: id,
      classId: map['class_id'] as String? ?? '',
      meetingId: map['meeting_id'] as String? ?? '',
      title: map['title'] as String? ?? 'Pretest Baru',
      duration: (map['duration'] as num?)?.toInt() ?? 15,
      deadline: parseDate(map['deadline']),
      maxAttempts: (map['max_attempts'] as num?)?.toInt() ?? 1,
      status: ContentStatus.fromString(map['status'] as String?),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'class_id': classId,
      'meeting_id': meetingId,
      'title': title,
      'duration': duration,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'max_attempts': maxAttempts,
      'status': status.value,
    };
  }

  Pretest copyWith({
    String? title,
    int? duration,
    DateTime? deadline,
    int? maxAttempts,
    ContentStatus? status,
  }) {
    return Pretest(
      id: id,
      classId: classId,
      meetingId: meetingId,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      deadline: deadline ?? this.deadline,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      status: status ?? this.status,
    );
  }
}

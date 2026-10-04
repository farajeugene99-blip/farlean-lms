import 'package:cloud_firestore/cloud_firestore.dart';
import 'content_status.dart';

class Meeting {
  final String id;
  final String classId;
  final int number;
  final String title;
  final DateTime? date;
  final String? pretestId;
  final String? materiId;
  final String? videoId;
  final ContentStatus status;

  const Meeting({
    required this.id,
    required this.classId,
    required this.number,
    required this.title,
    this.date,
    this.pretestId,
    this.materiId,
    this.videoId,
    this.status = ContentStatus.draft,
  });

  factory Meeting.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Meeting.fromMap(doc.data() ?? {}, id: doc.id);
  }

  factory Meeting.fromMap(Map<String, dynamic> map, {required String id}) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return Meeting(
      id: id,
      classId: map['class_id'] as String? ?? '',
      number: (map['number'] as num?)?.toInt() ?? 1,
      title: map['title'] as String? ?? 'Pertemuan Baru',
      date: parseDate(map['date']),
      pretestId: map['pretest_id'] as String?,
      materiId: map['materi_id'] as String?,
      videoId: map['video_id'] as String?,
      status: ContentStatus.fromString(map['status'] as String?),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'class_id': classId,
      'number': number,
      'title': title,
      'date': date != null ? Timestamp.fromDate(date!) : null,
      'pretest_id': pretestId,
      'materi_id': materiId,
      'video_id': videoId,
      'status': status.value,
    };
  }

  Meeting copyWith({
    String? title,
    int? number,
    DateTime? date,
    String? pretestId,
    String? materiId,
    String? videoId,
    ContentStatus? status,
  }) {
    return Meeting(
      id: id,
      classId: classId,
      number: number ?? this.number,
      title: title ?? this.title,
      date: date ?? this.date,
      pretestId: pretestId ?? this.pretestId,
      materiId: materiId ?? this.materiId,
      videoId: videoId ?? this.videoId,
      status: status ?? this.status,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'content_status.dart';
import 'delta_sanitizer.dart';

class MaterialContent {
  final String id;
  final String meetingId;
  final String classId;
  final String title;
  final dynamic content; // Delta JSON Ops
  final String format; // 'delta'
  final List<String> attachments;
  final int version;
  final ContentStatus status;
  final String updatedBy;
  final DateTime? updatedAt;

  const MaterialContent({
    required this.id,
    required this.meetingId,
    required this.classId,
    required this.title,
    required this.content,
    this.format = 'delta',
    this.attachments = const [],
    this.version = 1,
    this.status = ContentStatus.draft,
    required this.updatedBy,
    this.updatedAt,
  });

  factory MaterialContent.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return MaterialContent.fromMap(doc.data() ?? {}, id: doc.id);
  }

  factory MaterialContent.fromMap(Map<String, dynamic> map, {required String id}) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final rawAttachments = map['attachments'];
    final List<String> parsedAttachments = [];
    if (rawAttachments is List) {
      for (final a in rawAttachments) {
        if (a != null) parsedAttachments.add(a.toString());
      }
    }

    return MaterialContent(
      id: id,
      meetingId: map['meeting_id'] as String? ?? '',
      classId: map['class_id'] as String? ?? '',
      title: map['title'] as String? ?? 'Materi Baru',
      content: map['content'] ?? [
        {'insert': '\n'}
      ],
      format: map['format'] as String? ?? 'delta',
      attachments: parsedAttachments,
      version: (map['version'] as num?)?.toInt() ?? 1,
      status: ContentStatus.fromString(map['status'] as String?),
      updatedBy: map['updated_by'] as String? ?? '',
      updatedAt: parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    // Validasi sanitasi sebelum serialisasi
    DeltaSanitizer.sanitizeOrThrow(content);

    return {
      'meeting_id': meetingId,
      'class_id': classId,
      'title': title,
      'content': content,
      'format': format,
      'attachments': attachments,
      'version': version,
      'status': status.value,
      'updated_by': updatedBy,
      'updated_at': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  MaterialContent copyWith({
    String? title,
    dynamic content,
    List<String>? attachments,
    int? version,
    ContentStatus? status,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return MaterialContent(
      id: id,
      meetingId: meetingId,
      classId: classId,
      title: title ?? this.title,
      content: content ?? this.content,
      format: format,
      attachments: attachments ?? this.attachments,
      version: version ?? this.version,
      status: status ?? this.status,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

enum DiscussionStatus {
  active('ACTIVE'),
  archived('ARCHIVED');

  final String value;
  const DiscussionStatus(this.value);

  static DiscussionStatus fromString(String? val) {
    if (val == null || val.trim().isEmpty) return DiscussionStatus.active;
    final normalized = val.trim().toUpperCase();
    for (final e in DiscussionStatus.values) {
      if (e.value == normalized) return e;
    }
    return DiscussionStatus.active;
  }
}

class Discussion {
  final String id;
  final String classId;
  final String title;
  final String body;
  final String authorId;
  final String authorDisplayName;
  final DiscussionStatus status;
  final int replyCount;
  final DateTime? lastActivityAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Discussion({
    required this.id,
    required this.classId,
    required this.title,
    required this.body,
    required this.authorId,
    required this.authorDisplayName,
    this.status = DiscussionStatus.active,
    this.replyCount = 0,
    this.lastActivityAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Discussion.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Discussion.fromMap(doc.data() ?? {}, id: doc.id);
  }

  factory Discussion.fromMap(Map<String, dynamic> map, {required String id}) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return Discussion(
      id: id,
      classId: map['class_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      authorId: map['author_id'] as String? ?? '',
      authorDisplayName: map['author_display_name'] as String? ?? 'Pengguna',
      status: DiscussionStatus.fromString(map['status'] as String?),
      replyCount: (map['reply_count'] as num?)?.toInt() ?? 0,
      lastActivityAt: parseDate(map['last_activity_at']),
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'class_id': classId,
      'title': title,
      'body': body,
      'author_id': authorId,
      'author_display_name': authorDisplayName,
      'status': status.value,
      'reply_count': replyCount,
      'last_activity_at': lastActivityAt != null ? Timestamp.fromDate(lastActivityAt!) : FieldValue.serverTimestamp(),
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  Discussion copyWith({
    String? title,
    String? body,
    DiscussionStatus? status,
    int? replyCount,
    DateTime? lastActivityAt,
    DateTime? updatedAt,
  }) {
    return Discussion(
      id: id,
      classId: classId,
      title: title ?? this.title,
      body: body ?? this.body,
      authorId: authorId,
      authorDisplayName: authorDisplayName,
      status: status ?? this.status,
      replyCount: replyCount ?? this.replyCount,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DiscussionReply {
  final String id;
  final String discussionId;
  final String authorId;
  final String authorDisplayName;
  final String body;
  final DiscussionStatus status;
  final String? parentId;
  final String? parentAuthorName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DiscussionReply({
    required this.id,
    required this.discussionId,
    required this.authorId,
    required this.authorDisplayName,
    required this.body,
    this.status = DiscussionStatus.active,
    this.parentId,
    this.parentAuthorName,
    this.createdAt,
    this.updatedAt,
  });

  factory DiscussionReply.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return DiscussionReply.fromMap(doc.data() ?? {}, id: doc.id);
  }

  factory DiscussionReply.fromMap(Map<String, dynamic> map, {required String id}) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return DiscussionReply(
      id: id,
      discussionId: map['discussion_id'] as String? ?? '',
      authorId: map['author_id'] as String? ?? '',
      authorDisplayName: map['author_display_name'] as String? ?? 'Pengguna',
      body: map['body'] as String? ?? '',
      status: DiscussionStatus.fromString(map['status'] as String?),
      parentId: map['parent_id'] as String?,
      parentAuthorName: map['parent_author_name'] as String?,
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'discussion_id': discussionId,
      'author_id': authorId,
      'author_display_name': authorDisplayName,
      'body': body,
      'status': status.value,
      if (parentId != null) 'parent_id': parentId,
      if (parentAuthorName != null) 'parent_author_name': parentAuthorName,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }
}

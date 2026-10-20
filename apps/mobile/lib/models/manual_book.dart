import 'package:cloud_firestore/cloud_firestore.dart';

class ManualBook {
  final String id;
  final String classId;
  final String title;
  final String description;
  final String fileUrl;
  final String fileName;
  final int fileSize; // bytes
  final String mimeType;
  final String status; // 'Published' | 'Draft' | 'Archived'
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;

  const ManualBook({
    required this.id,
    this.classId = 'SYSTEM',
    required this.title,
    this.description = '',
    required this.fileUrl,
    this.fileName = 'manual.pdf',
    this.fileSize = 0,
    this.mimeType = 'application/pdf',
    this.status = 'Published',
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.publishedAt,
  });

  bool get isPublished => status.toLowerCase() == 'published';
  bool get isDraft => status.toLowerCase() == 'draft';
  bool get isArchived => status.toLowerCase() == 'archived';

  factory ManualBook.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ManualBook.fromMap(doc.data() ?? {}, id: doc.id);
  }

  factory ManualBook.fromMap(Map<String, dynamic> map, {required String id}) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return ManualBook(
      id: id,
      classId: map['class_id'] as String? ?? 'SYSTEM',
      title: map['title'] as String? ?? 'Buku Panduan',
      description: map['description'] as String? ?? '',
      fileUrl: map['file_url'] as String? ?? '',
      fileName: map['file_name'] as String? ?? 'manual.pdf',
      fileSize: (map['file_size'] as num?)?.toInt() ?? 0,
      mimeType: map['mime_type'] as String? ?? 'application/pdf',
      status: map['status'] as String? ?? 'Published',
      createdBy: map['created_by'] as String?,
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
      publishedAt: parseDate(map['published_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'class_id': classId,
      'title': title,
      'description': description,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'status': status,
      if (createdBy != null && createdBy!.isNotEmpty) 'created_by': createdBy,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updated_at': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
      if (publishedAt != null) 'published_at': Timestamp.fromDate(publishedAt!),
    };
  }

  ManualBook copyWith({
    String? classId,
    String? title,
    String? description,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? mimeType,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
  }) {
    return ManualBook(
      id: id,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      description: description ?? this.description,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }
}

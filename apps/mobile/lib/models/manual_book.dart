import 'package:cloud_firestore/cloud_firestore.dart';

class ManualBook {
  final String id;
  final String classId;
  final String title;
  final String description;
  final String fileUrl;
  final String fileName;
  final int fileSize; // bytes
  final DateTime? createdAt;

  const ManualBook({
    required this.id,
    required this.classId,
    required this.title,
    required this.description,
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    this.createdAt,
  });

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
      classId: map['class_id'] as String? ?? '',
      title: map['title'] as String? ?? 'Buku Panduan',
      description: map['description'] as String? ?? '',
      fileUrl: map['file_url'] as String? ?? '',
      fileName: map['file_name'] as String? ?? 'manual.pdf',
      fileSize: (map['file_size'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(map['created_at']),
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
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}

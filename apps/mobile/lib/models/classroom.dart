import 'package:cloud_firestore/cloud_firestore.dart';

class Classroom {
  final String id;
  final String name;
  final String code;
  final String description;
  final String teacherId;
  final String status; // 'Active' | 'Archived'
  final String? membershipStatus; // 'active' | 'pending' | 'removed'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Classroom({
    required this.id,
    required this.name,
    this.code = '',
    this.description = '',
    required this.teacherId,
    this.status = 'Active',
    this.membershipStatus,
    this.createdAt,
    this.updatedAt,
  });

  bool get isArchived => status.toLowerCase() == 'archived';
  bool get isActive => status.toLowerCase() == 'active';
  bool get isMembershipPending => membershipStatus?.toLowerCase() == 'pending';
  bool get isMembershipActive => membershipStatus == null || membershipStatus?.toLowerCase() == 'active';
  bool get isMembershipRemoved => membershipStatus?.toLowerCase() == 'removed';

  factory Classroom.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Classroom.fromMap(data, id: doc.id);
  }

  factory Classroom.fromMap(Map<String, dynamic> map, {required String id}) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return Classroom(
      id: id,
      name: map['name'] as String? ?? 'Kelas Tanpa Nama',
      code: map['code'] as String? ?? '',
      description: map['description'] as String? ?? '',
      teacherId: map['teacher_id'] as String? ?? '',
      status: map['status'] as String? ?? 'Active',
      membershipStatus: map['membership_status'] as String?,
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'description': description,
      'teacher_id': teacherId,
      'status': status,
      if (membershipStatus != null) 'membership_status': membershipStatus,
      if (createdAt != null) 'created_at': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updated_at': Timestamp.fromDate(updatedAt!),
    };
  }

  Classroom copyWith({
    String? name,
    String? code,
    String? description,
    String? teacherId,
    String? status,
    String? membershipStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Classroom(
      id: id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      teacherId: teacherId ?? this.teacherId,
      status: status ?? this.status,
      membershipStatus: membershipStatus ?? this.membershipStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

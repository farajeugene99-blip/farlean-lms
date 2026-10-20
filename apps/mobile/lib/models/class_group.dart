import 'package:cloud_firestore/cloud_firestore.dart';

class ClassGroup {
  final String id;
  final String classId;
  final String name;
  final String? leaderUid;
  final List<String> memberUids;
  final Map<String, String> memberNames; // uid -> displayName
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ClassGroup({
    required this.id,
    required this.classId,
    required this.name,
    this.leaderUid,
    this.memberUids = const [],
    this.memberNames = const {},
    this.createdAt,
    this.updatedAt,
  });

  factory ClassGroup.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc, {required String classId}) {
    return ClassGroup.fromMap(doc.data() ?? {}, id: doc.id, classId: classId);
  }

  factory ClassGroup.fromMap(Map<String, dynamic> map, {required String id, required String classId}) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final rawUids = map['member_uids'];
    final List<String> memberUids = [];
    if (rawUids is List) {
      for (final u in rawUids) {
        if (u != null) memberUids.add(u.toString());
      }
    }

    final rawNames = map['member_names'];
    final Map<String, String> memberNames = {};
    if (rawNames is Map) {
      rawNames.forEach((k, v) {
        if (k != null && v != null) {
          memberNames[k.toString()] = v.toString();
        }
      });
    }

    return ClassGroup(
      id: id,
      classId: map['class_id'] as String? ?? classId,
      name: map['name'] as String? ?? 'Kelompok',
      leaderUid: map['leader_uid'] as String?,
      memberUids: memberUids,
      memberNames: memberNames,
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'class_id': classId,
      'name': name,
      if (leaderUid != null && leaderUid!.trim().isNotEmpty) 'leader_uid': leaderUid,
      'member_uids': memberUids,
      'member_names': memberNames,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  ClassGroup copyWith({
    String? name,
    String? leaderUid,
    bool clearLeader = false,
    List<String>? memberUids,
    Map<String, String>? memberNames,
    DateTime? updatedAt,
  }) {
    return ClassGroup(
      id: id,
      classId: classId,
      name: name ?? this.name,
      leaderUid: clearLeader ? null : (leaderUid ?? this.leaderUid),
      memberUids: memberUids ?? this.memberUids,
      memberNames: memberNames ?? this.memberNames,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

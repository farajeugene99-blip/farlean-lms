import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_user.dart';

enum MemberStatus {
  pending('pending'),
  active('active'),
  removed('removed');

  final String value;
  const MemberStatus(this.value);

  static MemberStatus fromString(String? val) {
    if (val == null) return MemberStatus.pending;
    return MemberStatus.values.firstWhere(
      (e) => e.value.toLowerCase() == val.toLowerCase(),
      orElse: () => MemberStatus.pending,
    );
  }
}

class ClassMember {
  final String uid;
  final String displayName;
  final AccountType accountType;
  final MemberStatus status;
  final DateTime? joinedAt;
  final String? nim;

  const ClassMember({
    required this.uid,
    required this.displayName,
    required this.accountType,
    required this.status,
    this.joinedAt,
    this.nim,
  });

  factory ClassMember.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ClassMember.fromMap(data, uid: doc.id);
  }

  factory ClassMember.fromMap(Map<String, dynamic> map, {required String uid}) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final nimRaw = map['nim'] as String?;
    return ClassMember(
      uid: uid,
      displayName: map['display_name'] as String? ?? 'Anggota',
      accountType: AccountType.fromString(map['account_type'] as String?),
      status: MemberStatus.fromString(map['status'] as String?),
      joinedAt: parseDate(map['joined_at']),
      nim: nimRaw != null && nimRaw.trim().isNotEmpty ? nimRaw.trim() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'display_name': displayName,
      'account_type': accountType.value,
      'status': status.value,
      'joined_at': joinedAt != null ? Timestamp.fromDate(joinedAt!) : FieldValue.serverTimestamp(),
      if (nim != null && nim!.trim().isNotEmpty) 'nim': nim,
    };
  }
}

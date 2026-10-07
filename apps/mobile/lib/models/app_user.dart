import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum AccountType {
  mahasiswa('MAHASISWA'),
  dosen('DOSEN'),
  umum('UMUM');

  final String value;
  const AccountType(this.value);

  static AccountType fromString(String? val) {
    if (val == null || val.trim().isEmpty) return AccountType.umum;
    final normalized = val.trim().toUpperCase();
    for (final e in AccountType.values) {
      if (e.value == normalized) return e;
    }
    debugPrint('⚠️ [AccountType] Nilai tipe akun tidak dikenal: "$val". Fallback aman ke UMUM.');
    return AccountType.umum;
  }
}

enum UserRole {
  user('USER'),
  guru('GURU'),
  admin('ADMIN');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String? val) {
    if (val == null || val.trim().isEmpty) return UserRole.user;
    final normalized = val.trim().toUpperCase();
    for (final e in UserRole.values) {
      if (e.value == normalized) return e;
    }
    debugPrint('⚠️ [UserRole] Nilai peran tidak dikenal: "$val". Fallback aman ke USER.');
    return UserRole.user;
  }
}

class AppUser {
  final String uid;
  final String name;
  final String email;
  final AccountType accountType;
  final UserRole role; // Mirror display dari Firestore users/{uid}.role
  final UserRole? claimsRole; // Source of Truth otoritas dari Firebase Auth Custom Claims (token.role)
  final String? photoUrl;
  final DateTime? lastActive;
  final bool mfaEnabled;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.accountType,
    required this.role,
    this.claimsRole,
    this.photoUrl,
    this.lastActive,
    this.mfaEnabled = false,
  });

  /// Peran efektif yang digunakan untuk otorisasi & gating fitur.
  /// Memprioritaskan custom claims (karena Security Rules & Backend mewajibkan token.role),
  /// fallback ke mirror Firestore jika claims belum ter-resolve.
  UserRole get effectiveRole => claimsRole ?? role;

  /// Memeriksa apakah terjadi split-brain antara token Custom Claims dan dokumen Firestore
  bool get isRoleOutOfSync => (claimsRole != null && claimsRole != role);

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser.fromMap(data, uid: doc.id);
  }

  factory AppUser.fromMap(Map<String, dynamic> map, {required String uid}) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return AppUser(
      uid: map['uid'] as String? ?? uid,
      name: map['name'] as String? ?? 'Pengguna',
      email: map['email'] as String? ?? '',
      accountType: AccountType.fromString(map['account_type'] as String?),
      role: UserRole.fromString(map['role'] as String?),
      photoUrl: map['photo_url'] as String?,
      lastActive: parseDate(map['last_active']),
      mfaEnabled: map['mfa_enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'account_type': accountType.value,
      'role': role.value,
      'photo_url': photoUrl,
      'last_active': lastActive != null ? Timestamp.fromDate(lastActive!) : FieldValue.serverTimestamp(),
      'mfa_enabled': mfaEnabled,
    };
  }

  AppUser copyWith({
    String? name,
    String? photoUrl,
    DateTime? lastActive,
    UserRole? claimsRole,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email,
      accountType: accountType,
      role: role,
      claimsRole: claimsRole ?? this.claimsRole,
      photoUrl: photoUrl ?? this.photoUrl,
      lastActive: lastActive ?? this.lastActive,
      mfaEnabled: mfaEnabled,
    );
  }
}

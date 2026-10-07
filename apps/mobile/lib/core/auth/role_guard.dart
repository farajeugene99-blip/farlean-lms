import '../../models/app_user.dart';

class RoleGuard {
  /// Memeriksa apakah user berwenang mengelola kelas (GURU atau ADMIN)
  /// Menggunakan effectiveRole (Source of Truth Custom Claims)
  static bool canManageClass(AppUser? user) {
    if (user == null) return false;
    return user.effectiveRole == UserRole.guru || user.effectiveRole == UserRole.admin;
  }

  /// Memeriksa apakah user memiliki hak akses sistem tingkat admin
  static bool canAccessAdmin(AppUser? user) {
    if (user == null) return false;
    return user.effectiveRole == UserRole.admin;
  }

  /// Memeriksa apakah user dapat bergabung kelas secara langsung dengan status ACTIVE
  /// Berdasarkan Blueprint: MAHASISWA & DOSEN langsung active, UMUM berstatus pending
  static bool canJoinClassInstantly(AppUser? user) {
    if (user == null) return false;
    return user.accountType == AccountType.mahasiswa ||
        user.accountType == AccountType.dosen;
  }

  /// Memeriksa apakah user adalah staff (GURU atau ADMIN)
  /// Menggunakan effectiveRole (Source of Truth Custom Claims)
  static bool isStaff(AppUser? user) {
    if (user == null) return false;
    return user.effectiveRole == UserRole.guru || user.effectiveRole == UserRole.admin;
  }
}

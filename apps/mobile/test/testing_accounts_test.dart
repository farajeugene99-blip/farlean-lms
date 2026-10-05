import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/auth/role_guard.dart';
import 'package:mobile/core/config/domain_map.dart';
import 'package:mobile/models/app_user.dart';

void main() {
  group('Testing Accounts Domain & Role Resolution Tests', () {
    const studentEmail = 'testing.student@farlean.edu';
    const teacherEmail = 'testing.teacher@dosen.farlean.edu';
    const generalEmail = 'testing.user@example.com';
    const unverifiedEmail = 'testing.unverified@example.com';
    const removedEmail = 'testing.removed@farlean.edu';

    test('Semua email akun testing ter-resolve ke AccountType yang tepat', () {
      // 1. TEST STUDENT: domain farlean.edu -> MAHASISWA
      expect(
        DomainMap.resolveAccountType(studentEmail),
        equals(AccountType.mahasiswa),
      );

      // 2. TEST TEACHER: domain dosen.farlean.edu -> DOSEN
      expect(
        DomainMap.resolveAccountType(teacherEmail),
        equals(AccountType.dosen),
      );

      // 3. TEST GENERAL USER: domain example.com -> UMUM
      expect(
        DomainMap.resolveAccountType(generalEmail),
        equals(AccountType.umum),
      );

      // 4. TEST UNVERIFIED USER: domain example.com -> UMUM
      expect(
        DomainMap.resolveAccountType(unverifiedEmail),
        equals(AccountType.umum),
      );

      // 5. TEST REMOVED STUDENT: domain farlean.edu -> MAHASISWA
      expect(
        DomainMap.resolveAccountType(removedEmail),
        equals(AccountType.mahasiswa),
      );
    });

    test('RoleGuard membedakan hak akses wewenang antara STUDENT dan TEACHER', () {
      const student = AppUser(
        uid: 'tqa_student_01',
        name: 'Test Student',
        email: studentEmail,
        accountType: AccountType.mahasiswa,
        role: UserRole.user,
      );

      const teacher = AppUser(
        uid: 'tqa_teacher_01',
        name: 'Test Teacher',
        email: teacherEmail,
        accountType: AccountType.dosen,
        role: UserRole.guru,
      );

      const general = AppUser(
        uid: 'tqa_general_01',
        name: 'Test General User',
        email: generalEmail,
        accountType: AccountType.umum,
        role: UserRole.user,
      );

      // Wewenang Kelola Kelas (Hanya GURU / ADMIN)
      expect(RoleGuard.canManageClass(teacher), isTrue);
      expect(RoleGuard.canManageClass(student), isFalse);
      expect(RoleGuard.canManageClass(general), isFalse);

      // Hak Gabung Instan (Hanya MAHASISWA dan DOSEN; UMUM berstatus pending)
      expect(RoleGuard.canJoinClassInstantly(student), isTrue);
      expect(RoleGuard.canJoinClassInstantly(teacher), isTrue);
      expect(RoleGuard.canJoinClassInstantly(general), isFalse);

      // Status Staff
      expect(RoleGuard.isStaff(teacher), isTrue);
      expect(RoleGuard.isStaff(student), isFalse);
    });
  });
}

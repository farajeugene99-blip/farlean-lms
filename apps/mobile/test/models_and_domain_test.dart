import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/auth/role_guard.dart';
import 'package:mobile/core/config/domain_map.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/models/class_member.dart';
import 'package:mobile/models/classroom.dart';

void main() {
  group('DomainMap Resolver Tests', () {
    test('Exact domain kampus.ac.id menghasilkan MAHASISWA', () {
      expect(
        DomainMap.resolveAccountType('budi@kampus.ac.id'),
        equals(AccountType.mahasiswa),
      );
    });

    test('Subdomain sah mhs.kampus.ac.id menghasilkan MAHASISWA', () {
      expect(
        DomainMap.resolveAccountType('siti@mhs.kampus.ac.id'),
        equals(AccountType.mahasiswa),
      );
    });

    test('Subdomain dosen.kampus.ac.id menghasilkan DOSEN', () {
      expect(
        DomainMap.resolveAccountType('dosen.eko@dosen.kampus.ac.id'),
        equals(AccountType.dosen),
      );
    });

    test('Domain penipu evilkampus.ac.id DITOLAK menjadi UMUM (Label Boundary Check)', () {
      expect(
        DomainMap.resolveAccountType('hacker@evilkampus.ac.id'),
        equals(AccountType.umum),
      );
    });

    test('Domain publik seperti gmail.com menghasilkan UMUM', () {
      expect(
        DomainMap.resolveAccountType('farlean@gmail.com'),
        equals(AccountType.umum),
      );
    });

    test('Case-insensitivity bekerja dengan benar', () {
      expect(
        DomainMap.resolveAccountType('BUDI@KAMPUS.AC.ID'),
        equals(AccountType.mahasiswa),
      );
    });

    test('Format email tidak valid atau null menghasilkan UMUM', () {
      expect(DomainMap.resolveAccountType(null), equals(AccountType.umum));
      expect(DomainMap.resolveAccountType(''), equals(AccountType.umum));
      expect(DomainMap.resolveAccountType('invalid-email'), equals(AccountType.umum));
    });
  });

  group('AppUser Model Tests', () {
    test('AppUser fromMap dan toMap bekerja dengan konsisten', () {
      final now = DateTime(2026, 10, 4, 12, 0, 0);
      final user = AppUser(
        uid: 'user_123',
        name: 'Ahmad Farhan',
        email: 'ahmad@kampus.ac.id',
        accountType: AccountType.mahasiswa,
        role: UserRole.user,
        photoUrl: 'https://example.com/avatar.jpg',
        lastActive: now,
        mfaEnabled: false,
      );

      final map = user.toMap();
      expect(map['uid'], equals('user_123'));
      expect(map['name'], equals('Ahmad Farhan'));
      expect(map['account_type'], equals('MAHASISWA'));
      expect(map['role'], equals('USER'));
      expect(map['mfa_enabled'], isFalse);

      final recreated = AppUser.fromMap(map, uid: 'user_123');
      expect(recreated.uid, equals('user_123'));
      expect(recreated.name, equals('Ahmad Farhan'));
      expect(recreated.accountType, equals(AccountType.mahasiswa));
      expect(recreated.role, equals(UserRole.user));
    });

    test('AccountType dan UserRole dipisahkan dan tidak digabung', () {
      const userDosenBukanGuru = AppUser(
        uid: 'dosen_1',
        name: 'Dr. Joko',
        email: 'joko@dosen.kampus.ac.id',
        accountType: AccountType.dosen,
        role: UserRole.user, // Dosen tetap role USER sampai diangkat GURU
      );

      expect(userDosenBukanGuru.accountType, equals(AccountType.dosen));
      expect(userDosenBukanGuru.role, equals(UserRole.user));
      expect(RoleGuard.canManageClass(userDosenBukanGuru), isFalse);
    });
  });

  group('Classroom & ClassMember Model Tests', () {
    test('Classroom serialisasi bekerja', () {
      final classroom = Classroom.fromMap({
        'name': 'Fisika Dasar',
        'teacher_id': 'teacher_01',
      }, id: 'class_01');

      expect(classroom.id, equals('class_01'));
      expect(classroom.name, equals('Fisika Dasar'));
      expect(classroom.teacherId, equals('teacher_01'));
    });

    test('ClassMember status enum diparse dengan benar', () {
      final memberActive = ClassMember.fromMap({
        'display_name': 'Budi',
        'account_type': 'MAHASISWA',
        'status': 'active',
      }, uid: 'uid_01');

      final memberPending = ClassMember.fromMap({
        'display_name': 'Rian',
        'account_type': 'UMUM',
        'status': 'pending',
      }, uid: 'uid_02');

      expect(memberActive.status, equals(MemberStatus.active));
      expect(memberPending.status, equals(MemberStatus.pending));
    });
  });

  group('RoleGuard Tests', () {
    test('canJoinClassInstantly hanya true untuk MAHASISWA dan DOSEN', () {
      const mhs = AppUser(
        uid: '1',
        name: 'Mhs',
        email: 'mhs@kampus.ac.id',
        accountType: AccountType.mahasiswa,
        role: UserRole.user,
      );
      const dosen = AppUser(
        uid: '2',
        name: 'Dsn',
        email: 'dsn@dosen.kampus.ac.id',
        accountType: AccountType.dosen,
        role: UserRole.user,
      );
      const umum = AppUser(
        uid: '3',
        name: 'Umum',
        email: 'user@gmail.com',
        accountType: AccountType.umum,
        role: UserRole.user,
      );

      expect(RoleGuard.canJoinClassInstantly(mhs), isTrue);
      expect(RoleGuard.canJoinClassInstantly(dosen), isTrue);
      expect(RoleGuard.canJoinClassInstantly(umum), isFalse);
    });

    test('canManageClass hanya true untuk GURU dan ADMIN', () {
      const guru = AppUser(
        uid: '1',
        name: 'Guru',
        email: 'guru@kampus.ac.id',
        accountType: AccountType.dosen,
        role: UserRole.guru,
      );
      const admin = AppUser(
        uid: '2',
        name: 'Admin',
        email: 'admin@kampus.ac.id',
        accountType: AccountType.umum,
        role: UserRole.admin,
      );
      const user = AppUser(
        uid: '3',
        name: 'User',
        email: 'user@kampus.ac.id',
        accountType: AccountType.mahasiswa,
        role: UserRole.user,
      );

      expect(RoleGuard.canManageClass(guru), isTrue);
      expect(RoleGuard.canManageClass(admin), isTrue);
      expect(RoleGuard.canManageClass(user), isFalse);
    });
  });
}

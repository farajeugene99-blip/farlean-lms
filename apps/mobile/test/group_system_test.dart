import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/models/class_group.dart';
import 'package:mobile/models/class_member.dart';
import 'package:mobile/models/classroom.dart';
import 'package:mobile/presentation/class/class_detail_screen.dart';
import 'package:mobile/repositories/class_repository.dart';
import 'package:mobile/repositories/group_repository.dart';
import 'package:mobile/repositories/meeting_repository.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:provider/provider.dart';

import 'session_pipeline_test.dart';

class MockClassRepoForGroup extends ClassRepository {
  final Classroom mockClass;
  final List<ClassMember> mockMembers;

  MockClassRepoForGroup({required this.mockClass, required this.mockMembers});

  @override
  Future<Classroom?> getClass(String classId) async => mockClass;

  @override
  Future<List<ClassMember>> getClassMembers(String classId) async => mockMembers;

  @override
  Future<Map<String, double>> getClassPretestScores(String classId) async => {};

  @override
  Future<Map<String, double>> getClassPosttestScores(String classId) async => {};

  @override
  Future<Map<String, double>> getStudentScores({
    required String classId,
    required String uid,
  }) async => {};
}

class MockGroupRepo extends GroupRepository {
  List<ClassGroup> groups;
  List<ClassMember> available;

  MockGroupRepo({required this.groups, required this.available});

  @override
  Future<List<ClassGroup>> getGroups(String classId) async => groups;

  @override
  Future<List<ClassMember>> getAvailableMembers(String classId) async => available;

  @override
  Future<String> createGroup({
    required String classId,
    required String name,
    String? leaderUid,
    required List<ClassMember> members,
  }) async {
    final newId = 'grp_${groups.length + 1}';
    final group = ClassGroup(
      id: newId,
      classId: classId,
      name: name,
      leaderUid: leaderUid,
      memberUids: members.map((m) => m.uid).toList(),
      memberNames: {for (final m in members) m.uid: m.displayName},
    );
    groups.add(group);
    return newId;
  }

  @override
  Future<void> createRandomizedGroups({
    required String classId,
    required List<ClassGroup> groups,
  }) async {
    this.groups.addAll(groups);
  }

  @override
  Future<void> deleteGroup({
    required String classId,
    required String groupId,
    required List<String> memberUids,
  }) async {
    groups.removeWhere((g) => g.id == groupId);
  }
}

AuthProvider _authForGroup({
  required String uid,
  required String email,
  required AccountType type,
  required UserRole role,
  required String name,
}) {
  final fakeUser = FakeUser(uid: uid, email: email);
  final mockAuth = MockAuthService(
    mockCurrentUser: fakeUser,
    mockProfileToReturn: AppUser(
      uid: uid,
      name: name,
      email: email,
      accountType: type,
      role: role,
    ),
  );
  return AuthProvider(authService: mockAuth);
}

void main() {
  group('ClassGroup & ClassMember Model Tests', () {
    test('ClassGroup serialisasi toMap dan fromMap konsisten', () {
      final now = DateTime(2026, 10, 20, 10, 0);
      final group = ClassGroup(
        id: 'g1',
        classId: 'c1',
        name: 'Kelompok Alpha',
        leaderUid: 'u1',
        memberUids: ['u1', 'u2'],
        memberNames: {'u1': 'Budi', 'u2': 'Siti'},
        createdAt: now,
      );

      final map = group.toMap();
      expect(map['class_id'], equals('c1'));
      expect(map['name'], equals('Kelompok Alpha'));
      expect(map['leader_uid'], equals('u1'));
      expect(map['member_uids'], equals(['u1', 'u2']));

      final fromMap = ClassGroup.fromMap(map, id: 'g1', classId: 'c1');
      expect(fromMap.id, equals('g1'));
      expect(fromMap.name, equals('Kelompok Alpha'));
      expect(fromMap.memberUids.length, equals(2));
      expect(fromMap.memberNames['u1'], equals('Budi'));
    });

    test('ClassMember groupId dan copyWith(clearGroupId) berfungsi tepat', () {
      const member = ClassMember(
        uid: 'm1',
        displayName: 'Rina',
        accountType: AccountType.mahasiswa,
        status: MemberStatus.active,
        groupId: 'grp_01',
      );

      expect(member.groupId, equals('grp_01'));
      final cleared = member.copyWith(clearGroupId: true);
      expect(cleared.groupId, isNull);

      final map = member.toMap();
      expect(map['group_id'], equals('grp_01'));

      final fromMap = ClassMember.fromMap(map, uid: 'm1');
      expect(fromMap.groupId, equals('grp_01'));
    });

    test('GroupRepository melempar ArgumentError jika parameter kosong', () {
      final repo = GroupRepository();
      expect(() => repo.createGroup(classId: '', name: 'G1', members: []), throwsArgumentError);
      expect(() => repo.createGroup(classId: 'c1', name: '', members: []), throwsArgumentError);
      expect(() => repo.deleteGroup(classId: '', groupId: 'g1', memberUids: []), throwsArgumentError);
    });
  });

  group('ClassDetailScreen Tab Kelompok Tests (Fitur E)', () {
    late Classroom testClass;
    late List<ClassMember> testMembers;
    late List<ClassGroup> testGroups;

    setUp(() {
      testClass = Classroom(
        id: 'c1',
        name: 'Pemrograman Flutter',
        code: 'FLUT123',
        teacherId: 'teacher_01',
        status: 'Active',
      );
      testMembers = [
        const ClassMember(
          uid: 'student_01',
          displayName: 'Budi Santoso',
          accountType: AccountType.mahasiswa,
          status: MemberStatus.active,
          groupId: 'g1',
        ),
        const ClassMember(
          uid: 'student_02',
          displayName: 'Siti Rahma',
          accountType: AccountType.mahasiswa,
          status: MemberStatus.active,
        ),
      ];
      testGroups = [
        const ClassGroup(
          id: 'g1',
          classId: 'c1',
          name: 'Kelompok 1 - Frontend',
          leaderUid: 'student_01',
          memberUids: ['student_01'],
          memberNames: {'student_01': 'Budi Santoso'},
        ),
      ];
    });

    testWidgets('1. Tab Kelompok menampilkan daftar kelompok dan ketua untuk pengajar', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = _authForGroup(
        uid: 'teacher_01',
        name: 'Dosen Pembimbing',
        email: 'dosen@farlean.edu',
        type: AccountType.dosen,
        role: UserRole.guru,
      );

      final groupRepo = MockGroupRepo(groups: List.from(testGroups), available: [testMembers[1]]);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: ClassDetailScreen(
              classId: 'c1',
              classRepository: MockClassRepoForGroup(mockClass: testClass, mockMembers: testMembers),
              meetingRepository: MeetingRepository(),
              groupRepository: groupRepo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // Buka tab Anggota Kelas lalu pilih sub-tab Kelompok
      await tester.tap(find.text('Anggota Kelas'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Kelompok'));
      await tester.pumpAndSettle();

      // Memastikan nama kelompok dan anggota tampil
      expect(find.text('Kelompok 1 - Frontend'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Ketua Kelompok'), findsOneWidget);
      // Tombol buat kelompok tersedia untuk dosen pemilik kelas
      expect(find.text('Buat Kelompok'), findsOneWidget);
    });

    testWidgets('2. Mahasiswa melihat kelompok dalam mode baca tanpa tombol hapus', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = _authForGroup(
        uid: 'student_01',
        name: 'Budi Santoso',
        email: 'budi@farlean.edu',
        type: AccountType.mahasiswa,
        role: UserRole.user,
      );

      final groupRepo = MockGroupRepo(groups: List.from(testGroups), available: []);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: ClassDetailScreen(
              classId: 'c1',
              classRepository: MockClassRepoForGroup(mockClass: testClass, mockMembers: testMembers),
              meetingRepository: MeetingRepository(),
              groupRepository: groupRepo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Anggota Kelas'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Kelompok'));
      await tester.pumpAndSettle();

      expect(find.text('Kelompok 1 - Frontend'), findsOneWidget);
      // Mahasiswa tidak melihat tombol hapus atau buat kelompok
      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
      expect(find.text('Buat Kelompok'), findsNothing);
    });
  });
}

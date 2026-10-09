import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/models/class_member.dart';
import 'package:mobile/models/classroom.dart';
import 'package:mobile/presentation/class/class_detail_screen.dart';
import 'package:mobile/repositories/class_repository.dart';
import 'package:mobile/repositories/meeting_repository.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:provider/provider.dart';

import 'session_pipeline_test.dart';

class MockClassRepoForNim extends ClassRepository {
  final Classroom mockClass;
  final List<ClassMember> mockMembers;

  MockClassRepoForNim({required this.mockClass, this.mockMembers = const []});

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

AuthProvider _authFor({required String uid, required String email, required AccountType type, required UserRole role, required String name}) {
  final fakeUser = FakeUser(uid: uid, email: email);
  final mockAuth = MockAuthService(
    mockCurrentUser: fakeUser,
    mockProfileToReturn: AppUser(uid: uid, name: name, email: email, accountType: type, role: role),
  );
  return AuthProvider(authService: mockAuth);
}

void main() {
  group('Class Members Conditional NIM Tests', () {
    late Classroom testClass;
    late List<ClassMember> testMembers;

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
          nim: '230000001',
        ),
        const ClassMember(
          uid: 'student_02',
          displayName: 'Siti Rahma',
          accountType: AccountType.mahasiswa,
          status: MemberStatus.active,
        ),
      ];
    });

    Future<void> pumpScreen(WidgetTester tester, AuthProvider authProvider) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: ClassDetailScreen(
              classId: 'c1',
              classRepository: MockClassRepoForNim(mockClass: testClass, mockMembers: testMembers),
              meetingRepository: MeetingRepository(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anggota Kelas'));
      await tester.pumpAndSettle();
    }

    testWidgets('1. Staf melihat baris NIM hanya untuk anggota yang mengisi NIM', (tester) async {
      await pumpScreen(
        tester,
        _authFor(
          uid: 'teacher_01',
          email: 'dosen@dosen.farlean.edu',
          type: AccountType.dosen,
          role: UserRole.guru,
          name: 'Dosen Pengampu',
        ),
      );

      expect(find.text('NIM: 230000001'), findsOneWidget);
      // Anggota tanpa NIM tidak menampilkan label NIM kosong/placeholder
      expect(find.textContaining('Siti Rahma'), findsOneWidget);
      expect(find.text('NIM: -'), findsNothing);
      expect(find.text('NIM: null'), findsNothing);
    });

    testWidgets('2. Mahasiswa peer tidak melihat NIM siapa pun', (tester) async {
      await pumpScreen(
        tester,
        _authFor(
          uid: 'student_01',
          email: 'budi@farlean.edu',
          type: AccountType.mahasiswa,
          role: UserRole.user,
          name: 'Budi Santoso',
        ),
      );

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.textContaining('NIM:'), findsNothing);
    });
  });
}

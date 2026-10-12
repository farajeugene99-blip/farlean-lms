import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/models/class_member.dart';
import 'package:mobile/models/classroom.dart';
import 'package:mobile/presentation/class/class_detail_screen.dart';
import 'package:mobile/presentation/main/profile_screen.dart';
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
        const ClassMember(
          uid: 'teacher_01',
          displayName: 'Dosen Pembimbing',
          accountType: AccountType.dosen,
          status: MemberStatus.active,
          nim: '198501012010011001',
        ),
        const ClassMember(
          uid: 'guest_01',
          displayName: 'Peserta Umum',
          accountType: AccountType.umum,
          status: MemberStatus.active,
        ),
      ];
    });

    Future<void> pumpScreen(WidgetTester tester, AuthProvider authProvider) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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

    testWidgets('1. Staf/Owner melihat NIM untuk Mahasiswa, NIP untuk Dosen, dan tidak ada label untuk Umum/kosong', (tester) async {
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

      // Mahasiswa dengan NIM -> 'NIM: 230000001'
      expect(find.text('NIM: 230000001'), findsOneWidget);
      // Dosen dengan NIP -> 'NIP: 198501012010011001'
      expect(find.text('NIP: 198501012010011001'), findsOneWidget);
      // Mahasiswa tanpa NIM tidak menampilkan label NIM kosong/placeholder
      expect(find.textContaining('Siti Rahma'), findsOneWidget);
      expect(find.text('NIM: -'), findsNothing);
      expect(find.text('NIM: null'), findsNothing);
      // Peserta UMUM tidak menampilkan identitas
      expect(find.textContaining('Peserta Umum'), findsOneWidget);
      expect(find.textContaining('NIM: Peserta Umum'), findsNothing);
      expect(find.textContaining('NIP: Peserta Umum'), findsNothing);
    });

    testWidgets('2. Mahasiswa peer tidak melihat NIM atau NIP siapa pun di daftar anggota', (tester) async {
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
      expect(find.text('Dosen Pembimbing'), findsOneWidget);
      expect(find.text('Peserta Umum'), findsOneWidget);
      expect(find.textContaining('NIM:'), findsNothing);
      expect(find.textContaining('NIP:'), findsNothing);
    });
  });

  group('ProfileScreen Dynamic Identity Label Tests (G2)', () {
    testWidgets('3. Akun MAHASISWA menampilkan label Nomor Induk (NIM)', (tester) async {
      final authProvider = _authFor(
        uid: 'mhs_01',
        email: 'mhs@farlean.edu',
        type: AccountType.mahasiswa,
        role: UserRole.user,
        name: 'Mahasiswa Pintar',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nomor Induk (NIM)'), findsOneWidget);
      expect(find.text('Nomor Induk (NIP)'), findsNothing);
    });

    testWidgets('4. Akun DOSEN menampilkan label Nomor Induk (NIP)', (tester) async {
      final authProvider = _authFor(
        uid: 'dsn_01',
        email: 'dosen@dosen.farlean.edu',
        type: AccountType.dosen,
        role: UserRole.guru,
        name: 'Dosen Teladan',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nomor Induk (NIP)'), findsOneWidget);
      expect(find.text('Nomor Induk (NIM)'), findsNothing);
    });

    testWidgets('5. Akun UMUM menyembunyikan baris Nomor Induk sepenuhnya', (tester) async {
      final authProvider = _authFor(
        uid: 'general_01',
        email: 'umum@gmail.com',
        type: AccountType.umum,
        role: UserRole.user,
        name: 'Pengguna Umum',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Nomor Induk'), findsNothing);
    });

    testWidgets('6. Profil yang belum selesai dimuat (appUser null) menyembunyikan baris nomor induk', (tester) async {
      final fakeUser = FakeUser(uid: 'loading_user', email: 'load@test.com');
      final mockAuth = MockAuthService(
        mockCurrentUser: fakeUser,
        mockProfileToReturn: null, // appUser will be null
      );
      final authProvider = AuthProvider(authService: mockAuth);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Baris identitas disembunyikan sampai profil selesai dimuat
      expect(find.textContaining('Nomor Induk'), findsNothing);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/models/class_member.dart';
import 'package:mobile/models/classroom.dart';
import 'package:mobile/models/content_status.dart';
import 'package:mobile/models/meeting.dart';
import 'package:mobile/presentation/class/class_detail_screen.dart';
import 'package:mobile/presentation/main/join_class_screen.dart';
import 'package:mobile/repositories/class_repository.dart';
import 'package:mobile/repositories/meeting_repository.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:mobile/services/class_provider.dart';
import 'package:mobile/services/join_class_service.dart';
import 'package:provider/provider.dart';

import 'session_pipeline_test.dart';

class _FakeClassRepo extends ClassRepository {
  final Classroom classroom;
  final List<ClassMember> members;

  _FakeClassRepo({
    required this.classroom,
    this.members = const [],
  });

  @override
  Future<Classroom?> getClass(String id) async => classroom;

  @override
  Future<List<ClassMember>> getClassMembers(String classId) async => members;

  @override
  Future<Map<String, double>> getClassPretestScores(String classId) async => const {};

  @override
  Future<Map<String, double>> getClassPosttestScores(String classId) async => const {};
}

class _FakeMeetingRepo extends MeetingRepository {
  final List<Meeting> meetings;
  _FakeMeetingRepo({this.meetings = const []});

  @override
  Future<List<Meeting>> getMeetingsByClass(String classId, {bool isStaff = false}) async => meetings;
}

class _FakeJoinClassService extends JoinClassService {
  final JoinClassResult resultToReturn;
  _FakeJoinClassService({required this.resultToReturn});

  @override
  Future<JoinClassResult> joinClass(String code) async => resultToReturn;
}

AuthProvider _createOwnerAuth() {
  final fakeUser = FakeUser(uid: 'owner_01', email: 'owner@farlean.edu');
  final mockAuth = MockAuthService(
    mockCurrentUser: fakeUser,
    mockProfileToReturn: const AppUser(
      uid: 'owner_01',
      name: 'Dosen Pemilik',
      email: 'owner@farlean.edu',
      accountType: AccountType.dosen,
      role: UserRole.guru,
    ),
  );
  return AuthProvider(authService: mockAuth);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testClass = Classroom(
    id: 'c_test_01',
    name: 'Kalkulus Lanjut {Tingkat 2}',
    code: 'KALK2026',
    teacherId: 'owner_01',
    description: 'Silabus matematika lanjut untuk program studi teknik.',
    status: 'Active',
  );

  Widget createClassDetailHarness({
    required Classroom classroom,
    Locale locale = const Locale('id'),
  }) {
    final classRepo = _FakeClassRepo(
      classroom: classroom,
      members: [
        ClassMember(
          uid: 'mhs_01',
          displayName: 'Budi Raharja',
          accountType: AccountType.mahasiswa,
          status: MemberStatus.active,
          nim: '2026001',
        ),
      ],
    );
    final meetingRepo = _FakeMeetingRepo(meetings: [
      Meeting(
        id: 'm_1',
        classId: classroom.id,
        number: 1,
        title: 'Integral Lipat',
        status: ContentStatus.published,
      ),
    ]);

    return MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: _createOwnerAuth()),
          ChangeNotifierProvider<ClassProvider>(create: (_) => ClassProvider()),
        ],
        child: ClassDetailScreen(
          classId: classroom.id,
          classRepository: classRepo,
          meetingRepository: meetingRepo,
        ),
      ),
    );
  }

  Widget createJoinClassHarness({
    required JoinClassResult result,
    Locale locale = const Locale('id'),
  }) {
    final joinService = _FakeJoinClassService(resultToReturn: result);
    return MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: _createOwnerAuth()),
          ChangeNotifierProvider<ClassProvider>(create: (_) => ClassProvider()),
        ],
        child: JoinClassScreen(joinClassService: joinService),
      ),
    );
  }

  // =========================================================================
  // 1. ClassDetailScreen Localization — ID vs EN
  // =========================================================================
  group('ClassDetailScreen Localization', () {
    testWidgets('Detail kelas menampilkan string Bahasa Indonesia', (tester) async {
      await tester.pumpWidget(createClassDetailHarness(classroom: testClass, locale: const Locale('id')));
      await tester.pumpAndSettle();

      expect(find.text('Kalkulus Lanjut {Tingkat 2}'), findsWidgets);
      expect(find.text('Active'), findsOneWidget); // Status domain raw
      expect(find.text('1 Anggota'), findsOneWidget);
      expect(find.text('•  1 Pertemuan'), findsOneWidget);

      expect(find.text('Pertemuan'), findsOneWidget);
      expect(find.text('Rekap Nilai'), findsOneWidget);
      expect(find.text('Anggota Kelas'), findsOneWidget);

      expect(find.text('Tambah Pertemuan'), findsOneWidget);
    });

    testWidgets('Detail kelas menampilkan string Bahasa Inggris', (tester) async {
      await tester.pumpWidget(createClassDetailHarness(classroom: testClass, locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Kalkulus Lanjut {Tingkat 2}'), findsWidgets);
      expect(find.text('Active'), findsOneWidget); // Status domain raw
      expect(find.text('1 Member'), findsOneWidget);
      expect(find.text('•  1 Meeting'), findsOneWidget);

      expect(find.text('Meetings'), findsOneWidget);
      expect(find.text('Gradebook'), findsOneWidget);
      expect(find.text('Class Members'), findsOneWidget);

      expect(find.text('Add Meeting'), findsOneWidget);
    });
  });

  // =========================================================================
  // 2. JoinClassScreen Localization — ID vs EN
  // =========================================================================
  group('JoinClassScreen Localization', () {
    testWidgets('Layar gabung kelas menampilkan string Bahasa Indonesia', (tester) async {
      final dummyResult = JoinClassResult(
        success: true,
        className: 'Algoritma Pemrograman',
        message: 'Permintaan bergabung berhasil diproses.',
        status: MemberStatus.active,
        classId: 'c_algo',
      );

      await tester.pumpWidget(createJoinClassHarness(result: dummyResult, locale: const Locale('id')));
      await tester.pumpAndSettle();

      expect(find.text('Gabung Kelas'), findsOneWidget);
      expect(find.text('Masukkan Kode Kelas'), findsOneWidget);
      expect(find.text('Gabung Sekarang'), findsOneWidget);

      // Submit form
      await tester.enterText(find.byType(TextFormField), 'ALGO2026');
      await tester.tap(find.text('Gabung Sekarang'));
      await tester.pumpAndSettle();

      expect(find.text('Berhasil Bergabung'), findsOneWidget);
      expect(find.text('Status: ACTIVE'), findsOneWidget);
      expect(find.text('Buka Kelas'), findsOneWidget);
    });

    testWidgets('Layar gabung kelas menampilkan string Bahasa Inggris', (tester) async {
      final dummyResult = JoinClassResult(
        success: true,
        className: 'Algorithms & Data',
        message: 'Your join request was received.',
        status: MemberStatus.pending,
        classId: 'c_algo',
      );

      await tester.pumpWidget(createJoinClassHarness(result: dummyResult, locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Join Class'), findsOneWidget);
      expect(find.text('Enter Class Code'), findsOneWidget);
      expect(find.text('Join Now'), findsOneWidget);

      // Submit form
      await tester.enterText(find.byType(TextFormField), 'ALGO2026');
      await tester.tap(find.text('Join Now'));
      await tester.pumpAndSettle();

      expect(find.text('Pending Approval'), findsOneWidget);
      expect(find.text('Status: PENDING'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
    });
  });

  // =========================================================================
  // 3. Responsive Narrow Screen Test (Poin 2 User Requirement)
  // =========================================================================
  group('ClassDetailScreen Responsive Layout Test', () {
    testWidgets('ClassDetailScreen pada layar sempit (320px, textScale 1.5, EN) tidak melempar RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 1000),
            textScaler: TextScaler.linear(1.5),
          ),
          child: createClassDetailHarness(
            classroom: testClass,
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  // =========================================================================
  // 4. Locale-Lock Protection Test
  // =========================================================================
  group('Class & Members Locale-Lock Protection', () {
    testWidgets('Tanpa override locale, layar tetap merender Bahasa Indonesia', (tester) async {
      final dummyResult = JoinClassResult(
        success: true,
        className: 'Sistem Operasi',
        message: 'Permintaan berhasil.',
        status: MemberStatus.active,
        classId: 'c_os',
      );

      await tester.pumpWidget(createJoinClassHarness(result: dummyResult, locale: const Locale('id')));
      await tester.pumpAndSettle();

      expect(find.text('Gabung Kelas'), findsOneWidget);
      expect(find.text('Join Class'), findsNothing);
    });
  });
}

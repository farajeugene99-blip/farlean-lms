import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/models/class_member.dart';
import 'package:mobile/models/classroom.dart';
import 'package:mobile/models/content_status.dart';
import 'package:mobile/models/material_content.dart';
import 'package:mobile/models/meeting.dart';
import 'package:mobile/presentation/class/class_detail_screen.dart';
import 'package:mobile/presentation/main/dashboard_screen.dart';
import 'package:mobile/presentation/material/material_editor_screen.dart';
import 'package:mobile/presentation/meeting/create_meeting_dialog.dart';
import 'package:mobile/presentation/meeting/meeting_list_screen.dart';
import 'package:mobile/repositories/class_repository.dart';
import 'package:mobile/repositories/meeting_repository.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:mobile/services/class_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'session_pipeline_test.dart';

// ---------------------------------------------------------------------------
// Mock Repositories
// ---------------------------------------------------------------------------

class _MockClassRepo extends ClassRepository {
  final Classroom mockClass;
  final List<ClassMember> mockMembers;
  final Map<String, double> mockPreScores;
  final Map<String, double> mockPostScores;
  final Map<String, double> mockPersonalScores;

  _MockClassRepo({
    required this.mockClass,
    this.mockMembers = const [],
    this.mockPreScores = const {},
    this.mockPostScores = const {},
    this.mockPersonalScores = const {},
  });

  @override
  Future<Map<String, List<Classroom>>> getMyClasses() async {
    return {
      'owned': [mockClass],
      'joined': [],
    };
  }

  @override
  Future<Classroom?> getClass(String classId) async => mockClass;

  @override
  Future<List<ClassMember>> getClassMembers(String classId) async => mockMembers;

  @override
  Future<Map<String, double>> getClassPretestScores(String classId) async => mockPreScores;

  @override
  Future<Map<String, double>> getClassPosttestScores(String classId) async => mockPostScores;

  @override
  Future<Map<String, double>> getStudentScores({
    required String classId,
    required String uid,
  }) async => mockPersonalScores;
}

class _MockMeetingRepo extends MeetingRepository {
  List<Meeting> meetings;
  int createCallCount = 0;
  Meeting? lastCreatedMeeting;

  _MockMeetingRepo({this.meetings = const []});

  @override
  Future<List<Meeting>> getMeetingsByClass(String classId, {bool isStaff = false}) async {
    return meetings;
  }

  @override
  Future<int> getMeetingCount(String classId, {bool isStaff = false}) async {
    return meetings.length;
  }

  @override
  Future<int> syncScheduledMeetings({String? classId}) async => 0;

  @override
  Future<String> createMeeting(Meeting meeting) async {
    createCallCount++;
    lastCreatedMeeting = meeting;
    final newMeeting = Meeting(
      id: 'm_${meetings.length + 1}',
      classId: meeting.classId,
      number: meeting.number,
      title: meeting.title,
      date: meeting.date,
      status: meeting.status,
    );
    meetings = [...meetings, newMeeting];
    return newMeeting.id;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

AuthProvider _createStaffAuth(String uid) {
  final fakeUser = FakeUser(uid: uid, email: 'dosen@farlean.edu');
  final mockAuth = MockAuthService(
    mockCurrentUser: fakeUser,
    mockProfileToReturn: AppUser(
      uid: uid,
      name: 'Dosen Pembimbing',
      email: 'dosen@farlean.edu',
      accountType: AccountType.dosen,
      role: UserRole.guru,
    ),
  );
  return AuthProvider(authService: mockAuth);
}

Widget _wrapWithApp(Widget child, {AuthProvider? authProvider, ClassProvider? classProvider}) {
  final widgetTree = MaterialApp(
    theme: AppTheme.lightTheme,
    locale: const Locale('id'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      FlutterQuillLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );

  final auth = authProvider ?? _createStaffAuth('default_teacher');
  final clProvider = classProvider ?? ClassProvider();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<ClassProvider>.value(value: clProvider),
    ],
    child: widgetTree,
  );
}

// ---------------------------------------------------------------------------
// Main Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Classroom testClass;
  late List<Meeting> testMeetings;
  late List<ClassMember> testMembers;

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    testClass = Classroom(
      id: 'c_test_01',
      name: 'Pemrograman Piranti Bergerak',
      code: 'PPB2026',
      teacherId: 'teacher_01',
      status: 'Active',
      description: 'Kelas belajar Flutter responsif',
    );

    testMeetings = [
      Meeting(
        id: 'm1',
        classId: 'c_test_01',
        number: 1,
        title: 'Pengantar Flutter & Widget',
        pretestId: 'pre_01',
        posttestId: 'post_01',
        status: ContentStatus.published,
      ),
    ];

    testMembers = [
      const ClassMember(
        uid: 'student_01',
        displayName: 'Budi Santoso',
        accountType: AccountType.mahasiswa,
        status: MemberStatus.active,
        nim: '22051204001',
      ),
    ];
  });

  group('Poin 1: DashboardScreen Manage Class Button Row Overflow Tests', () {
    testWidgets('Dashboard class card does NOT throw RenderFlex overflow on 360px viewport', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final authProvider = _createStaffAuth('teacher_01');
      final classRepo = _MockClassRepo(mockClass: testClass);
      final classProvider = ClassProvider(classRepository: classRepo);

      await tester.pumpWidget(
        _wrapWithApp(
          const DashboardScreen(),
          authProvider: authProvider,
          classProvider: classProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Kelola Kelas'), findsOneWidget);
      expect(find.text('PPB2026'), findsOneWidget);
    });

    testWidgets('Dashboard class card does NOT throw RenderFlex overflow on narrow 320px viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final authProvider = _createStaffAuth('teacher_01');
      final classRepo = _MockClassRepo(mockClass: testClass);
      final classProvider = ClassProvider(classRepository: classRepo);

      await tester.pumpWidget(
        _wrapWithApp(
          const DashboardScreen(),
          authProvider: authProvider,
          classProvider: classProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Kelola Kelas'), findsOneWidget);
      expect(find.text('PPB2026'), findsOneWidget);
    });
  });

  group('Poin 2: CreateMeetingDialog & Soft Refresh Tests', () {
    testWidgets('CreateMeetingDialog validates inputs and returns MeetingFormData on submit', (tester) async {
      MeetingFormData? resultData;

      await tester.pumpWidget(
        _wrapWithApp(
          Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  resultData = await showDialog<MeetingFormData>(
                    context: context,
                    builder: (ctx) => const CreateMeetingDialog(initialNumber: 3),
                  );
                },
                child: const Text('Buka Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Buat Pertemuan Baru'), findsOneWidget);
      expect(find.text('3'), findsOneWidget); // Nomor awal default

      // Coba simpan saat judul masih kosong -> validasi error
      await tester.tap(find.text('Simpan Pertemuan'));
      await tester.pumpAndSettle();
      expect(find.text('Judul wajib diisi'), findsOneWidget);
      expect(resultData, isNull);

      // Masukkan judul yang valid
      await tester.enterText(find.widgetWithText(TextFormField, 'Judul Pertemuan'), 'Pertemuan 3: State Management');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Simpan Pertemuan'));
      await tester.pumpAndSettle();

      // Dialog tertutup dan mengembalikan data
      expect(resultData, isNotNull);
      expect(resultData!.number, equals(3));
      expect(resultData!.title, equals('Pertemuan 3: State Management'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('ClassDetailScreen soft refresh does not reset _isLoading and avoids _dependents.isEmpty', (tester) async {
      final authProvider = _createStaffAuth('teacher_01');
      final classRepo = _MockClassRepo(mockClass: testClass, mockMembers: testMembers);
      final meetingRepo = _MockMeetingRepo(meetings: testMeetings);

      await tester.pumpWidget(
        _wrapWithApp(
          ClassDetailScreen(
            classId: 'c_test_01',
            classRepository: classRepo,
            meetingRepository: meetingRepo,
          ),
          authProvider: authProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pemrograman Piranti Bergerak'), findsWidgets);
      expect(find.text('Pengantar Flutter & Widget'), findsOneWidget);

      // Buka dialog tambah pertemuan via FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Buat Pertemuan Baru'), findsOneWidget);

      // Masukkan judul pertemuan baru
      await tester.enterText(find.widgetWithText(TextFormField, 'Judul Pertemuan'), 'Pertemuan 2: Layout Flutter');
      await tester.pumpAndSettle();

      // Simpan pertemuan
      await tester.tap(find.text('Simpan Pertemuan'));
      await tester.pumpAndSettle();

      // Pastikan repo berhasil dipanggil dan data baru ter-render tanpa exception
      expect(meetingRepo.createCallCount, equals(1));
      expect(meetingRepo.lastCreatedMeeting?.title, equals('Pertemuan 2: Layout Flutter'));
      expect(find.text('Pertemuan 2: Layout Flutter'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MeetingListScreen creates meeting and performs soft refresh safely', (tester) async {
      final authProvider = _createStaffAuth('teacher_01');
      final meetingRepo = _MockMeetingRepo(meetings: testMeetings);
      final classProvider = ClassProvider(classRepository: _MockClassRepo(mockClass: testClass));
      await classProvider.selectClass('c_test_01');

      await tester.pumpWidget(
        _wrapWithApp(
          MeetingListScreen(
            classId: 'c_test_01',
            meetingRepository: meetingRepo,
          ),
          authProvider: authProvider,
          classProvider: classProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pengantar Flutter & Widget'), findsOneWidget);

      // Buka dialog via FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Buat Pertemuan Baru'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Judul Pertemuan'), 'Pertemuan 2: Widget Tree');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Simpan Draft'));
      await tester.pumpAndSettle();

      expect(meetingRepo.createCallCount, equals(1));
      expect(find.text('Pertemuan 2: Widget Tree'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Poin 3: MaterialEditorScreen AppBar Overflow Tests', () {
    testWidgets('MaterialEditorScreen AppBar renders without 63px overflow on 360px viewport', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const existingMaterial = MaterialContent(
        id: 'mat_01',
        meetingId: 'm1',
        classId: 'c_test_01',
        title: 'Materi Bab 1 Flutter',
        content: [
          {'insert': 'Konten materi lengkap.\n'}
        ],
        updatedBy: 'teacher_01',
      );

      await tester.pumpWidget(
        _wrapWithApp(
          const MaterialEditorScreen(
            materiId: 'mat_01',
            initialMaterial: existingMaterial,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Edit Materi'), findsOneWidget);
      expect(find.byIcon(Icons.save_outlined), findsOneWidget);
      expect(find.text('Publikasikan'), findsOneWidget);
    });

    testWidgets('MaterialEditorScreen AppBar renders without overflow on narrow 320px viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrapWithApp(
          const MaterialEditorScreen(materiId: 'new'),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Buat Materi Baru'), findsOneWidget);
      expect(find.byIcon(Icons.save_outlined), findsOneWidget);
      expect(find.text('Publikasikan'), findsOneWidget);
    });
  });

  group('Poin 4: ClassDetailScreen Rekap Nilai _buildScoreChip Overflow Tests', () {
    testWidgets('Rekap nilai with uncompleted modules does NOT overflow 26px on 360px viewport', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final authProvider = _createStaffAuth('teacher_01');
      // Siswa belum memiliki skor (belum mengerjakan pretest dan posttest)
      final classRepo = _MockClassRepo(
        mockClass: testClass,
        mockMembers: testMembers,
        mockPreScores: {},
        mockPostScores: {},
      );
      final meetingRepo = _MockMeetingRepo(meetings: testMeetings);

      await tester.pumpWidget(
        _wrapWithApp(
          ClassDetailScreen(
            classId: 'c_test_01',
            classRepository: classRepo,
            meetingRepository: meetingRepo,
          ),
          authProvider: authProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Pindah ke tab Rekap Nilai (tab index 1)
      await tester.tap(find.text('Rekap Nilai'));
      await tester.pumpAndSettle();

      // Pilih pertemuan 1 dari dropdown agar _buildScoreChip dirender berdampingan
      await tester.tap(find.text('Semua Pertemuan (Ringkasan)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pertemuan 1: Pengantar Flutter & Widget').last);
      await tester.pumpAndSettle();

      // Scroll ke bawah agar kartu member terlihat
      await tester.drag(find.byType(ListView).last, const Offset(0, -300));
      await tester.pumpAndSettle();

      // Verifikasi skor "Belum Ada" dirender tanpa RenderFlex overflow
      expect(find.textContaining('Belum Ada'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Rekap nilai with uncompleted modules does NOT overflow on narrow 320px viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final authProvider = _createStaffAuth('teacher_01');
      final classRepo = _MockClassRepo(
        mockClass: testClass,
        mockMembers: testMembers,
        mockPreScores: {},
        mockPostScores: {},
      );
      final meetingRepo = _MockMeetingRepo(meetings: testMeetings);

      await tester.pumpWidget(
        _wrapWithApp(
          ClassDetailScreen(
            classId: 'c_test_01',
            classRepository: classRepo,
            meetingRepository: meetingRepo,
          ),
          authProvider: authProvider,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rekap Nilai'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Semua Pertemuan (Ringkasan)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pertemuan 1: Pengantar Flutter & Widget').last);
      await tester.pumpAndSettle();

      // Scroll ke bawah agar kartu member terlihat
      await tester.drag(find.byType(ListView).last, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.textContaining('Belum Ada'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}

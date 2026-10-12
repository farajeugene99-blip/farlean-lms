import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/models/content_status.dart';
import 'package:mobile/models/meeting.dart';
import 'package:mobile/presentation/meeting/meeting_detail_screen.dart';
import 'package:mobile/presentation/meeting/meeting_list_screen.dart';
import 'package:mobile/presentation/meeting/meeting_status_localization.dart';
import 'package:mobile/repositories/meeting_repository.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:mobile/services/class_provider.dart';
import 'package:provider/provider.dart';

import 'session_pipeline_test.dart';

class _FakeMeetingRepo extends MeetingRepository {
  final List<Meeting> meetings;

  _FakeMeetingRepo({this.meetings = const []});

  @override
  Future<List<Meeting>> getMeetingsByClass(String classId, {bool isStaff = false}) async {
    return meetings;
  }

  @override
  Future<Meeting?> getMeeting(String meetingId) async {
    return meetings.firstWhere((m) => m.id == meetingId);
  }
}

AuthProvider _createStaffAuth() {
  final fakeUser = FakeUser(uid: 'staff_01', email: 'guru@farlean.edu');
  final mockAuth = MockAuthService(
    mockCurrentUser: fakeUser,
    mockProfileToReturn: const AppUser(
      uid: 'staff_01',
      name: 'Guru Farlean',
      email: 'guru@farlean.edu',
      accountType: AccountType.dosen,
      role: UserRole.guru,
    ),
  );
  return AuthProvider(authService: mockAuth);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testMeeting = Meeting(
    id: 'm_1',
    classId: 'c_1',
    number: 1,
    title: 'Pengantar Sistem Informasi',
    description: 'Sesi perdana materi pengenalan sistem informasi.',
    materiId: 'mat_1',
    pretestId: 'pre_1',
    videoId: 'vid_1',
    posttestId: 'post_1',
    status: ContentStatus.published,
  );

  Widget createMeetingListHarness({
    required List<Meeting> meetings,
    Locale locale = const Locale('id'),
  }) {
    final repo = _FakeMeetingRepo(meetings: meetings);
    return MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: _createStaffAuth()),
          ChangeNotifierProvider<ClassProvider>(create: (_) => ClassProvider()),
        ],
        child: MeetingListScreen(
          classId: 'c_1',
          meetingRepository: repo,
        ),
      ),
    );
  }

  Widget createMeetingDetailHarness({
    required Meeting meeting,
    Locale locale = const Locale('id'),
  }) {
    final repo = _FakeMeetingRepo(meetings: [meeting]);
    return MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ChangeNotifierProvider<AuthProvider>.value(
        value: _createStaffAuth(),
        child: MeetingDetailScreen(
          meetingId: meeting.id,
          initialMeeting: meeting,
          meetingRepository: repo,
        ),
      ),
    );
  }

  // =========================================================================
  // 1. Status Localization Tests (4 Status + Fallback Raw Value)
  // =========================================================================
  group('MeetingStatusLocalization Tests', () {
    testWidgets('Semua 4 status dipetakan dengan benar di ID dan EN', (tester) async {
      late AppLocalizations idL10n;
      late AppLocalizations enL10n;

      await tester.pumpWidget(MaterialApp(
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (ctx) {
          idL10n = AppLocalizations.of(ctx);
          return const SizedBox.shrink();
        }),
      ));

      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (ctx) {
          enL10n = AppLocalizations.of(ctx);
          return const SizedBox.shrink();
        }),
      ));

      // Pengujian Bahasa Indonesia
      expect(MeetingStatusLocalization.label(ContentStatus.draft, idL10n), equals('Draf'));
      expect(MeetingStatusLocalization.label(ContentStatus.scheduled, idL10n), equals('Terjadwal'));
      expect(MeetingStatusLocalization.label(ContentStatus.published, idL10n), equals('Dipublikasikan'));
      expect(MeetingStatusLocalization.label(ContentStatus.archived, idL10n), equals('Diarsipkan'));

      // Pengujian Bahasa Inggris
      expect(MeetingStatusLocalization.label(ContentStatus.draft, enL10n), equals('Draft'));
      expect(MeetingStatusLocalization.label(ContentStatus.scheduled, enL10n), equals('Scheduled'));
      expect(MeetingStatusLocalization.label(ContentStatus.published, enL10n), equals('Published'));
      expect(MeetingStatusLocalization.label(ContentStatus.archived, enL10n), equals('Archived'));

      // labelUpperCase
      expect(MeetingStatusLocalization.labelUpperCase(ContentStatus.draft, idL10n), equals('DRAF'));
      expect(MeetingStatusLocalization.labelUpperCase(ContentStatus.draft, enL10n), equals('DRAFT'));
    });

    testWidgets('Fallback status aman: nilai tidak dikenal menampilkan string mentah', (tester) async {
      late AppLocalizations idL10n;
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (ctx) {
          idL10n = AppLocalizations.of(ctx);
          return const SizedBox.shrink();
        }),
      ));

      // null -> '-'
      expect(MeetingStatusLocalization.label(null, idL10n), equals('-'));
      expect(MeetingStatusLocalization.fromRawString(null, idL10n), equals('-'));
      expect(MeetingStatusLocalization.fromRawString('', idL10n), equals('-'));

      // String status sah
      expect(MeetingStatusLocalization.fromRawString('scheduled', idL10n), equals('Terjadwal'));

      // String status anomali/kustom dari backend -> harus tampil mentah, bukan crash atau hilang
      expect(MeetingStatusLocalization.fromRawString('PENDING_REVIEW', idL10n), equals('PENDING_REVIEW'));
    });
  });

  // =========================================================================
  // 2. ICU Pluralisasi Sinkronisasi Jadwal
  // =========================================================================
  group('ICU Plural Sync Schedule Tests', () {
    testWidgets('ID: count 0, 1, dan >1 diformat dengan benar', (tester) async {
      late AppLocalizations idL10n;
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (ctx) {
          idL10n = AppLocalizations.of(ctx);
          return const SizedBox.shrink();
        }),
      ));

      expect(idL10n.meetingSyncScheduleSuccess(0), equals('Tidak ada pertemuan terjadwal yang jatuh tempo saat ini.'));
      expect(idL10n.meetingSyncScheduleSuccess(1), equals('1 pertemuan terjadwal yang jatuh tempo berhasil dipublikasikan.'));
      expect(idL10n.meetingSyncScheduleSuccess(4), equals('4 pertemuan terjadwal yang jatuh tempo berhasil dipublikasikan.'));
    });

    testWidgets('EN: count 0, 1, dan >1 diformat dengan benar (singular vs plural)', (tester) async {
      late AppLocalizations enL10n;
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (ctx) {
          enL10n = AppLocalizations.of(ctx);
          return const SizedBox.shrink();
        }),
      ));

      expect(enL10n.meetingSyncScheduleSuccess(0), equals('No due scheduled meetings at this time.'));
      expect(enL10n.meetingSyncScheduleSuccess(1), equals('1 due scheduled meeting was successfully published.'));
      expect(enL10n.meetingSyncScheduleSuccess(3), equals('3 due scheduled meetings were successfully published.'));
    });
  });

  // =========================================================================
  // 3. Real Screen Localization — ID
  // =========================================================================
  group('Meeting Real Screen — ID', () {
    testWidgets('MeetingListScreen menampilkan string Bahasa Indonesia', (tester) async {
      await tester.pumpWidget(createMeetingListHarness(
        meetings: [testMeeting],
        locale: const Locale('id'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Materi & Pertemuan'), findsOneWidget);
      expect(find.text('Tambah Pertemuan'), findsOneWidget);
      expect(find.text('Pertemuan 1'), findsOneWidget);
      expect(find.text('Dipublikasikan'), findsOneWidget);
      expect(find.text('Pretest'), findsOneWidget);
      expect(find.text('Materi'), findsOneWidget);
      expect(find.text('Video'), findsOneWidget);
    });

    testWidgets('MeetingDetailScreen menampilkan string Bahasa Indonesia', (tester) async {
      tester.view.physicalSize = const Size(600, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createMeetingDetailHarness(
        meeting: testMeeting,
        locale: const Locale('id'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Pertemuan 1'), findsWidgets);
      expect(find.text('Dipublikasikan'), findsOneWidget);
      expect(find.text('Modul Pembelajaran'), findsOneWidget);
      expect(find.text('Materi Pembelajaran'), findsOneWidget);
      expect(find.text('Kuis Pretest'), findsOneWidget);
      expect(find.text('Video Pembelajaran'), findsOneWidget);
      expect(find.text('Kuis Post Test'), findsOneWidget);
      expect(find.text('Buka Materi'), findsOneWidget);
    });
  });

  // =========================================================================
  // 4. Real Screen Localization — EN
  // =========================================================================
  group('Meeting Real Screen — EN', () {
    testWidgets('MeetingListScreen menampilkan string Bahasa Inggris', (tester) async {
      await tester.pumpWidget(createMeetingListHarness(
        meetings: [testMeeting],
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Materials & Meetings'), findsOneWidget);
      expect(find.text('Add Meeting'), findsOneWidget);
      expect(find.text('Meeting 1'), findsOneWidget);
      expect(find.text('Published'), findsOneWidget);
      expect(find.text('Pretest'), findsOneWidget);
      expect(find.text('Material'), findsOneWidget);
      expect(find.text('Video'), findsOneWidget);
    });

    testWidgets('MeetingDetailScreen menampilkan string Bahasa Inggris', (tester) async {
      tester.view.physicalSize = const Size(600, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createMeetingDetailHarness(
        meeting: testMeeting,
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Meeting 1'), findsWidgets);
      expect(find.text('Published'), findsOneWidget);
      expect(find.text('Learning Modules'), findsOneWidget);
      expect(find.text('Learning Material'), findsOneWidget);
      expect(find.text('Pretest Quiz'), findsOneWidget);
      expect(find.text('Learning Video'), findsOneWidget);
      expect(find.text('Post Test Quiz'), findsOneWidget);
      expect(find.text('Open Material'), findsOneWidget);
    });
  });

  // =========================================================================
  // 5. Locale-Lock Protection Test (Poin 9 Wajib Review)
  // =========================================================================
  group('Locale-Lock Protection — Real Screens stay in ID without override', () {
    testWidgets('Tanpa override locale, MeetingListScreen tetap menampilkan Bahasa Indonesia', (tester) async {
      final repo = _FakeMeetingRepo(meetings: [testMeeting]);

      // Pump dengan locale default 'id' yang merefleksikan LocaleProvider yang terkunci
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: _createStaffAuth()),
              ChangeNotifierProvider<ClassProvider>(create: (_) => ClassProvider()),
            ],
            child: MeetingListScreen(
              classId: 'c_1',
              meetingRepository: repo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi: Teks Indonesia tampil, teks Inggris tidak tampil
      expect(find.text('Materi & Pertemuan'), findsOneWidget);
      expect(find.text('Tambah Pertemuan'), findsOneWidget);
      expect(find.text('Pertemuan 1'), findsOneWidget);
      expect(find.text('Materials & Meetings'), findsNothing);
      expect(find.text('Add Meeting'), findsNothing);
      expect(find.text('Meeting 1'), findsNothing);
    });

    testWidgets('Tanpa override locale, MeetingDetailScreen tetap menampilkan Bahasa Indonesia', (tester) async {
      final repo = _FakeMeetingRepo(meetings: [testMeeting]);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: _createStaffAuth(),
            child: MeetingDetailScreen(
              meetingId: testMeeting.id,
              initialMeeting: testMeeting,
              meetingRepository: repo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi: Teks Indonesia tampil, teks Inggris tidak tampil
      expect(find.text('Modul Pembelajaran'), findsOneWidget);
      expect(find.text('Materi Pembelajaran'), findsOneWidget);
      expect(find.text('Learning Modules'), findsNothing);
      expect(find.text('Learning Material'), findsNothing);
    });

    testWidgets('MeetingDetailScreen pada layar sempit (320px, EN) tidak melempar RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createMeetingDetailHarness(
          meeting: testMeeting,
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/models/content_status.dart';
import 'package:mobile/models/meeting.dart';
import 'package:mobile/presentation/meeting/meeting_detail_screen.dart';
import 'package:mobile/presentation/meeting/meeting_list_screen.dart';
import 'package:mobile/repositories/meeting_repository.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:mobile/services/class_provider.dart';
import 'package:provider/provider.dart';

import 'session_pipeline_test.dart';

class MockMeetingRepoForScheduled extends MeetingRepository {
  final List<Meeting> mockMeetings;

  MockMeetingRepoForScheduled({this.mockMeetings = const []});

  @override
  Future<List<Meeting>> getMeetingsByClass(String classId, {bool isStaff = false}) async {
    return mockMeetings;
  }
}

AuthProvider _studentAuthProvider() {
  final fakeUser = FakeUser(uid: 'student_01', email: 'budi@farlean.edu');
  final mockAuth = MockAuthService(
    mockCurrentUser: fakeUser,
    mockProfileToReturn: AppUser(
      uid: 'student_01',
      name: 'Budi Mahasiswa',
      email: 'budi@farlean.edu',
      accountType: AccountType.mahasiswa,
      role: UserRole.user,
    ),
  );
  return AuthProvider(authService: mockAuth);
}

void main() {
  group('Scheduled Publish Meeting Tests', () {
    test('Meeting serialization roundtrip preserves publish_at timestamp', () {
      final publishAt = DateTime(2026, 11, 15, 8, 0);
      final meeting = Meeting(
        id: 'm_sched',
        classId: 'c1',
        number: 3,
        title: 'Pertemuan Terjadwal',
        status: ContentStatus.scheduled,
        publishAt: publishAt,
      );

      final map = meeting.toMap();
      expect(map['status'], equals('Scheduled'));
      expect(map['publish_at'], isNotNull);

      final fromMap = Meeting.fromMap(map, id: 'm_sched');
      expect(fromMap.status, equals(ContentStatus.scheduled));
      expect(fromMap.publishAt, equals(publishAt));
    });

    test('Meeting toUpdateMap clears publish_at when status is Published or Draft', () {
      final published = Meeting(
        id: 'm1',
        classId: 'c1',
        number: 1,
        title: 'Pertemuan Rilis',
        status: ContentStatus.published,
        publishAt: DateTime(2026, 11, 15, 8, 0),
      );
      expect(published.toUpdateMap()['publish_at'], isNull);

      final draft = Meeting(
        id: 'm2',
        classId: 'c1',
        number: 2,
        title: 'Pertemuan Draft',
        status: ContentStatus.draft,
      );
      expect(draft.toUpdateMap()['publish_at'], isNull);
    });

    testWidgets('1. Detail pertemuan Scheduled menampilkan banner jadwal bagi mahasiswa', (tester) async {
      final futurePublish = DateTime.now().add(const Duration(days: 2));
      final scheduledMeeting = Meeting(
        id: 'm_sched',
        classId: 'c1',
        number: 3,
        title: 'Pertemuan Terjadwal',
        materiId: 'mat_01',
        pretestId: 'pre_01',
        status: ContentStatus.scheduled,
        publishAt: futurePublish,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: _studentAuthProvider(),
            child: MeetingDetailScreen(
              meetingId: 'm_sched',
              initialMeeting: scheduledMeeting,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pertemuan Terjadwal'), findsWidgets);
      expect(find.textContaining('Dijadwalkan terbit pada'), findsOneWidget);
    });

    testWidgets('2. Mahasiswa yang mengetuk modul terjadwal menerima pemberitahuan kunci, bukan navigasi', (tester) async {
      final futurePublish = DateTime.now().add(const Duration(days: 2));
      final scheduledMeeting = Meeting(
        id: 'm_sched',
        classId: 'c1',
        number: 3,
        title: 'Pertemuan Terjadwal',
        materiId: 'mat_01',
        status: ContentStatus.scheduled,
        publishAt: futurePublish,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: _studentAuthProvider(),
            child: MeetingDetailScreen(
              meetingId: 'm_sched',
              initialMeeting: scheduledMeeting,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buka Materi'));
      await tester.pump();

      expect(find.textContaining('masih berstatus Terjadwal'), findsOneWidget);
    });

    testWidgets('3. Daftar pertemuan menampilkan label Terbit untuk pertemuan Scheduled', (tester) async {
      final futurePublish = DateTime(2026, 12, 20, 8, 30);
      final repo = MockMeetingRepoForScheduled(mockMeetings: [
        Meeting(
          id: 'm_sched',
          classId: 'c1',
          number: 3,
          title: 'Pertemuan Terjadwal',
          status: ContentStatus.scheduled,
          publishAt: futurePublish,
        ),
        const Meeting(
          id: 'm_pub',
          classId: 'c1',
          number: 1,
          title: 'Pertemuan Rilis',
          status: ContentStatus.published,
        ),
      ]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: _studentAuthProvider()),
            ChangeNotifierProvider<ClassProvider>(create: (_) => ClassProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: MeetingListScreen(
              classId: 'c1',
              meetingRepository: repo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pertemuan Terjadwal'), findsOneWidget);
      expect(find.textContaining('Terbit:'), findsOneWidget);
      expect(find.text('Pertemuan Rilis'), findsOneWidget);
    });
  });
}

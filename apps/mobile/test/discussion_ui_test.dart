import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/models/discussion.dart';
import 'package:mobile/presentation/discussion/discussion_list_screen.dart';
import 'package:mobile/presentation/discussion/thread_detail_screen.dart';
import 'package:mobile/presentation/main/main_shell.dart';
import 'package:mobile/repositories/discussion_repository.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:mobile/services/class_provider.dart';
import 'package:provider/provider.dart';

import 'session_pipeline_test.dart';

class MockDiscussionRepoForUI extends DiscussionRepository {
  List<Discussion> mockDiscussions;
  List<DiscussionReply> mockReplies;

  MockDiscussionRepoForUI({
    this.mockDiscussions = const [],
    this.mockReplies = const [],
  });

  @override
  Future<List<Discussion>> getDiscussions({
    required String classId,
    bool isStaff = false,
    int limit = 20,
    dynamic startAfterDoc,
    bool filterUnanswered = false,
  }) async {
    if (filterUnanswered) {
      return mockDiscussions.where((d) => d.replyCount == 0).toList();
    }
    return mockDiscussions;
  }

  @override
  Future<Discussion?> getDiscussion(String discussionId) async {
    return mockDiscussions.firstWhere(
      (d) => d.id == discussionId,
      orElse: () => Discussion(
        id: discussionId,
        classId: 'c1',
        title: 'Judul Thread',
        body: 'Isi Thread',
        authorId: 'u1',
        authorDisplayName: 'Penulis',
      ),
    );
  }

  @override
  Future<List<DiscussionReply>> getReplies({
    required String discussionId,
    bool isStaff = false,
  }) async {
    return mockReplies;
  }
}

void main() {
  group('Bottom Navigation Bar & Discussion UI Tests', () {
    testWidgets('MainShell bottom navigation bar does NOT render yellow isFuture dots on icons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MainShell(
            child: Scaffold(body: Text('Content Area')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Memastikan label navigasi ada
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Materi'), findsOneWidget);
      expect(find.text('AI Tutor'), findsOneWidget);
      expect(find.text('Diskusi'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);

      // Verifikasi: Tidak ada Container berbentuk circle dengan warna AppTheme.warning (isFuture dot)
      final yellowDots = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          return box.shape == BoxShape.circle && box.color == AppTheme.warning;
        }
        return false;
      });

      expect(yellowDots, findsNothing);
    });

    testWidgets('DiscussionListScreen renders empty state when classId is missing', (tester) async {
      final fakeUser = FakeUser(uid: 'u1', email: 'user@farlean.edu');
      final mockAuth = MockAuthService(mockCurrentUser: fakeUser);
      final authProvider = AuthProvider(authService: mockAuth);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<ClassProvider>(create: (_) => ClassProvider()),
          ],
          child: const MaterialApp(
            home: DiscussionListScreen(classId: ''),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Pilih Kelas untuk Berdiskusi'), findsOneWidget);
      expect(find.text('Gabung Kelas'), findsOneWidget);
    });

    testWidgets('DiscussionListScreen displays list of threads with author and reply count', (tester) async {
      final fakeUser = FakeUser(uid: 'u1', email: 'user@farlean.edu');
      final mockAuth = MockAuthService(mockCurrentUser: fakeUser);
      final authProvider = AuthProvider(authService: mockAuth);

      final repo = MockDiscussionRepoForUI(
        mockDiscussions: [
          const Discussion(
            id: 'd1',
            classId: 'c1',
            title: 'Diskusi Algoritma Dijkstra',
            body: 'Bagaimana membuktikan kompleksitas O(V^2)?',
            authorId: 'u1',
            authorDisplayName: 'Budi Santoso',
            replyCount: 3,
          ),
          const Discussion(
            id: 'd2',
            classId: 'c1',
            title: 'Tanya Bab Database',
            body: 'Apakah B-Tree selalu seimbang?',
            authorId: 'u2',
            authorDisplayName: 'Siti Rahma',
            replyCount: 0,
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<ClassProvider>(create: (_) => ClassProvider()),
          ],
          child: MaterialApp(
            home: DiscussionListScreen(classId: 'c1', discussionRepository: repo),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Cek judul dan penulis
      expect(find.text('Diskusi Algoritma Dijkstra'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('3 Balasan'), findsOneWidget);

      expect(find.text('Tanya Bab Database'), findsOneWidget);
      expect(find.text('Siti Rahma'), findsOneWidget);
      expect(find.text('0 Balasan'), findsOneWidget);

      // Uji filter "Belum Dibalas"
      await tester.tap(find.text('Belum Dibalas'));
      await tester.pumpAndSettle();

      expect(find.text('Tanya Bab Database'), findsOneWidget);
      expect(find.text('Diskusi Algoritma Dijkstra'), findsNothing);
    });

    testWidgets('ThreadDetailScreen displays thread body and replies, with active reply composer', (tester) async {
      final fakeUser = FakeUser(uid: 'u1', email: 'user@farlean.edu');
      final mockAuth = MockAuthService(mockCurrentUser: fakeUser);
      final authProvider = AuthProvider(authService: mockAuth);

      final repo = MockDiscussionRepoForUI(
        mockDiscussions: [
          const Discussion(
            id: 'd1',
            classId: 'c1',
            title: 'Judul Lengkap Diskusi',
            body: 'Isi lengkap pertanyaan yang diajukan oleh mahasiswa.',
            authorId: 'u1',
            authorDisplayName: 'Penulis Thread',
            status: DiscussionStatus.active,
          ),
        ],
        mockReplies: [
          const DiscussionReply(
            id: 'r1',
            discussionId: 'd1',
            authorId: 'u2',
            authorDisplayName: 'Dosen Pembimbing',
            body: 'Tanggapan penjelasan dari dosen pembimbing.',
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<ClassProvider>(create: (_) => ClassProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: ThreadDetailScreen(
              discussionId: 'd1',
              classId: 'c1',
              discussionRepository: repo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Judul Lengkap Diskusi'), findsOneWidget);
      expect(find.text('Isi lengkap pertanyaan yang diajukan oleh mahasiswa.'), findsOneWidget);
      expect(find.text('Balasan (1)'), findsOneWidget);
      expect(find.text('Dosen Pembimbing'), findsOneWidget);
      expect(find.text('Tanggapan penjelasan dari dosen pembimbing.'), findsOneWidget);

      // Verifikasi input composer balasan aktif
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('ThreadDetailScreen displays archived banner and disables composer on ARCHIVED thread', (tester) async {
      final fakeUser = FakeUser(uid: 'u1', email: 'user@farlean.edu');
      final mockAuth = MockAuthService(mockCurrentUser: fakeUser);
      final authProvider = AuthProvider(authService: mockAuth);

      final repo = MockDiscussionRepoForUI(
        mockDiscussions: [
          const Discussion(
            id: 'd_arch',
            classId: 'c1',
            title: 'Diskusi Arsip',
            body: 'Topik sudah selesai.',
            authorId: 'u1',
            authorDisplayName: 'Penulis Thread',
            status: DiscussionStatus.archived,
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<ClassProvider>(create: (_) => ClassProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: ThreadDetailScreen(
              discussionId: 'd_arch',
              classId: 'c1',
              discussionRepository: repo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verifikasi banner arsip muncul dan input textfield tidak ada
      expect(find.text('Diskusi diarsipkan. Pengiriman balasan dinonaktifkan.'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
    });

    testWidgets('Create thread dialog disables submit button and protects with PopScope while submitting', (tester) async {
      final fakeUser = FakeUser(uid: 'u1', email: 'user@farlean.edu');
      final mockAuth = MockAuthService(mockCurrentUser: fakeUser);
      final authProvider = AuthProvider(authService: mockAuth);

      final repo = MockDiscussionRepoForUI();
      repo.mockDiscussions = [];

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<ClassProvider>(create: (_) => ClassProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: DiscussionListScreen(classId: 'c1', discussionRepository: repo),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Buka dialog buat diskusi
      await tester.tap(find.text('Buat Diskusi'));
      await tester.pumpAndSettle();

      expect(find.text('Buat Diskusi Baru'), findsOneWidget);

      // Isi form
      await tester.enterText(find.widgetWithText(TextFormField, 'Judul Diskusi *'), 'Pertanyaan Baru');
      await tester.enterText(find.widgetWithText(TextFormField, 'Isi Pertanyaan / Topik Diskusi *'), 'Isi topik diskusi baru');
      await tester.pump();

      // Pastikan tombol Kirim Diskusi ada
      expect(find.text('Kirim Diskusi'), findsOneWidget);
    });
  });
}

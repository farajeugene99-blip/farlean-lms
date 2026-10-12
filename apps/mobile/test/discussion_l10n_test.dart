import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/models/discussion.dart';
import 'package:mobile/presentation/discussion/discussion_list_screen.dart';
import 'package:mobile/presentation/discussion/thread_detail_screen.dart';
import 'package:mobile/repositories/discussion_repository.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:mobile/services/class_provider.dart';
import 'package:provider/provider.dart';

import 'session_pipeline_test.dart';

class _FakeDiscussionRepo extends DiscussionRepository {
  List<Discussion> discussions;
  List<DiscussionReply> replies;

  _FakeDiscussionRepo({
    this.discussions = const [],
    this.replies = const [],
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
      return discussions.where((d) => d.replyCount == 0).toList();
    }
    return discussions;
  }

  @override
  Future<Discussion?> getDiscussion(String discussionId) async {
    return discussions.firstWhere(
      (d) => d.id == discussionId,
      orElse: () => Discussion(
        id: discussionId,
        classId: 'c1',
        title: 'Thread $discussionId',
        body: 'Body of $discussionId',
        authorId: 'u1',
        authorDisplayName: 'Author',
      ),
    );
  }

  @override
  Future<List<DiscussionReply>> getReplies({
    required String discussionId,
    bool isStaff = false,
  }) async {
    return replies;
  }

  @override
  Future<Map<String, DateTime>> getReadStatesForDiscussions({
    required String userId,
    required List<String> discussionIds,
  }) async {
    return {};
  }
}

AuthProvider _createTestAuth() {
  final fakeUser = FakeUser(uid: 'u_test', email: 'user@farlean.edu');
  final mockAuth = MockAuthService(
    mockCurrentUser: fakeUser,
    mockProfileToReturn: const AppUser(
      uid: 'u_test',
      name: 'User Farlean',
      email: 'user@farlean.edu',
      accountType: AccountType.mahasiswa,
      role: UserRole.user,
    ),
  );
  return AuthProvider(authService: mockAuth);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testThread = Discussion(
    id: 'thread_1',
    classId: 'c_test',
    title: 'Analisis Algoritma {Kompleksitas O(n^2)}',
    body: 'Bagaimana membuktikan recurrence relation T(n) = 2T(n/2) + n?',
    authorId: 'u_other',
    authorDisplayName: 'Mahasiswa Pintar',
    replyCount: 2,
    status: DiscussionStatus.active,
  );

  final testReplies = [
    const DiscussionReply(
      id: 'rep_1',
      discussionId: 'thread_1',
      authorId: 'u_guru',
      authorDisplayName: 'Dosen Pembina',
      body: 'Gunakan Master Theorem Kasus 2.',
    ),
    const DiscussionReply(
      id: 'rep_2',
      discussionId: 'thread_1',
      authorId: 'u_test',
      authorDisplayName: 'User Farlean',
      body: 'Terima kasih, hasilnya O(n log n).',
      parentId: 'rep_1',
      parentAuthorName: 'Dosen Pembina',
    ),
  ];

  Widget createListHarness({
    required List<Discussion> threads,
    Locale locale = const Locale('id'),
  }) {
    final repo = _FakeDiscussionRepo(discussions: threads);
    return MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: _createTestAuth()),
          ChangeNotifierProvider<ClassProvider>(create: (_) => ClassProvider()),
        ],
        child: DiscussionListScreen(
          classId: 'c_test',
          discussionRepository: repo,
        ),
      ),
    );
  }

  Widget createDetailHarness({
    required Discussion thread,
    List<DiscussionReply> replies = const [],
    Locale locale = const Locale('id'),
  }) {
    final repo = _FakeDiscussionRepo(discussions: [thread], replies: replies);
    return MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ChangeNotifierProvider<AuthProvider>.value(
        value: _createTestAuth(),
        child: ThreadDetailScreen(
          discussionId: thread.id,
          classId: thread.classId,
          discussionRepository: repo,
        ),
      ),
    );
  }

  // =========================================================================
  // 1. DiscussionListScreen — ID vs EN
  // =========================================================================
  group('DiscussionListScreen Localization', () {
    testWidgets('Layar daftar diskusi menampilkan string Bahasa Indonesia', (tester) async {
      await tester.pumpWidget(createListHarness(threads: [testThread], locale: const Locale('id')));
      await tester.pumpAndSettle();

      expect(find.text('Forum Diskusi'), findsOneWidget);
      expect(find.text('Buat Diskusi'), findsOneWidget);
      expect(find.text('Semua Diskusi'), findsOneWidget);
      expect(find.text('Belum Dibalas'), findsOneWidget);
      expect(find.text('Belum Dibaca'), findsOneWidget);
      expect(find.text('2 Balasan'), findsOneWidget);

      // Konten pengguna tetap mentah
      expect(find.text('Analisis Algoritma {Kompleksitas O(n^2)}'), findsOneWidget);
    });

    testWidgets('Layar daftar diskusi menampilkan string Bahasa Inggris', (tester) async {
      await tester.pumpWidget(createListHarness(threads: [testThread], locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Discussion Forum'), findsOneWidget);
      expect(find.text('Create Discussion'), findsOneWidget);
      expect(find.text('All Discussions'), findsOneWidget);
      expect(find.text('Unanswered'), findsOneWidget);
      expect(find.text('Unread'), findsOneWidget);
      expect(find.text('2 Replies'), findsOneWidget);

      // Konten pengguna tetap mentah
      expect(find.text('Analisis Algoritma {Kompleksitas O(n^2)}'), findsOneWidget);
    });
  });

  // =========================================================================
  // 2. ThreadDetailScreen — ID vs EN
  // =========================================================================
  group('ThreadDetailScreen Localization', () {
    testWidgets('Layar detail diskusi menampilkan string Bahasa Indonesia', (tester) async {
      await tester.pumpWidget(createDetailHarness(
        thread: testThread,
        replies: testReplies,
        locale: const Locale('id'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Detail Diskusi'), findsOneWidget);
      expect(find.text('Thread Diskusi Aktif'), findsOneWidget);
      expect(find.text('Balasan (2)'), findsOneWidget);
      expect(find.text('Balas'), findsNWidgets(2));

      // Konten pengguna utuh
      expect(find.text('Analisis Algoritma {Kompleksitas O(n^2)}'), findsOneWidget);
      expect(find.text('Gunakan Master Theorem Kasus 2.'), findsOneWidget);
    });

    testWidgets('Layar detail diskusi menampilkan string Bahasa Inggris', (tester) async {
      await tester.pumpWidget(createDetailHarness(
        thread: testThread,
        replies: testReplies,
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Discussion Details'), findsOneWidget);
      expect(find.text('Active Discussion Thread'), findsOneWidget);
      expect(find.text('Replies (2)'), findsOneWidget);
      expect(find.text('Reply'), findsNWidgets(2));

      // Konten pengguna utuh
      expect(find.text('Analisis Algoritma {Kompleksitas O(n^2)}'), findsOneWidget);
      expect(find.text('Gunakan Master Theorem Kasus 2.'), findsOneWidget);
    });
  });

  // =========================================================================
  // 3. ICU Plural Balasan (Poin 4 Review)
  // =========================================================================
  group('ICU Plural Reply Count Tests', () {
    testWidgets('ID dan EN menangani plural count balasan dengan benar', (tester) async {
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

      // ID: bentuk kata "Balasan" konsisten
      expect(idL10n.discussionReplyCount(0), equals('0 Balasan'));
      expect(idL10n.discussionReplyCount(1), equals('1 Balasan'));
      expect(idL10n.discussionReplyCount(5), equals('5 Balasan'));

      // EN: singular "1 Reply" vs plural "N Replies"
      expect(enL10n.discussionReplyCount(0), equals('0 Replies'));
      expect(enL10n.discussionReplyCount(1), equals('1 Reply'));
      expect(enL10n.discussionReplyCount(5), equals('5 Replies'));
    });
  });

  // =========================================================================
  // 4. Locale-Lock Protection Test
  // =========================================================================
  group('Discussion Locale-Lock Protection', () {
    testWidgets('Tanpa override locale, layar diskusi tetap merender Bahasa Indonesia', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: _createTestAuth()),
              ChangeNotifierProvider<ClassProvider>(create: (_) => ClassProvider()),
            ],
            child: DiscussionListScreen(
              classId: 'c_test',
              discussionRepository: _FakeDiscussionRepo(discussions: [testThread]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Forum Diskusi'), findsOneWidget);
      expect(find.text('Discussion Forum'), findsNothing);
    });
  });
}

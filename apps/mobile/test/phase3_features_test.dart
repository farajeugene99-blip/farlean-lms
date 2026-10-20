import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/utils/delta_pdf_converter.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/models/discussion.dart';
import 'package:mobile/presentation/discussion/thread_detail_screen.dart';
import 'package:mobile/repositories/discussion_repository.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:provider/provider.dart';

import 'session_pipeline_test.dart';

class _FakeDiscussionRepoForPhase3 extends DiscussionRepository {
  final Discussion thread;
  final List<DiscussionReply> replies;

  _FakeDiscussionRepoForPhase3({required this.thread, required this.replies});

  @override
  Future<Discussion?> getDiscussion(String discussionId) async => thread;

  @override
  Future<List<DiscussionReply>> getReplies({required String discussionId, bool isStaff = false}) async => replies;

  @override
  Future<void> markAsRead({required String classId, required String discussionId}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeltaPdfConverter Tests (Fitur C)', () {
    test('1. Mengonversi Delta JSON dengan header, list, formatting, dan simbol Unicode ke format PDF yang valid', () async {
      // 1x1 transparent PNG byte dummy
      final dummyPngBytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
      );

      final deltaOps = [
        {'insert': 'Pengantar Algoritma'},
        {'insert': '\n', 'attributes': {'header': 1}},
        {'insert': 'Ini adalah '},
        {'insert': 'teks tebal', 'attributes': {'bold': true}},
        {'insert': ' dan '},
        {'insert': 'teks miring', 'attributes': {'italic': true}},
        {'insert': ' dengan simbol Unicode: • tanda peluru, → panah kanan, dan “kutip”.\n'},
        {'insert': 'Poin Pertama'},
        {'insert': '\n', 'attributes': {'list': 'bullet'}},
        {'insert': 'Poin Kedua'},
        {'insert': '\n', 'attributes': {'list': 'bullet'}},
        {'insert': 'Langkah 1'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
        {'insert': 'Langkah 2'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
        {'insert': 'console.log("Kode rapi");'},
        {'insert': '\n', 'attributes': {'code-block': true}},
        {'insert': 'Kutipan penting dari pakar.'},
        {'insert': '\n', 'attributes': {'blockquote': true}},
        {
          'insert': {
            'image': 'https://res.cloudinary.com/farlean/image/upload/sample.png',
          }
        },
      ];

      final pdfBytes = await DeltaPdfConverter.convertToPdf(
        title: 'Materi Struktur Data',
        subtitle: 'Pertemuan 1',
        deltaContent: deltaOps,
        imageLoader: (url) async => dummyPngBytes,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(500));
      // Verifikasi magic header PDF (%PDF-)
      final header = String.fromCharCodes(pdfBytes.take(5));
      expect(header, equals('%PDF-'));
    });
  });

  group('ThreadDetailScreen YouTube-style Collapse/Expand & Clean Mention (Fitur G)', () {
    late Discussion testThread;
    late List<DiscussionReply> testReplies;

    setUp(() {
      testThread = const Discussion(
        id: 'd_yt',
        classId: 'c1',
        title: 'Diskusi YouTube Pattern',
        body: 'Menguji apakah balasan anak tertutup secara default.',
        authorId: 'u1',
        authorDisplayName: 'Budi Santoso',
      );

      testReplies = [
        const DiscussionReply(
          id: 'rep_root',
          discussionId: 'd_yt',
          authorId: 'u_dosen',
          authorDisplayName: 'Dosen Pengampu',
          body: 'Ini adalah komentar utama (root).',
        ),
        const DiscussionReply(
          id: 'rep_child_1',
          discussionId: 'd_yt',
          authorId: 'u_student_1',
          authorDisplayName: 'Siti Rahma',
          body: 'Ini balasan anak ke-1.',
          parentId: 'rep_root',
          parentAuthorName: 'Dosen Pengampu',
        ),
        const DiscussionReply(
          id: 'rep_child_2',
          discussionId: 'd_yt',
          authorId: 'u_student_2',
          authorDisplayName: 'Agus Pratama',
          body: 'Ini balasan anak ke-2.',
          parentId: 'rep_root',
          parentAuthorName: 'Dosen Pengampu',
        ),
      ];
    });

    testWidgets('1. Balasan anak tertutup secara default dan terbuka saat tombol Lihat Balasan diketuk', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = AuthProvider(
        authService: MockAuthService(
          mockCurrentUser: FakeUser(uid: 'u_guest', email: 'guest@farlean.edu'),
          mockProfileToReturn: const AppUser(
            uid: 'u_guest',
            name: 'Tamu',
            email: 'guest@farlean.edu',
            accountType: AccountType.mahasiswa,
            role: UserRole.user,
          ),
        ),
      );

      final repo = _FakeDiscussionRepoForPhase3(thread: testThread, replies: testReplies);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: ThreadDetailScreen(
              discussionId: testThread.id,
              classId: testThread.classId,
              discussionRepository: repo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Komentar utama harus langsung tampak
      expect(find.text('Ini adalah komentar utama (root).'), findsOneWidget);

      // Balasan anak tertutup (collapsed) secara default
      expect(find.text('Ini balasan anak ke-1.'), findsNothing);
      expect(find.text('Ini balasan anak ke-2.'), findsNothing);
      expect(find.text('Lihat 2 balasan'), findsOneWidget);

      // Ketuk Lihat 2 balasan (Pola YouTube)
      await tester.tap(find.text('Lihat 2 balasan'));
      await tester.pumpAndSettle();

      // Balasan anak kini terbuka (expanded)
      expect(find.text('Ini balasan anak ke-1.'), findsOneWidget);
      expect(find.text('Ini balasan anak ke-2.'), findsOneWidget);
      expect(find.text('Sembunyikan balasan'), findsOneWidget);

      // Ketuk Sembunyikan balasan
      await tester.tap(find.text('Sembunyikan balasan'));
      await tester.pumpAndSettle();

      // Balasan anak kembali tersembunyi
      expect(find.text('Ini balasan anak ke-1.'), findsNothing);
      expect(find.text('Lihat 2 balasan'), findsOneWidget);
    });

    testWidgets('2. Mengetuk Balas pada balasan anak mengganti mention target bersih tanpa duplikasi', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = AuthProvider(
        authService: MockAuthService(
          mockCurrentUser: FakeUser(uid: 'u_guest', email: 'guest@farlean.edu'),
          mockProfileToReturn: const AppUser(
            uid: 'u_guest',
            name: 'Tamu',
            email: 'guest@farlean.edu',
            accountType: AccountType.mahasiswa,
            role: UserRole.user,
          ),
        ),
      );

      final repo = _FakeDiscussionRepoForPhase3(thread: testThread, replies: testReplies);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: ThreadDetailScreen(
              discussionId: testThread.id,
              classId: testThread.classId,
              discussionRepository: repo,
              defaultExpandReplies: true, // expand untuk uji interaksi mention
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Cari semua tombol Balas (3 tombol: root, child 1, child 2)
      final replyButtons = find.text('Balas');
      expect(replyButtons, findsNWidgets(3));

      // Ketuk Balas pada child 1 (Siti Rahma)
      await tester.tap(replyButtons.at(1));
      await tester.pumpAndSettle();

      final inputField = find.byType(TextFormField);
      expect(find.descendant(of: inputField, matching: find.text('@Siti Rahma ')), findsOneWidget);

      // Ketuk Balas pada child 2 (Agus Pratama) tanpa mengetik manual
      await tester.tap(replyButtons.at(2));
      await tester.pumpAndSettle();

      // Pastikan mention digantikan secara bersih dan tidak menjadi "@Siti Rahma @Agus Pratama "
      expect(find.descendant(of: inputField, matching: find.text('@Agus Pratama ')), findsOneWidget);
      expect(find.textContaining('@Siti Rahma @Agus Pratama'), findsNothing);
    });
  });
}

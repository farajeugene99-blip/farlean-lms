import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/models/video_item.dart';
import 'package:mobile/presentation/ai/ai_tutor_screen.dart';
import 'package:mobile/presentation/video/video_player_screen.dart';
import 'package:mobile/repositories/video_repository.dart';
import 'package:mobile/services/ai_service.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:provider/provider.dart';

import 'session_pipeline_test.dart';

class MockAiServiceForTest extends AiService {
  String tutorResponse;
  String videoDraftResponse;
  bool isExamLocked;
  int askTutorCallCount = 0;

  MockAiServiceForTest({
    this.tutorResponse = 'Ini adalah penjelasan konsep dari AI Tutor.',
    this.videoDraftResponse = 'Ini adalah draf deskripsi video dari AI.',
    this.isExamLocked = false,
  });

  @override
  Future<AiResponse> askTutor(String prompt) async {
    askTutorCallCount++;
    if (isExamLocked) {
      return const AiResponse(
        success: false,
        content: 'Fitur AI Tutor dinonaktifkan sementara saat Anda sedang menempuh sesi kuis/ujian.',
        isExamLocked: true,
      );
    }
    return AiResponse(
      success: true,
      content: tutorResponse,
      remainingQuota: 9,
    );
  }

  @override
  Future<String> generateVideoDescription({
    required String title,
    String? courseName,
    String? meetingTitle,
    String? keywords,
    String? existingDescription,
  }) async {
    return videoDraftResponse;
  }
}

class MockVideoRepoForTest extends VideoRepository {
  VideoItem? currentVideo;
  int updateCallCount = 0;

  MockVideoRepoForTest({this.currentVideo});

  @override
  Future<VideoItem?> getVideo(String videoId) async => currentVideo;

  @override
  Future<void> updateVideo(VideoItem video) async {
    updateCallCount++;
    currentVideo = video;
  }
}

AuthProvider _createAuth({
  required String uid,
  required UserRole role,
  required AccountType type,
}) {
  final fakeUser = FakeUser(uid: uid, email: '$uid@farlean.edu');
  final mockAuth = MockAuthService(
    mockCurrentUser: fakeUser,
    mockProfileToReturn: AppUser(
      uid: uid,
      name: 'User $uid',
      email: '$uid@farlean.edu',
      accountType: type,
      role: role,
    ),
  );
  return AuthProvider(authService: mockAuth);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VideoItem Model & Video Editing Tests (Fitur B)', () {
    test('1. VideoItem serialisasi title & description dengan kompatibilitas mundur', () {
      const video = VideoItem(
        id: 'v1',
        meetingId: 'm1',
        classId: 'c1',
        url: 'https://youtube.com/watch?v=sample',
        provider: VideoProvider.youtube,
        title: 'Pengenalan Algoritma',
        description: 'Video pengantar algoritma pemrograman.',
      );

      final map = video.toMap();
      expect(map['title'], equals('Pengenalan Algoritma'));
      expect(map['description'], equals('Video pengantar algoritma pemrograman.'));

      final fromMap = VideoItem.fromMap(map, id: 'v1');
      expect(fromMap.title, equals('Pengenalan Algoritma'));
      expect(fromMap.description, equals('Video pengantar algoritma pemrograman.'));

      // Backward compatibility jika map lama tidak punya title & description
      final legacyMap = {
        'meeting_id': 'm1',
        'class_id': 'c1',
        'url': 'https://youtube.com/watch?v=sample',
        'provider': 'youtube',
      };
      final fromLegacy = VideoItem.fromMap(legacyMap, id: 'v1');
      expect(fromLegacy.title, isEmpty);
      expect(fromLegacy.description, isEmpty);
    });

    testWidgets('2. Dosen dapat mengedit deskripsi video dan meminta draf AI', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = _createAuth(uid: 'teacher_1', role: UserRole.guru, type: AccountType.dosen);
      final initialVideo = const VideoItem(
        id: 'v_edit',
        meetingId: 'm1',
        classId: 'c1',
        url: 'https://res.cloudinary.com/farlean/sample_video.mp4',
        provider: VideoProvider.cloudinary,
        title: 'Video Awal',
        description: 'Deskripsi awal.',
      );

      final mockRepo = MockVideoRepoForTest(currentVideo: initialVideo);
      final mockAi = MockAiServiceForTest(videoDraftResponse: 'Deskripsi yang disusun otomatis oleh AI.');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: VideoPlayerScreen(
              videoId: 'v_edit',
              initialVideo: initialVideo,
              videoRepository: mockRepo,
              aiService: mockAi,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Judul dan deskripsi awal tampil
      expect(find.text('Video Awal'), findsOneWidget);
      expect(find.text('Deskripsi awal.'), findsOneWidget);

      // Tombol edit video untuk dosen di AppBar
      expect(find.byIcon(Icons.edit_note_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.edit_note_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Edit Video Pembelajaran'), findsOneWidget);
      expect(find.text('Bantu Buat Draf (AI)'), findsOneWidget);

      // Ketuk Bantu Buat Draf (AI)
      await tester.tap(find.text('Bantu Buat Draf (AI)'));
      await tester.pumpAndSettle();

      // Teks draf dari AI terisi ke TextFormField deskripsi
      expect(find.text('Deskripsi yang disusun otomatis oleh AI.'), findsOneWidget);

      // Simpan perubahan
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // Terverifikasi repository updateVideo dipanggil
      expect(mockRepo.updateCallCount, equals(1));
      expect(mockRepo.currentVideo?.description, equals('Deskripsi yang disusun otomatis oleh AI.'));
    });
  });

  group('AiTutorScreen Tests (Fitur F)', () {
    testWidgets('1. Guardrail 6: Layar AI Tutor dimulai tanpa fetch jaringan otomatis dan bebas overflow di 320px', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockAi = MockAiServiceForTest();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AiTutorScreen(aiService: mockAi),
        ),
      );

      await tester.pumpAndSettle();

      // Tidak ada pemanggilan API saat startup (Guardrail 6)
      expect(mockAi.askTutorCallCount, equals(0));

      // Sambutan pembuka lokal dan suggestion chips tampil
      expect(find.textContaining('Farlean AI Tutor'), findsOneWidget);
      expect(find.text('Jelaskan konsep Polymorphism dalam OOP'), findsOneWidget);

      // Bebas RenderFlex overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. Mahasiswa dapat mengirim pertanyaan dan menerima respon AI Tutor', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockAi = MockAiServiceForTest(tutorResponse: 'Polymorphism adalah kemampuan objek untuk memiliki banyak bentuk.');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AiTutorScreen(aiService: mockAi),
        ),
      );

      await tester.pumpAndSettle();

      // Masukkan pertanyaan
      await tester.enterText(find.byType(TextFormField), 'Apa itu Polymorphism?');
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pumpAndSettle();

      // Verifikasi askTutor dipanggil
      expect(mockAi.askTutorCallCount, equals(1));
      // Pertanyaan user dan jawaban AI tampil di chat
      expect(find.text('Apa itu Polymorphism?'), findsOneWidget);
      expect(find.text('Polymorphism adalah kemampuan objek untuk memiliki banyak bentuk.'), findsOneWidget);
    });

    testWidgets('3. Guardrail Ujian: Menampilkan pesan peringatan jika sesi ujian sedang aktif', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockAi = MockAiServiceForTest(isExamLocked: true);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AiTutorScreen(aiService: mockAi),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Bocorkan jawaban kuis nomor 1');
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pumpAndSettle();

      expect(find.textContaining('Fitur AI Tutor dinonaktifkan sementara saat Anda sedang menempuh sesi kuis/ujian.'), findsOneWidget);
    });
  });
}

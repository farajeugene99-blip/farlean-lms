import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/models/video_item.dart';
import 'package:mobile/presentation/common/error_view.dart';
import 'package:mobile/presentation/video/video_player_screen.dart';
import 'package:mobile/repositories/video_repository.dart';

class MockVideoRepositoryForL10n extends VideoRepository {
  final VideoItem? videoToReturn;
  final bool shouldThrow;

  MockVideoRepositoryForL10n({this.videoToReturn, this.shouldThrow = false});

  @override
  Future<VideoItem?> getVideo(String videoId) async {
    if (shouldThrow) {
      throw Exception('Network connection timed out');
    }
    return videoToReturn;
  }
}

void main() {
  group('VideoPlayerScreen Localization Tests', () {
    testWidgets('1. VideoPlayerScreen error state renders Indonesian UI chrome', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: VideoPlayerScreen(
            videoId: 'vid_not_found',
            videoRepository: MockVideoRepositoryForL10n(videoToReturn: null),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Video Pembelajaran'), findsOneWidget);
      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Video pembelajaran tidak ditemukan.'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('2. VideoPlayerScreen error state renders English UI chrome', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: VideoPlayerScreen(
            videoId: 'vid_not_found',
            videoRepository: MockVideoRepositoryForL10n(videoToReturn: null),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Learning Video'), findsOneWidget);
      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Learning video not found.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('3. VideoPlayerScreen load exception renders localized error with parameter in ID and EN', (tester) async {
      // Test Indonesian
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: VideoPlayerScreen(
            videoId: 'vid_error',
            videoRepository: MockVideoRepositoryForL10n(shouldThrow: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Gagal memuat video: Exception: Network connection timed out'), findsOneWidget);

      // Test English
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: VideoPlayerScreen(
            videoId: 'vid_error',
            videoRepository: MockVideoRepositoryForL10n(shouldThrow: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Failed to load video: Exception: Network connection timed out'), findsOneWidget);
    });

    test('4. ARB parity and accessors for video player error and playback', () {
      final idL10n = lookupAppLocalizations(const Locale('id'));
      final enL10n = lookupAppLocalizations(const Locale('en'));

      expect(idL10n.videoLoadingPlayer, equals('Memuat pemutar video...'));
      expect(enL10n.videoLoadingPlayer, equals('Loading video player...'));

      expect(idL10n.videoYoutubeUrlInvalid, equals('URL video YouTube tidak valid.'));
      expect(enL10n.videoYoutubeUrlInvalid, equals('Invalid YouTube video URL.'));

      expect(idL10n.videoPlaybackFailed('404'), contains('Gagal memutar video Cloudinary: 404'));
      expect(enL10n.videoPlaybackFailed('404'), contains('Failed to play Cloudinary video: 404'));
    });
  });
}

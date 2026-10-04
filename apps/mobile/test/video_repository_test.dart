import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/video_item.dart';
import 'package:mobile/repositories/video_repository.dart';

void main() {
  group('VideoRepository Validation Tests', () {
    late VideoRepository repository;

    setUp(() {
      repository = VideoRepository();
    });

    test('createVideo melempar ArgumentError jika URL kosong', () async {
      final invalidVideo = VideoItem(
        id: 'v1',
        meetingId: 'm1',
        classId: 'c1',
        url: '',
        provider: VideoProvider.youtube,
      );

      expect(
        () => repository.createVideo(invalidVideo),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createVideo melempar ArgumentError jika URL bukan http/https', () async {
      final invalidVideo = VideoItem(
        id: 'v1',
        meetingId: 'm1',
        classId: 'c1',
        url: 'ftp://example.com/video.mp4',
        provider: VideoProvider.cloudinary,
      );

      expect(
        () => repository.createVideo(invalidVideo),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('updateVideo melempar ArgumentError jika URL kosong', () async {
      final invalidVideo = VideoItem(
        id: 'v1',
        meetingId: 'm1',
        classId: 'c1',
        url: '   ',
        provider: VideoProvider.youtube,
      );

      expect(
        () => repository.updateVideo(invalidVideo),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('getVideo mengembalikan null secara aman saat Firestore uninitialized', () async {
      final video = await repository.getVideo('non_existent');
      expect(video, isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/content_status.dart';
import 'package:mobile/models/delta_sanitizer.dart';
import 'package:mobile/models/manual_book.dart';
import 'package:mobile/models/material_content.dart';
import 'package:mobile/models/meeting.dart';
import 'package:mobile/models/posttest.dart';
import 'package:mobile/models/pretest.dart';
import 'package:mobile/models/question.dart';
import 'package:mobile/models/test_attempt.dart';
import 'package:mobile/models/video_item.dart';

void main() {
  group('ContentStatus Tests', () {
    test('ContentStatus fromString handles case variations and defaults to draft', () {
      expect(ContentStatus.fromString('Published'), equals(ContentStatus.published));
      expect(ContentStatus.fromString('draft'), equals(ContentStatus.draft));
      expect(ContentStatus.fromString('ARCHIVED'), equals(ContentStatus.archived));
      expect(ContentStatus.fromString(null), equals(ContentStatus.draft));
      expect(ContentStatus.fromString('unknown'), equals(ContentStatus.draft));
    });
  });

  group('Meeting Model Tests', () {
    test('Meeting serialization stores reference IDs and status', () {
      final now = DateTime(2026, 10, 4, 10, 0);
      final meeting = Meeting(
        id: 'meeting_01',
        classId: 'class_01',
        number: 1,
        title: 'Pengantar Dart & Flutter',
        description: 'Pembahasan arsitektur Flutter',
        date: now,
        pretestId: 'pretest_01',
        materiId: 'materi_01',
        videoId: 'video_01',
        posttestId: 'posttest_01',
        status: ContentStatus.published,
      );

      final map = meeting.toMap();
      expect(map['class_id'], equals('class_01'));
      expect(map['number'], equals(1));
      expect(map['title'], equals('Pengantar Dart & Flutter'));
      expect(map['description'], equals('Pembahasan arsitektur Flutter'));
      expect(map['pretest_id'], equals('pretest_01'));
      expect(map['materi_id'], equals('materi_01'));
      expect(map['video_id'], equals('video_01'));
      expect(map['posttest_id'], equals('posttest_01'));
      expect(map['status'], equals('Published'));

      final fromMap = Meeting.fromMap(map, id: 'meeting_01');
      expect(fromMap.id, equals('meeting_01'));
      expect(fromMap.status, equals(ContentStatus.published));
      expect(fromMap.description, equals('Pembahasan arsitektur Flutter'));
      expect(fromMap.pretestId, equals('pretest_01'));
      expect(fromMap.posttestId, equals('posttest_01'));
    });

    test('Meeting toUpdateMap does not include null module IDs (prevents null overwrite)', () {
      const partialMeeting = Meeting(
        id: 'meeting_02',
        classId: 'class_01',
        number: 2,
        title: 'Pertemuan 2 Judul Revisi',
        description: 'Deskripsi baru',
        pretestId: null, // modul belum di-link di objek lokal
        materiId: null,
        videoId: null,
        posttestId: null,
        status: ContentStatus.draft,
      );

      final updateMap = partialMeeting.toUpdateMap();
      expect(updateMap['number'], equals(2));
      expect(updateMap['title'], equals('Pertemuan 2 Judul Revisi'));
      expect(updateMap['status'], equals('Draft'));
      // PASTIKAN: id modul null TIDAK dimasukkan ke dalam updateMap sehingga tautan modul aman dari overwrite
      expect(updateMap.containsKey('pretest_id'), isFalse);
      expect(updateMap.containsKey('materi_id'), isFalse);
      expect(updateMap.containsKey('video_id'), isFalse);
      expect(updateMap.containsKey('posttest_id'), isFalse);
    });

    test('Meeting Scheduled roundtrip preserves publish_at timestamp', () {
      final publishAt = DateTime(2026, 11, 15, 8, 0);
      final meeting = Meeting(
        id: 'meeting_sched',
        classId: 'class_01',
        number: 3,
        title: 'Pertemuan Terjadwal',
        status: ContentStatus.scheduled,
        publishAt: publishAt,
      );

      final map = meeting.toMap();
      expect(map['status'], equals('Scheduled'));
      expect(map['publish_at'], isNotNull);

      final fromMap = Meeting.fromMap(map, id: 'meeting_sched');
      expect(fromMap.status, equals(ContentStatus.scheduled));
      expect(fromMap.publishAt, equals(publishAt));
    });

    test('Meeting toUpdateMap clears publish_at on manual publish (cancels schedule)', () {
      final published = Meeting(
        id: 'meeting_pub',
        classId: 'class_01',
        number: 3,
        title: 'Pertemuan Rilis',
        status: ContentStatus.published,
        publishAt: DateTime(2026, 11, 15, 8, 0),
      );
      expect(published.toUpdateMap()['publish_at'], isNull);
    });
  });

  group('Posttest Model Tests', () {
    test('Posttest serialization stores duration and max_attempts', () {
      final now = DateTime(2026, 10, 4, 23, 59);
      final posttest = Posttest(
        id: 'posttest_01',
        classId: 'class_01',
        meetingId: 'meeting_01',
        title: 'Post Test Evaluasi',
        duration: 20,
        deadline: now,
        maxAttempts: 2,
        status: ContentStatus.published,
      );

      final map = posttest.toMap();
      expect(map['class_id'], equals('class_01'));
      expect(map['meeting_id'], equals('meeting_01'));
      expect(map['title'], equals('Post Test Evaluasi'));
      expect(map['duration'], equals(20));
      expect(map['max_attempts'], equals(2));
      expect(map['status'], equals('Published'));

      final recreated = Posttest.fromMap(map, id: 'posttest_01');
      expect(recreated.id, equals('posttest_01'));
      expect(recreated.duration, equals(20));
      expect(recreated.maxAttempts, equals(2));
      expect(recreated.status, equals(ContentStatus.published));
    });
  });

  group('Pretest & Question Model Tests', () {
    test('Pretest serialization handles duration and max_attempts', () {
      final pretest = Pretest(
        id: 'pretest_01',
        classId: 'class_01',
        meetingId: 'meeting_01',
        title: 'Kuis Pertemuan 1',
        duration: 20,
        maxAttempts: 2,
        status: ContentStatus.published,
      );

      final map = pretest.toMap();
      expect(map['duration'], equals(20));
      expect(map['max_attempts'], equals(2));
      expect(map['status'], equals('Published'));

      final recreated = Pretest.fromMap(map, id: 'pretest_01');
      expect(recreated.duration, equals(20));
      expect(recreated.maxAttempts, equals(2));
    });

    test('Question model stores text, options, points, tag without answer key leak', () {
      final question = Question(
        id: 'q_01',
        text: 'Manakah widget immutable di Flutter?',
        type: QuestionType.multipleChoice,
        options: ['StatefulWidget', 'StatelessWidget', 'InheritedModel', 'RenderObject'],
        points: 25,
        tag: 'flutter-widgets',
      );

      final map = question.toMap();
      expect(map['text'], contains('immutable'));
      expect(map['options'].length, equals(4));
      expect(map['points'], equals(25));
      expect(map['tag'], equals('flutter-widgets'));
      // Wajib: tidak ada key jawaban di map client
      expect(map.containsKey('correct'), isFalse);
      expect(map.containsKey('answer'), isFalse);
      expect(map.containsKey('explanation'), isFalse);

      final recreated = Question.fromMap(map, id: 'q_01');
      expect(recreated.id, equals('q_01'));
      expect(recreated.options.length, equals(4));
    });
  });

  group('TestAttempt Model Tests', () {
    test('TestAttempt preserves question order and answers', () {
      final attempt = TestAttempt(
        id: 'attempt_01',
        userId: 'user_01',
        testId: 'pretest_01',
        classId: 'class_01',
        attemptNo: 1,
        answers: {'q_01': 1, 'q_02': 3},
        questionOrder: ['q_02', 'q_01'],
        score: 100.0,
        status: AttemptStatus.submitted,
      );

      final map = attempt.toMap();
      expect(map['user_id'], equals('user_01'));
      expect(map['test_id'], equals('pretest_01'));
      expect(map['question_order'], equals(['q_02', 'q_01']));
      expect(map['answers']['q_01'], equals(1));
      expect(map['score'], equals(100.0));
      expect(map['status'], equals('submitted'));

      final fromMap = TestAttempt.fromMap(map, id: 'attempt_01');
      expect(fromMap.questionOrder, equals(['q_02', 'q_01']));
      expect(fromMap.status, equals(AttemptStatus.submitted));
    });
  });

  group('DeltaSanitizer Tests', () {
    test('Delta valid lolos sanitasi', () {
      final validDelta = [
        {'insert': 'Pengenalan Flutter\n', 'attributes': {'header': 1}},
        {'insert': 'Kunjungi situs '},
        {
          'insert': 'Flutter Resmi',
          'attributes': {'link': 'https://flutter.dev'},
        },
        {'insert': '\n'},
        {
          'insert': {'image': 'https://res.cloudinary.com/farlean/image/upload/sample.jpg'},
        },
      ];

      expect(DeltaSanitizer.validate(validDelta), isNull);
    });

    test('Delta dengan link berbahaya javascript: DITOLAK', () {
      final dangerousDelta = [
        {'insert': 'Klik '},
        {
          'insert': 'disini',
          'attributes': {'link': 'javascript:alert(1)'},
        },
        {'insert': '\n'},
      ];

      final error = DeltaSanitizer.validate(dangerousDelta);
      expect(error, isNotNull);
      expect(error, contains('Skema link berbahaya'));
    });

    test('Delta dengan gambar inline base64 DITOLAK', () {
      final base64Delta = [
        {'insert': 'Gambar berikut: '},
        {
          'insert': {'image': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA...'},
        },
      ];

      final error = DeltaSanitizer.validate(base64Delta);
      expect(error, isNotNull);
      expect(error, contains('Gambar base64 inline dilarang'));
    });

    test('Delta melebihi batas ukuran 500KB DITOLAK', () {
      final oversizedText = 'A' * (520 * 1024);
      final hugeDelta = [
        {'insert': oversizedText},
      ];

      final error = DeltaSanitizer.validate(hugeDelta);
      expect(error, isNotNull);
      expect(error, contains('melebihi batas maksimal 500KB'));
    });
  });

  group('MaterialContent Model Tests', () {
    test('MaterialContent serialization enforces Delta sanitization', () {
      final validContent = [
        {'insert': 'Judul Materi\n'},
      ];

      final material = MaterialContent(
        id: 'mat_01',
        meetingId: 'meeting_01',
        classId: 'class_01',
        title: 'Materi 1: Fondasi',
        content: validContent,
        updatedBy: 'teacher_01',
        status: ContentStatus.published,
      );

      final map = material.toMap();
      expect(map['title'], equals('Materi 1: Fondasi'));
      expect(map['status'], equals('Published'));
    });

    test('MaterialContent melempar DeltaSanitizationException jika konten tidak aman', () {
      final invalidContent = [
        {
          'insert': 'Hack',
          'attributes': {'link': 'javascript:exploit()'},
        },
      ];

      final material = MaterialContent(
        id: 'mat_01',
        meetingId: 'meeting_01',
        classId: 'class_01',
        title: 'Exploit Test',
        content: invalidContent,
        updatedBy: 'teacher_01',
      );

      expect(() => material.toMap(), throwsA(isA<DeltaSanitizationException>()));
    });
  });

  group('VideoItem & ManualBook Model Tests', () {
    test('VideoItem serialization handles YouTube & Cloudinary providers', () {
      final youtubeVideo = VideoItem(
        id: 'vid_01',
        meetingId: 'meeting_01',
        classId: 'class_01',
        url: 'https://youtube.com/watch?v=12345',
        provider: VideoProvider.youtube,
        duration: 360,
      );

      final map = youtubeVideo.toMap();
      expect(map['provider'], equals('youtube'));
      expect(map['duration'], equals(360));

      final fromMap = VideoItem.fromMap(map, id: 'vid_01');
      expect(fromMap.provider, equals(VideoProvider.youtube));
    });

    test('ManualBook serialization stores file URL and metadata', () {
      final book = ManualBook(
        id: 'book_01',
        classId: 'class_01',
        title: 'Buku Panduan Farlean LMS',
        description: 'Panduan lengkap bagi peserta kelas',
        fileUrl: 'https://res.cloudinary.com/farlean/raw/upload/manual.pdf',
        fileName: 'manual.pdf',
        fileSize: 1024000,
      );

      final map = book.toMap();
      expect(map['file_name'], equals('manual.pdf'));
      expect(map['file_size'], equals(1024000));

      final fromMap = ManualBook.fromMap(map, id: 'book_01');
      expect(fromMap.fileName, equals('manual.pdf'));
      expect(fromMap.fileSize, equals(1024000));
    });
  });
}

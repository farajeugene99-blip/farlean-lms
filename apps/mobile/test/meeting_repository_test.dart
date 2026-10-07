import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/meeting.dart';
import 'package:mobile/repositories/meeting_repository.dart';

void main() {
  group('MeetingRepository Validation Tests', () {
    late MeetingRepository repository;

    setUp(() {
      repository = MeetingRepository();
    });

    test('createMeeting melempar ArgumentError jika judul kosong', () async {
      final invalidMeeting = Meeting(
        id: 'm1',
        classId: 'c1',
        number: 1,
        title: '',
      );

      expect(
        () => repository.createMeeting(invalidMeeting),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createMeeting melempar ArgumentError jika nomor <= 0', () async {
      final invalidMeeting = Meeting(
        id: 'm1',
        classId: 'c1',
        number: 0,
        title: 'Pertemuan Negatif',
      );

      expect(
        () => repository.createMeeting(invalidMeeting),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('updateMeeting melempar ArgumentError jika judul kosong', () async {
      final invalidMeeting = Meeting(
        id: 'm1',
        classId: 'c1',
        number: 1,
        title: '   ',
      );

      expect(
        () => repository.updateMeeting(invalidMeeting),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('getMeetingsByClass mengembalikan list kosong secara aman saat Firestore uninitialized', () async {
      final list = await repository.getMeetingsByClass('class_01');
      expect(list, isEmpty);
    });

    test('getMeeting mengembalikan null secara aman saat Firestore uninitialized', () async {
      final meeting = await repository.getMeeting('meeting_01');
      expect(meeting, isNull);
    });

    test('linkModule melempar StateError saat Firestore uninitialized', () async {
      expect(
        () => repository.linkModule('m1', posttestId: 'post_01'),
        throwsA(isA<StateError>()),
      );
    });

    test('getMeetingCount mengembalikan 0 secara aman saat Firestore uninitialized', () async {
      final count = await repository.getMeetingCount('class_01');
      expect(count, equals(0));
    });

    test('deleteMeeting melempar StateError saat Firestore uninitialized', () async {
      expect(
        () => repository.deleteMeeting('m1'),
        throwsA(isA<StateError>()),
      );
    });
  });
}

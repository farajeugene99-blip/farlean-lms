import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/content_status.dart';
import 'package:mobile/models/meeting.dart';
import 'package:mobile/repositories/meeting_repository.dart';

class InMemoryIsolatedMeetingRepository extends MeetingRepository {
  final Map<String, List<Meeting>> _store = {};

  void seedMeetings(String classId, List<Meeting> meetings) {
    _store[classId] = meetings;
  }

  @override
  Future<List<Meeting>> getMeetingsByClass(String classId, {bool isStaff = false}) async {
    final list = _store[classId] ?? [];
    if (!isStaff) {
      return list
          .where((m) => m.status == ContentStatus.published || m.status == ContentStatus.scheduled)
          .toList();
    }
    return list;
  }
}

void main() {
  group('Multi-Class Meeting Isolation Regression Tests', () {
    late InMemoryIsolatedMeetingRepository repository;

    setUp(() {
      repository = InMemoryIsolatedMeetingRepository();

      // Seed Class A
      repository.seedMeetings('class_A', [
        const Meeting(
          id: 'meet_A1',
          classId: 'class_A',
          number: 1,
          title: 'Pertemuan A1',
          status: ContentStatus.published,
        ),
        const Meeting(
          id: 'meet_A2',
          classId: 'class_A',
          number: 2,
          title: 'Pertemuan A2',
          status: ContentStatus.published,
        ),
      ]);

      // Seed Class B
      repository.seedMeetings('class_B', [
        const Meeting(
          id: 'meet_B1',
          classId: 'class_B',
          number: 1,
          title: 'Pertemuan B1',
          status: ContentStatus.published,
        ),
      ]);
    });

    test('Class A meetings only return meetings belonging to Class A', () async {
      final meetingsA = await repository.getMeetingsByClass('class_A', isStaff: false);
      expect(meetingsA.length, equals(2));
      expect(meetingsA.map((m) => m.id), containsAll(['meet_A1', 'meet_A2']));
      expect(meetingsA.any((m) => m.classId != 'class_A'), isFalse);
    });

    test('Class B meetings only return meetings belonging to Class B (never leaks Class A)', () async {
      final meetingsB = await repository.getMeetingsByClass('class_B', isStaff: false);
      expect(meetingsB.length, equals(1));
      expect(meetingsB.first.id, equals('meet_B1'));
      expect(meetingsB.first.classId, equals('class_B'));
      expect(meetingsB.any((m) => m.id == 'meet_A1' || m.id == 'meet_A2'), isFalse);
    });

    test('Non-existent or unknown class returns empty list without cross-leak', () async {
      final meetingsC = await repository.getMeetingsByClass('class_unknown', isStaff: false);
      expect(meetingsC, isEmpty);
    });
  });
}

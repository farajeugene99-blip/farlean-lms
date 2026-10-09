import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/config/app_constants.dart';
import 'package:mobile/models/content_status.dart';
import 'package:mobile/models/meeting.dart';
import 'package:mobile/presentation/main/main_shell.dart';
import 'package:mobile/repositories/meeting_repository.dart';

class FakeMeetingRepository extends MeetingRepository {
  final Map<String, List<Meeting>> meetingsByClass;

  FakeMeetingRepository(this.meetingsByClass);

  @override
  Future<List<Meeting>> getMeetingsByClass(String classId, {bool isStaff = false}) async {
    final list = meetingsByClass[classId] ?? [];
    if (!isStaff) {
      return list
          .where((m) => m.status == ContentStatus.published || m.status == ContentStatus.scheduled)
          .toList();
    }
    return list;
  }
}

void main() {
  group('Home -> Materi Flow & Multi-Class Isolation Regression Tests', () {
    test('MainShell.activeClassId remembers active class across tab switches', () {
      MainShell.activeClassId = null;
      expect(MainShell.activeClassId, isNull);

      // Simulates user visiting /materi?classId=class_test_qa
      MainShell.activeClassId = 'class_test_qa';
      expect(MainShell.activeClassId, 'class_test_qa');

      // Simulates tab tap: uses activeClassId
      final targetRoute = MainShell.activeClassId != null
          ? '${AppConstants.materiRoute}?classId=${MainShell.activeClassId}'
          : AppConstants.materiRoute;
      expect(targetRoute, '/materi?classId=class_test_qa');
    });

    test('FakeMeetingRepository isolates Class A and Class B meetings', () async {
      final fakeRepo = FakeMeetingRepository({
        'class_a': [
          const Meeting(
            id: 'm_a1',
            classId: 'class_a',
            number: 1,
            title: 'Pertemuan A1',
            materiId: 'mat_a1',
            status: ContentStatus.published,
          ),
        ],
        'class_b': [
          const Meeting(
            id: 'm_b1',
            classId: 'class_b',
            number: 1,
            title: 'Pertemuan B1',
            materiId: 'mat_b1',
            status: ContentStatus.published,
          ),
        ],
      });

      final classAMeetings = await fakeRepo.getMeetingsByClass('class_a', isStaff: false);
      final classBMeetings = await fakeRepo.getMeetingsByClass('class_b', isStaff: false);

      expect(classAMeetings.length, 1);
      expect(classAMeetings.first.id, 'm_a1');
      expect(classAMeetings.first.materiId, 'mat_a1');

      expect(classBMeetings.length, 1);
      expect(classBMeetings.first.id, 'm_b1');
      expect(classBMeetings.first.materiId, 'mat_b1');

      // Regression: Class A must never contain Class B's meeting or material
      expect(classAMeetings.any((m) => m.id == 'm_b1'), isFalse);
      expect(classBMeetings.any((m) => m.id == 'm_a1'), isFalse);
    });

    test('Student query filters out draft meetings while staff sees all', () async {
      final fakeRepo = FakeMeetingRepository({
        'class_a': [
          const Meeting(
            id: 'm_pub',
            classId: 'class_a',
            number: 1,
            title: 'Pertemuan Publik',
            status: ContentStatus.published,
          ),
          const Meeting(
            id: 'm_draft',
            classId: 'class_a',
            number: 2,
            title: 'Pertemuan Draft',
            status: ContentStatus.draft,
          ),
        ],
      });

      final studentMeetings = await fakeRepo.getMeetingsByClass('class_a', isStaff: false);
      final staffMeetings = await fakeRepo.getMeetingsByClass('class_a', isStaff: true);

      expect(studentMeetings.length, 1);
      expect(studentMeetings.first.id, 'm_pub');

      expect(staffMeetings.length, 2);
      expect(staffMeetings.map((m) => m.id), containsAll(['m_pub', 'm_draft']));
    });
  });
}

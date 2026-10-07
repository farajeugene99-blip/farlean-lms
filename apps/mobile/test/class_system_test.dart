import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/class_member.dart';
import 'package:mobile/models/classroom.dart';
import 'package:mobile/repositories/class_repository.dart';
import 'package:mobile/services/class_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeClassRepository extends ClassRepository {
  final Map<String, List<Classroom>> mockClasses;
  final List<ClassMember> mockMembers;

  FakeClassRepository({
    required this.mockClasses,
    this.mockMembers = const [],
  });

  @override
  Future<Map<String, List<Classroom>>> getMyClasses() async {
    return mockClasses;
  }

  @override
  Future<Classroom?> getClass(String classId) async {
    final all = [...?mockClasses['owned'], ...?mockClasses['joined']];
    return all.cast<Classroom?>().firstWhere(
      (c) => c?.id == classId,
      orElse: () => null,
    );
  }

  @override
  Future<Classroom> createClass({
    required String name,
    String description = '',
    String? customCode,
  }) async {
    return Classroom(
      id: 'class_new_123',
      name: name,
      code: customCode ?? 'RND12345',
      description: description,
      teacherId: 'teacher_curr',
      status: 'Active',
    );
  }

  @override
  Future<void> archiveClass(String classId) async {}

  @override
  Future<void> reactivateClass(String classId) async {}

  @override
  Future<List<ClassMember>> getClassMembers(String classId) async {
    return mockMembers;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ClassProvider & Multi-Class Logic Tests', () {
    test('loadClasses populates owned and joined classes and detects single class', () async {
      final fakeRepo = FakeClassRepository(
        mockClasses: {
          'owned': [
            const Classroom(
              id: 'c_single',
              name: 'Kelas Tunggal',
              code: 'TUNGGAL1',
              teacherId: 'teacher_1',
              status: 'Active',
            ),
          ],
          'joined': [],
        },
      );

      final provider = ClassProvider(classRepository: fakeRepo);
      await provider.loadClasses();

      expect(provider.ownedClasses.length, 1);
      expect(provider.joinedClasses.length, 0);
      expect(provider.allClasses.length, 1);
      expect(provider.hasSingleClass, isTrue);
      expect(provider.singleClassId, 'c_single');
      expect(provider.selectedClassId, 'c_single');
    });

    test('hasSingleClass is false when user has multiple classes', () async {
      final fakeRepo = FakeClassRepository(
        mockClasses: {
          'owned': [
            const Classroom(
              id: 'c_1',
              name: 'Kelas 1',
              code: 'KODE1',
              teacherId: 'teacher_1',
            ),
          ],
          'joined': [
            const Classroom(
              id: 'c_2',
              name: 'Kelas 2',
              code: 'KODE2',
              teacherId: 'teacher_2',
            ),
          ],
        },
      );

      final provider = ClassProvider(classRepository: fakeRepo);
      await provider.loadClasses();

      expect(provider.allClasses.length, 2);
      expect(provider.hasSingleClass, isFalse);
      expect(provider.singleClassId, isNull);
    });

    test('selectClass updates selectedClass and selectedClassId', () async {
      final fakeRepo = FakeClassRepository(
        mockClasses: {
          'owned': [
            const Classroom(id: 'c_1', name: 'Kelas 1', teacherId: 't1'),
            const Classroom(id: 'c_2', name: 'Kelas 2', teacherId: 't1'),
          ],
          'joined': [],
        },
      );

      final provider = ClassProvider(classRepository: fakeRepo);
      await provider.loadClasses();
      await provider.selectClass('c_2');

      expect(provider.selectedClassId, 'c_2');
      expect(provider.selectedClass?.name, 'Kelas 2');
    });

    test('archiveClass updates class status and resets selectedClass if archived', () async {
      final fakeRepo = FakeClassRepository(
        mockClasses: {
          'owned': [
            const Classroom(id: 'c_1', name: 'Kelas 1', teacherId: 't1', status: 'Active'),
          ],
          'joined': [],
        },
      );

      final provider = ClassProvider(classRepository: fakeRepo);
      await provider.loadClasses();
      expect(provider.selectedClassId, 'c_1');

      await provider.archiveClass('c_1');
      expect(provider.ownedClasses.first.isArchived, isTrue);
      expect(provider.selectedClassId, isNull);

      await provider.reactivateClass('c_1');
      expect(provider.ownedClasses.first.isActive, isTrue);
    });
  });
}

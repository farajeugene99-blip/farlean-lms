import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/delta_sanitizer.dart';
import 'package:mobile/models/material_content.dart';
import 'package:mobile/repositories/material_repository.dart';

void main() {
  group('MaterialRepository Validation Tests', () {
    late MaterialRepository repository;

    setUp(() {
      repository = MaterialRepository();
    });

    test('createMaterial melempar ArgumentError jika judul kosong', () async {
      final invalidMaterial = MaterialContent(
        id: 'mat_01',
        meetingId: 'meet_01',
        classId: 'class_01',
        title: '',
        content: [{'insert': 'Teks\n'}],
        updatedBy: 'teacher_01',
      );

      expect(
        () => repository.createMaterial(invalidMaterial),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createMaterial melempar DeltaSanitizationException jika konten memuat link berbahaya', () async {
      final maliciousMaterial = MaterialContent(
        id: 'mat_01',
        meetingId: 'meet_01',
        classId: 'class_01',
        title: 'Judul Sah',
        content: [
          {
            'insert': 'Exploit link',
            'attributes': {'link': 'javascript:alert(1)'},
          },
        ],
        updatedBy: 'teacher_01',
      );

      expect(
        () => repository.createMaterial(maliciousMaterial),
        throwsA(isA<DeltaSanitizationException>()),
      );
    });

    test('updateMaterial melempar ArgumentError jika judul kosong', () async {
      final invalidMaterial = MaterialContent(
        id: 'mat_01',
        meetingId: 'meet_01',
        classId: 'class_01',
        title: '   ',
        content: [{'insert': 'Teks\n'}],
        updatedBy: 'teacher_01',
      );

      expect(
        () => repository.updateMaterial(invalidMaterial),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('updateMaterial melempar ArgumentError jika ID materi kosong', () async {
      final invalidMaterial = MaterialContent(
        id: '  ',
        meetingId: 'meet_01',
        classId: 'class_01',
        title: 'Judul Sah',
        content: [{'insert': 'Teks\n'}],
        updatedBy: 'teacher_01',
      );

      expect(
        () => repository.updateMaterial(invalidMaterial),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('getMaterial mengembalikan null secara aman saat Firestore uninitialized', () async {
      final material = await repository.getMaterial('non_existent');
      expect(material, isNull);
    });

    test('hasOpenedMateri mengembalikan false secara aman saat Firestore uninitialized', () async {
      final hasOpened = await repository.hasOpenedMateri(
        classId: 'c1',
        meetingId: 'm1',
        uid: 'u1',
      );
      expect(hasOpened, isFalse);
    });
  });
}

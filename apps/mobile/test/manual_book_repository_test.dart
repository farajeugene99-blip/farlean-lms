import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/manual_book.dart';
import 'package:mobile/repositories/manual_book_repository.dart';

void main() {
  group('ManualBookRepository Validation Tests', () {
    late ManualBookRepository repository;

    setUp(() {
      repository = ManualBookRepository();
    });

    test('createManualBook melempar ArgumentError jika judul kosong', () async {
      final invalidBook = ManualBook(
        id: 'b1',
        classId: 'c1',
        title: '',
        description: 'Desc',
        fileUrl: 'https://cloudinary.com/manual.pdf',
        fileName: 'manual.pdf',
        fileSize: 1024,
      );

      expect(
        () => repository.createManualBook(invalidBook),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createManualBook melempar ArgumentError jika URL tidak valid', () async {
      final invalidBook = ManualBook(
        id: 'b1',
        classId: 'c1',
        title: 'Buku Sah',
        description: 'Desc',
        fileUrl: 'invalid_url',
        fileName: 'manual.pdf',
        fileSize: 1024,
      );

      expect(
        () => repository.createManualBook(invalidBook),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('getManualBook mengembalikan null secara aman saat Firestore uninitialized', () async {
      final book = await repository.getManualBook('non_existent');
      expect(book, isNull);
    });

    test('getManualBooksByClass mengembalikan list kosong secara aman saat Firestore uninitialized', () async {
      final list = await repository.getManualBooksByClass('c1');
      expect(list, isEmpty);
    });
  });
}

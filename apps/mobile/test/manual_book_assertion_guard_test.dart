import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/models/manual_book.dart';
import 'package:mobile/presentation/manual_book/create_manual_book_dialog.dart';
import 'package:mobile/presentation/manual_book/manual_book_list_screen.dart';
import 'package:mobile/repositories/manual_book_repository.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:provider/provider.dart';

import 'session_pipeline_test.dart';

class _MockManualBookRepoWithCreate extends ManualBookRepository {
  List<ManualBook> books;
  int createCount = 0;

  _MockManualBookRepoWithCreate({required this.books});

  @override
  Future<List<ManualBook>> getManualBooksByClass(String classId, {bool isAdmin = false}) async {
    return List.from(books);
  }

  @override
  Future<String> createManualBook(ManualBook book) async {
    createCount++;
    books.add(book);
    return 'book_${books.length}';
  }
}

AuthProvider _createAdminAuth() {
  final fakeUser = FakeUser(uid: 'u_admin', email: 'admin@farlean.edu');
  final mockAuth = MockAuthService(
    mockCurrentUser: fakeUser,
    mockProfileToReturn: const AppUser(
      uid: 'u_admin',
      name: 'Admin Farlean',
      email: 'admin@farlean.edu',
      accountType: AccountType.dosen,
      role: UserRole.admin,
    ),
  );
  return AuthProvider(authService: mockAuth);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ManualBook Assertion Guard & Lifecycle Tests (Line 6281 Protection)', () {
    testWidgets('1. CreateManualBookDialog validates input and pops data cleanly', (tester) async {
      ManualBookFormData? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showDialog<ManualBookFormData>(
                    context: context,
                    builder: (_) => const CreateManualBookDialog(),
                  );
                },
                child: const Text('Buka'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();

      // Coba simpan saat kosong -> error validation
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(result, isNull);

      // Isi form yang valid
      await tester.enterText(find.byType(TextFormField).at(0), 'Panduan Mahasiswa Baru');
      await tester.enterText(find.byType(TextFormField).at(1), 'Petunjuk KRS dan LMS');
      await tester.enterText(find.byType(TextFormField).at(2), 'https://res.cloudinary.com/farlean/manual.pdf');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.title, equals('Panduan Mahasiswa Baru'));
      expect(result!.description, equals('Petunjuk KRS dan LMS'));
      expect(result!.fileUrl, equals('https://res.cloudinary.com/farlean/manual.pdf'));
      expect(result!.isPublished, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. ManualBookListScreen opens dialog, creates book, and soft-refreshes without assert(_dependents.isEmpty)', (tester) async {
      final repo = _MockManualBookRepoWithCreate(books: []);
      final auth = _createAdminAuth();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: ManualBookListScreen(
              classId: 'SYSTEM',
              manualBookRepository: repo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Empty state tampak
      expect(find.text('Belum Ada Buku Panduan'), findsOneWidget);

      // Buka dialog via FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Manual Book'), findsWidgets);

      // Isi form
      await tester.enterText(find.byType(TextFormField).at(0), 'Buku Panduan Farlean v1.0');
      await tester.enterText(find.byType(TextFormField).at(2), 'https://res.cloudinary.com/farlean/v1.pdf');
      await tester.pumpAndSettle();

      // Tap Simpan
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // Verifikasi: Dialog tertutup, repo dipanggil, data muncul di list, dan TIDAK ADA EXCEPTION
      expect(repo.createCount, equals(1));
      expect(find.text('Buku Panduan Farlean v1.0'), findsOneWidget);
      expect(find.text('PUBLISHED'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

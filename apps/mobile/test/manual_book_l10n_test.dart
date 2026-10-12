import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/models/manual_book.dart';
import 'package:mobile/presentation/manual_book/manual_book_list_screen.dart';
import 'package:mobile/repositories/manual_book_repository.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:provider/provider.dart';

import 'session_pipeline_test.dart';

class _FakeManualBookRepo extends ManualBookRepository {
  final List<ManualBook> books;
  _FakeManualBookRepo({this.books = const []});

  @override
  Future<List<ManualBook>> getManualBooksByClass(String classId) async => books;
}

AuthProvider _createStaffAuth() {
  final fakeUser = FakeUser(uid: 'u_staff', email: 'staff@farlean.edu');
  final mockAuth = MockAuthService(
    mockCurrentUser: fakeUser,
    mockProfileToReturn: const AppUser(
      uid: 'u_staff',
      name: 'Pengajar Farlean',
      email: 'staff@farlean.edu',
      accountType: AccountType.dosen,
      role: UserRole.guru,
    ),
  );
  return AuthProvider(authService: mockAuth);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testBook = ManualBook(
    id: 'b_01',
    classId: 'c_01',
    title: 'Panduan Praktikum Database',
    description: 'Modul praktikum laboratorium semester ganjil.',
    fileUrl: 'https://res.cloudinary.com/demo/raw/upload/sample.pdf',
    fileName: 'praktikum_db.pdf',
    fileSize: 2048 * 1024, // 2 MB
    createdAt: DateTime.now(),
  );

  Widget createHarness({
    required List<ManualBook> books,
    Locale locale = const Locale('id'),
  }) {
    final repo = _FakeManualBookRepo(books: books);
    return MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ChangeNotifierProvider<AuthProvider>.value(
        value: _createStaffAuth(),
        child: ManualBookListScreen(
          classId: 'c_01',
          manualBookRepository: repo,
        ),
      ),
    );
  }

  group('ManualBookListScreen Localization', () {
    testWidgets('Layar manual book menampilkan string Bahasa Indonesia', (tester) async {
      await tester.pumpWidget(createHarness(books: [testBook], locale: const Locale('id')));
      await tester.pumpAndSettle();

      expect(find.text('Buku Panduan (Manual Book)'), findsOneWidget);
      expect(find.text('Tambah Manual Book'), findsOneWidget);
      expect(find.text('Panduan Praktikum Database'), findsOneWidget);
      expect(find.text('Buka Dokumen PDF'), findsOneWidget);
    });

    testWidgets('Layar manual book menampilkan string Bahasa Inggris', (tester) async {
      await tester.pumpWidget(createHarness(books: [testBook], locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Guide Book (Manual Book)'), findsOneWidget);
      expect(find.text('Add Manual Book'), findsOneWidget);
      expect(find.text('Panduan Praktikum Database'), findsOneWidget);
      expect(find.text('Open PDF Document'), findsOneWidget);
    });

    testWidgets('Dialog tambah manual book menampilkan UI terlokalisasi di EN', (tester) async {
      await tester.pumpWidget(createHarness(books: [], locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('No Guide Books Yet'), findsOneWidget);

      await tester.tap(find.text('Add Manual Book'));
      await tester.pumpAndSettle();

      expect(find.text('Add Manual Book'), findsWidgets);
      expect(find.text('Guide Title'), findsOneWidget);
      expect(find.text('Short Description'), findsOneWidget);
      expect(find.text('Cloudinary File URL (PDF)'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('Tanpa override locale, layar manual book tetap merender Bahasa Indonesia', (tester) async {
      await tester.pumpWidget(createHarness(books: [testBook], locale: const Locale('id')));
      await tester.pumpAndSettle();

      expect(find.text('Buku Panduan (Manual Book)'), findsOneWidget);
      expect(find.text('Guide Book (Manual Book)'), findsNothing);
    });
  });
}

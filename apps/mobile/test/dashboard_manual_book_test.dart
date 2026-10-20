import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/models/classroom.dart';
import 'package:mobile/models/manual_book.dart';
import 'package:mobile/presentation/main/dashboard_screen.dart';
import 'package:mobile/presentation/manual_book/manual_book_list_screen.dart';
import 'package:mobile/repositories/class_repository.dart';
import 'package:mobile/repositories/manual_book_repository.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:mobile/services/class_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'session_pipeline_test.dart';

class MockManualBookRepoForSystem extends ManualBookRepository {
  final List<ManualBook> books;
  MockManualBookRepoForSystem(this.books);

  @override
  Future<List<ManualBook>> getManualBooksByClass(String classId) async {
    return books.where((b) => b.classId == classId).toList();
  }
}

class _FakeClassRepo extends ClassRepository {
  final List<Classroom> owned;

  _FakeClassRepo({this.owned = const []});

  @override
  Future<Map<String, List<Classroom>>> getMyClasses() async {
    return {'owned': owned, 'joined': []};
  }
}

AuthProvider _createAuth({
  required String uid,
  required String email,
  required AccountType type,
  required UserRole role,
}) {
  final fakeUser = FakeUser(uid: uid, email: email);
  final mockAuth = MockAuthService(
    mockCurrentUser: fakeUser,
    mockProfileToReturn: AppUser(
      uid: uid,
      name: 'Pengguna Test',
      email: email,
      accountType: type,
      role: role,
      claimsRole: role,
    ),
  );
  return AuthProvider(authService: mockAuth);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testClass = Classroom(
    id: 'c_dash',
    name: 'Struktur Data Dasar',
    code: 'STRUKTUR1',
    teacherId: 'admin_01',
    description: 'Mata kuliah dasar algoritma.',
    status: 'Active',
  );

  group('Manual Book Dashboard & System Mode Tests (Fitur A)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('1. DashboardScreen merender Kartu Buku Panduan LMS dengan badge Admin untuk Admin', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = _createAuth(
        uid: 'admin_01',
        email: 'admin@farlean.edu',
        type: AccountType.dosen,
        role: UserRole.admin,
      );
      final classProvider = ClassProvider(classRepository: _FakeClassRepo(owned: [testClass]));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: auth),
              ChangeNotifierProvider<ClassProvider>.value(value: classProvider),
            ],
            child: const DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Buku Panduan LMS'), findsOneWidget);
      expect(find.text('Dikelola Admin'), findsOneWidget);
      expect(find.byIcon(Icons.menu_book_rounded), findsWidgets);
    });

    testWidgets('2. ManualBookListScreen dengan classId SYSTEM menampilkan judul Buku Panduan Sistem', (tester) async {
      final auth = _createAuth(
        uid: 'student_01',
        email: 'budi@farlean.edu',
        type: AccountType.mahasiswa,
        role: UserRole.user,
      );

      final repo = MockManualBookRepoForSystem([
        const ManualBook(
          id: 'mb_sys_1',
          classId: 'SYSTEM',
          title: 'Panduan Penggunaan Farlean LMS',
          description: 'Panduan navigasi dan fitur bagi mahasiswa',
          fileUrl: 'https://res.cloudinary.com/farlean/manual.pdf',
          fileName: 'panduan_lms.pdf',
          fileSize: 1048576,
        ),
      ]);

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

      // Judul AppBar sistem
      expect(find.text('Buku Panduan Sistem'), findsOneWidget);
      expect(find.text('Panduan Penggunaan Farlean LMS'), findsOneWidget);
      // Mahasiswa tidak memiliki FAB tambah panduan sistem
      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });
}

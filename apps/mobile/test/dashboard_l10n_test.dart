import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/models/classroom.dart';
import 'package:mobile/presentation/main/dashboard_profile_error_localization.dart';
import 'package:mobile/presentation/main/dashboard_screen.dart';
import 'package:mobile/presentation/main/main_shell.dart';
import 'package:mobile/repositories/class_repository.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:mobile/services/class_provider.dart';
import 'package:provider/provider.dart';

import 'session_pipeline_test.dart';

class _FakeClassRepo extends ClassRepository {
  final List<Classroom> owned;
  final List<Classroom> joined;

  _FakeClassRepo({this.owned = const [], this.joined = const []});

  @override
  Future<Map<String, List<Classroom>>> getMyClasses() async {
    return {'owned': owned, 'joined': joined};
  }
}

AuthProvider _createAuth({
  required AccountType type,
  required UserRole role,
  bool roleOutOfSync = false,
}) {
  final fakeUser = FakeUser(uid: 'u_dash', email: 'dash@farlean.edu');
  final mockAuth = MockAuthService(
    mockCurrentUser: fakeUser,
    mockProfileToReturn: AppUser(
      uid: 'u_dash',
      name: 'Pengguna Dashboard',
      email: 'dash@farlean.edu',
      accountType: type,
      role: role,
      claimsRole: roleOutOfSync ? UserRole.user : role,
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
    teacherId: 'u_dash',
    description: 'Mata kuliah dasar algoritma dan struktur data.',
    status: 'Active',
  );

  Widget createDashboardHarness({
    required AuthProvider authProvider,
    ClassRepository? classRepo,
    Locale locale = const Locale('id'),
  }) {
    final cRepo = classRepo ?? _FakeClassRepo(owned: [testClass], joined: []);
    final classProvider = ClassProvider(classRepository: cRepo);

    return MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<ClassProvider>.value(value: classProvider),
        ],
        child: const DashboardScreen(),
      ),
    );
  }

  Widget createShellHarness({
    Locale locale = const Locale('id'),
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MainShell(
        child: Scaffold(body: Text('Page Body')),
      ),
    );
  }

  // =========================================================================
  // 1. DashboardScreen — ID vs EN
  // =========================================================================
  group('DashboardScreen Localization', () {
    testWidgets('Layar dashboard menampilkan string Bahasa Indonesia', (tester) async {
      final auth = _createAuth(
        type: AccountType.dosen,
        role: UserRole.guru,
      );

      await tester.pumpWidget(createDashboardHarness(authProvider: auth, locale: const Locale('id')));
      await tester.pumpAndSettle();

      expect(find.text('Farlean LMS'), findsWidgets);
      expect(find.text('Selamat Datang di Farlean LMS'), findsOneWidget);
      expect(find.text('Kelas yang Anda Kelola'), findsOneWidget);
      expect(find.text('Kelas yang Anda Ikuti'), findsOneWidget);
      expect(find.text('Kelola Kelas'), findsOneWidget);
    });

    testWidgets('Layar dashboard menampilkan string Bahasa Inggris', (tester) async {
      final auth = _createAuth(
        type: AccountType.dosen,
        role: UserRole.guru,
      );

      await tester.pumpWidget(createDashboardHarness(authProvider: auth, locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Farlean LMS'), findsWidgets);
      expect(find.text('Welcome to Farlean LMS'), findsOneWidget);
      expect(find.text('Classes You Manage'), findsOneWidget);
      expect(find.text('Classes You Joined'), findsOneWidget);
      expect(find.text('Manage Class'), findsOneWidget);
    });

    testWidgets('Banner peran belum sinkron menampilkan pesan terlokalisasi di EN', (tester) async {
      final auth = _createAuth(
        type: AccountType.dosen,
        role: UserRole.guru,
        roleOutOfSync: true,
      );

      await tester.pumpWidget(createDashboardHarness(authProvider: auth, locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Account Role Out of Sync'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
      expect(find.textContaining('Token: USER vs Profile: GURU'), findsOneWidget);
    });
  });

  // =========================================================================
  // 2. MainShell Navigation Labels — ID vs EN
  // =========================================================================
  group('MainShell Navigation Localization', () {
    testWidgets('Navigasi bawah menampilkan label Bahasa Indonesia', (tester) async {
      await tester.pumpWidget(createShellHarness(locale: const Locale('id')));
      await tester.pumpAndSettle();

      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Materi'), findsOneWidget);
      expect(find.text('AI Tutor'), findsOneWidget);
      expect(find.text('Diskusi'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
    });

    testWidgets('Navigasi bawah menampilkan label Bahasa Inggris', (tester) async {
      await tester.pumpWidget(createShellHarness(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Materials'), findsOneWidget);
      expect(find.text('AI Tutor'), findsOneWidget);
      expect(find.text('Discussion'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });
  });

  // =========================================================================
  // 3. ProfileErrorReason Enum Mapping Coverage (Poin 3 Review)
  // =========================================================================
  group('ProfileErrorReason Localization Mapping Coverage', () {
    testWidgets('Semua nilai ProfileErrorReason.values terpetakan tanpa exception', (tester) async {
      late AppLocalizations idL10n;
      late AppLocalizations enL10n;

      await tester.pumpWidget(MaterialApp(
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (ctx) {
          idL10n = AppLocalizations.of(ctx);
          return const SizedBox.shrink();
        }),
      ));

      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (ctx) {
          enL10n = AppLocalizations.of(ctx);
          return const SizedBox.shrink();
        }),
      ));

      // Verifikasi seluruh enum ProfileErrorReason
      for (final reason in ProfileErrorReason.values) {
        final idMsg = DashboardProfileErrorLocalization.messageForReason(reason, idL10n);
        final enMsg = DashboardProfileErrorLocalization.messageForReason(reason, enL10n);

        expect(idMsg, isNotEmpty, reason: 'Pesan ID tidak boleh kosong untuk reason $reason');
        expect(enMsg, isNotEmpty, reason: 'Pesan EN tidak boleh kosong untuk reason $reason');

        if (reason == ProfileErrorReason.network) {
          expect(idMsg, equals(idL10n.dashboardProfileErrorNetwork));
          expect(enMsg, equals(enL10n.dashboardProfileErrorNetwork));
        } else if (reason == ProfileErrorReason.notFound) {
          expect(idMsg, equals(idL10n.dashboardProfileErrorNotFound));
          expect(enMsg, equals(enL10n.dashboardProfileErrorNotFound));
        } else if (reason == ProfileErrorReason.permissionDenied) {
          expect(idMsg, equals(idL10n.dashboardProfileErrorPermission));
          expect(enMsg, equals(enL10n.dashboardProfileErrorPermission));
        }
      }
    });
  });

  // =========================================================================
  // 4. Responsive Narrow Screen Test on MainShell (Poin 2 User Requirement)
  // =========================================================================
  group('MainShell Responsive Layout Test', () {
    testWidgets('MainShell pada layar sempit (262px, textScale 1.5, EN) tidak melempar RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(262, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(262, 640),
            textScaler: TextScaler.linear(1.5),
          ),
          child: createShellHarness(locale: const Locale('en')),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  // =========================================================================
  // 5. Locale-Lock Protection Test
  // =========================================================================
  group('Dashboard Locale-Lock Protection', () {
    testWidgets('Tanpa override locale, dashboard tetap merender Bahasa Indonesia', (tester) async {
      final auth = _createAuth(
        type: AccountType.mahasiswa,
        role: UserRole.user,
      );

      await tester.pumpWidget(createDashboardHarness(authProvider: auth, locale: const Locale('id')));
      await tester.pumpAndSettle();

      expect(find.text('Selamat Datang di Farlean LMS'), findsOneWidget);
      expect(find.text('Welcome to Farlean LMS'), findsNothing);
    });
  });
}

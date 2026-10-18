import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/models/material_content.dart';
import 'package:mobile/presentation/material/material_editor_screen.dart';
import 'package:mobile/presentation/material/material_reader_screen.dart';
import 'package:mobile/repositories/material_repository.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:provider/provider.dart';

import 'session_pipeline_test.dart';

class _FakeMaterialRepo extends MaterialRepository {
  final MaterialContent? material;
  _FakeMaterialRepo({this.material});

  @override
  Future<MaterialContent?> getMaterial(String id) async => material;

  @override
  Future<void> recordMateriOpened({
    required String classId,
    required String meetingId,
    required String materiId,
    required String uid,
  }) async {}
}

AuthProvider _createTeacherAuth() {
  final fakeUser = FakeUser(uid: 'teacher_01', email: 'guru@farlean.edu');
  final mockAuth = MockAuthService(
    mockCurrentUser: fakeUser,
    mockProfileToReturn: const AppUser(
      uid: 'teacher_01',
      name: 'Guru Pembimbing',
      email: 'guru@farlean.edu',
      accountType: AccountType.dosen,
      role: UserRole.guru,
    ),
  );
  return AuthProvider(authService: mockAuth);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testContent = MaterialContent(
    id: 'mat_01',
    meetingId: 'meet_01',
    classId: 'class_01',
    title: 'Pengantar Jaringan Komputer',
    content: [
      {'insert': 'Jaringan komputer menghubungkan node-node komunikasi.\n'}
    ],
    updatedBy: 'teacher_01',
    version: 2,
    format: 'delta',
  );

  Widget createReaderHarness({
    required MaterialContent material,
    Locale locale = const Locale('id'),
  }) {
    final repo = _FakeMaterialRepo(material: material);
    return MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: ChangeNotifierProvider<AuthProvider>.value(
        value: _createTeacherAuth(),
        child: MaterialReaderScreen(
          materiId: material.id,
          classId: material.classId,
          meetingId: material.meetingId,
          materialRepository: repo,
        ),
      ),
    );
  }

  Widget createEditorHarness({
    MaterialContent? initialMaterial,
    Locale locale = const Locale('id'),
  }) {
    final repo = _FakeMaterialRepo(material: initialMaterial);
    return MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: ChangeNotifierProvider<AuthProvider>.value(
        value: _createTeacherAuth(),
        child: MaterialEditorScreen(
          materiId: initialMaterial?.id ?? 'new',
          initialMaterial: initialMaterial,
          classId: 'class_01',
          meetingId: 'meet_01',
          materialRepository: repo,
        ),
      ),
    );
  }

  // =========================================================================
  // 1. MaterialReaderScreen — ID vs EN
  // =========================================================================
  group('MaterialReaderScreen Localization', () {
    testWidgets('Tampilan pembaca menampilkan string Bahasa Indonesia', (tester) async {
      await tester.pumpWidget(createReaderHarness(material: testContent, locale: const Locale('id')));
      await tester.pumpAndSettle();

      expect(find.text('Pengantar Jaringan Komputer'), findsOneWidget);
      expect(find.text('Versi 2'), findsOneWidget);
      expect(find.text('Format: DELTA'), findsOneWidget);
      expect(find.text('Tercatat Dibuka'), findsOneWidget);
    });

    testWidgets('Tampilan pembaca menampilkan string Bahasa Inggris', (tester) async {
      await tester.pumpWidget(createReaderHarness(material: testContent, locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Pengantar Jaringan Komputer'), findsOneWidget);
      expect(find.text('Version 2'), findsOneWidget);
      expect(find.text('Format: DELTA'), findsOneWidget);
      expect(find.text('Recorded as Opened'), findsOneWidget);
    });
  });

  // =========================================================================
  // 2. MaterialEditorScreen — ID vs EN
  // =========================================================================
  group('MaterialEditorScreen Localization', () {
    testWidgets('Editor baru menampilkan string Bahasa Indonesia', (tester) async {
      await tester.pumpWidget(createEditorHarness(locale: const Locale('id')));
      await tester.pumpAndSettle();

      expect(find.text('Buat Materi Baru'), findsOneWidget);
      expect(find.byTooltip('Simpan Draft'), findsOneWidget);
      expect(find.text('Publikasikan'), findsOneWidget);
      expect(find.text('Judul Materi Pembelajaran'), findsOneWidget);
      expect(find.text('Gambar'), findsOneWidget);
      expect(find.text('Template'), findsOneWidget);
      expect(find.textContaining('0 karakter • Format: Delta JSON'), findsOneWidget);
      expect(find.textContaining('Materi masih kosong'), findsOneWidget);
    });

    testWidgets('Editor baru menampilkan string Bahasa Inggris', (tester) async {
      await tester.pumpWidget(createEditorHarness(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Create New Material'), findsOneWidget);
      expect(find.byTooltip('Save Draft'), findsOneWidget);
      expect(find.text('Publish'), findsOneWidget);
      expect(find.text('Learning Material Title'), findsOneWidget);
      expect(find.text('Image'), findsOneWidget);
      expect(find.text('Template'), findsOneWidget);
      expect(find.textContaining('0 characters • Format: Delta JSON'), findsOneWidget);
      expect(find.textContaining('Material is still empty'), findsOneWidget);
    });

    testWidgets('Dialog Pratinjau menampilkan UI terlokalisasi di EN', (tester) async {
      await tester.pumpWidget(createEditorHarness(
        initialMaterial: testContent,
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Edit Material'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Pengantar Jaringan Komputer'), findsWidgets);
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Close'), findsNothing);
    });

    testWidgets('Template menyisipkan teks dan memperbarui status di EN', (tester) async {
      await tester.pumpWidget(createEditorHarness(locale: const Locale('en')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Template'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Material is still empty'), findsNothing);
      expect(find.text('Material template successfully inserted. Please complete each section.'), findsOneWidget);
    });
  });

  // =========================================================================
  // 3. String Keys & Dialog Translations Verification
  // =========================================================================
  group('Material Dialogs & Actions Translation Parity', () {
    testWidgets('Semua dialog konfirmasi dan aksi memiliki terjemahan valid di EN dan ID', (tester) async {
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

      // Dialog Sisipkan Gambar
      expect(idL10n.materialInsertImageTitle, equals('Sisipkan Gambar (URL Cloudinary)'));
      expect(enL10n.materialInsertImageTitle, equals('Insert Image (Cloudinary URL)'));
      expect(idL10n.materialImageUrlLabel, equals('URL Gambar (https://...)'));
      expect(enL10n.materialImageUrlLabel, equals('Image URL (https://...)'));
      expect(idL10n.materialInsertBtn, equals('Sisipkan'));
      expect(enL10n.materialInsertBtn, equals('Insert'));

      // Dialog Buang Perubahan
      expect(idL10n.materialDiscardConfirmTitle, equals('Buang Perubahan?'));
      expect(enL10n.materialDiscardConfirmTitle, equals('Discard Changes?'));
      expect(idL10n.materialKeepEditingBtn, equals('Lanjutkan Mengedit'));
      expect(enL10n.materialKeepEditingBtn, equals('Keep Editing'));
      expect(idL10n.materialDiscardChangesBtn, equals('Buang Perubahan'));
      expect(enL10n.materialDiscardChangesBtn, equals('Discard Changes'));

      // Pesan Simpan & Validasi
      expect(idL10n.materialTitleRequired, equals('Judul materi wajib diisi.'));
      expect(enL10n.materialTitleRequired, equals('Material title is required.'));
      expect(idL10n.materialSavedAsStatus('Dipublikasikan'), equals('Materi berhasil disimpan sebagai Dipublikasikan.'));
      expect(enL10n.materialSavedAsStatus('Published'), equals('Material successfully saved as Published.'));
    });
  });

  // =========================================================================
  // 3. Locale-Lock Protection Test
  // =========================================================================
  group('Material Locale-Lock Protection', () {
    testWidgets('Tanpa override locale, editor tetap merender Bahasa Indonesia', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: _createTeacherAuth(),
            child: MaterialEditorScreen(
              materiId: 'new',
              classId: 'class_01',
              meetingId: 'meet_01',
              materialRepository: _FakeMaterialRepo(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Buat Materi Baru'), findsOneWidget);
      expect(find.byTooltip('Simpan Draft'), findsOneWidget);
      expect(find.text('Create New Material'), findsNothing);
      expect(find.byTooltip('Save Draft'), findsNothing);
    });
  });
}

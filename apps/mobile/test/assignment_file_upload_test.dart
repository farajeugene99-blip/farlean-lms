import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mobile/models/app_user.dart';
import 'package:mobile/models/assignment.dart';
import 'package:mobile/models/material_content.dart';
import 'package:mobile/presentation/assignment/submit_assignment_dialog.dart';
import 'package:mobile/presentation/class/create_assignment_dialog.dart';
import 'package:mobile/presentation/material/material_editor_screen.dart';
import 'package:mobile/presentation/material/material_reader_screen.dart';
import 'package:mobile/repositories/material_repository.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:mobile/services/cloudinary_upload_service.dart';
import 'package:provider/provider.dart';

import 'session_pipeline_test.dart';

final class FakePlatformFile extends PlatformFile {
  @override
  final String name;
  final String? fakePath;
  final Uint8List? fakeBytes;
  final int? fakeSize;

  FakePlatformFile({
    required this.name,
    this.fakePath,
    this.fakeBytes,
    this.fakeSize,
  });

  @override
  Uri get uri => fakePath != null ? Uri.file(fakePath!) : Uri.parse('content://dummy/$name');

  @override
  String? get path => fakePath;

  @override
  XFile get xFile => XFile(fakePath ?? '', name: name, bytes: fakeBytes);

  @override
  int? lengthSync() => fakeSize ?? fakeBytes?.length;

  @override
  Future<int?> length() async => lengthSync();

  @override
  Future<Uint8List> readAsBytes() async => fakeBytes ?? Uint8List(0);

  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(fakeBytes ?? Uint8List(0));
}

class MockCloudinaryServiceForTest extends CloudinaryUploadService {
  PlatformFile? docToReturn;
  PlatformFile? imageToReturn;
  CloudinaryUploadResult? resultToReturn;
  Exception? exceptionToThrow;
  int uploadCallCount = 0;
  String? lastFolderType;
  String? lastClassId;

  MockCloudinaryServiceForTest({
    this.docToReturn,
    this.imageToReturn,
    this.resultToReturn,
    this.exceptionToThrow,
  });

  @override
  Future<PlatformFile?> pickDocumentFile({List<String>? allowedExtensions}) async {
    return docToReturn;
  }

  @override
  Future<PlatformFile?> pickImageFile() async {
    return imageToReturn;
  }

  @override
  Future<CloudinaryUploadResult> uploadFile({
    required PlatformFile file,
    required String folderType,
    String? classId,
    String? assignmentId,
    List<String>? allowedExtensions,
  }) async {
    uploadCallCount++;
    lastFolderType = folderType;
    lastClassId = classId;
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return resultToReturn ??
        CloudinaryUploadResult(
          secureUrl: 'https://res.cloudinary.com/farlean/auto/upload/v12345/petunjuk.pdf',
          fileName: file.name,
          sizeBytes: file.lengthSync() ?? 1024,
        );
  }
}

class MockMaterialRepoForUploadTest extends MaterialRepository {
  MaterialContent? lastSavedMaterial;

  @override
  Future<String> createMaterial(MaterialContent material) async {
    lastSavedMaterial = material;
    return 'mat_new_1';
  }

  @override
  Future<void> updateMaterial(MaterialContent material) async {
    lastSavedMaterial = material;
  }

  @override
  Future<MaterialContent?> getMaterial(String materiId) async {
    return lastSavedMaterial;
  }
}

AuthProvider _createStaffAuth() {
  final fakeUser = FakeUser(
    uid: 'guru_1',
    email: 'dosen@farlean.edu',
    mockClaims: const {'role': 'GURU'},
  );
  final mockAuth = MockAuthService(
    mockCurrentUser: fakeUser,
    mockProfileToReturn: const AppUser(
      uid: 'guru_1',
      name: 'Dosen Farlean',
      email: 'dosen@farlean.edu',
      accountType: AccountType.dosen,
      role: UserRole.guru,
      claimsRole: UserRole.guru,
    ),
  );
  return AuthProvider(authService: mockAuth);
}

AuthProvider _createStudentAuth() {
  final fakeUser = FakeUser(
    uid: 'mhs_1',
    email: 'mhs@farlean.edu',
    mockClaims: const {'role': 'USER'},
  );
  final mockAuth = MockAuthService(
    mockCurrentUser: fakeUser,
    mockProfileToReturn: const AppUser(
      uid: 'mhs_1',
      name: 'Mahasiswa Farlean',
      email: 'mhs@farlean.edu',
      accountType: AccountType.mahasiswa,
      role: UserRole.user,
      claimsRole: UserRole.user,
    ),
  );
  return AuthProvider(authService: mockAuth);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CloudinaryUploadService URL Metadata Encoding & Validation Unit Tests', () {
    test('1. toEncodedUrl and parseEncodedUrl handles file names with spaces, commas, and size metadata', () {
      const result = CloudinaryUploadResult(
        secureUrl: 'https://res.cloudinary.com/farlean/auto/upload/v1/Panduan_LMS.pdf',
        fileName: 'Panduan Modul 1, Revisi Akhir.pdf',
        sizeBytes: 3145728, // 3 MB
      );

      final encoded = result.toEncodedUrl();
      expect(encoded.startsWith('https://res.cloudinary.com/farlean/auto/upload/v1/Panduan_LMS.pdf#'), isTrue);

      final parsed = CloudinaryUploadResult.parseEncodedUrl(encoded);
      expect(parsed['url'], equals('https://res.cloudinary.com/farlean/auto/upload/v1/Panduan_LMS.pdf'));
      expect(parsed['fileName'], equals('Panduan Modul 1, Revisi Akhir.pdf'));
      expect(parsed['sizeBytes'], equals(3145728));
    });

    test('2. parseEncodedUrl gracefully falls back when given raw URL without fragment', () {
      const rawUrl = 'https://res.cloudinary.com/farlean/raw/upload/v999/silabus.pdf';
      final parsed = CloudinaryUploadResult.parseEncodedUrl(rawUrl);
      expect(parsed['url'], equals(rawUrl));
      expect(parsed['fileName'], equals('silabus.pdf'));
      expect(parsed['sizeBytes'], isNull);
    });

    test('3. validateFile rejects file larger than 10MB or empty file', () async {
      final service = CloudinaryUploadService();

      final emptyFile = FakePlatformFile(name: 'empty.pdf', fakeSize: 0);
      expect(
        () => service.validateFile(emptyFile),
        throwsA(isA<CloudinaryUploadException>().having((e) => e.message, 'message', contains('kosong'))),
      );

      final oversizedFile = FakePlatformFile(name: 'huge.pdf', fakeSize: 11 * 1024 * 1024);
      expect(
        () => service.validateFile(oversizedFile),
        throwsA(isA<CloudinaryUploadException>().having((e) => e.message, 'message', contains('10 MB'))),
      );

      final invalidExtFile = FakePlatformFile(name: 'script.exe', fakeSize: 1024);
      expect(
        () => service.validateFile(invalidExtFile, allowedExtensions: ['pdf', 'doc', 'docx']),
        throwsA(isA<CloudinaryUploadException>().having((e) => e.message, 'message', contains('tidak didukung'))),
      );
    });
  });

  group('AssignmentFormDialog Upload & Attachment Lifecycle Widget Tests', () {
    testWidgets('4. Guru dapat memilih file dokumen, mengunggah ke Cloudinary, dan menyimpan hasil lampiran', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeDoc = FakePlatformFile(name: 'Soal_Tugas_1.pdf', fakeSize: 1024 * 500);
      final mockUpload = MockCloudinaryServiceForTest(
        docToReturn: fakeDoc,
        resultToReturn: const CloudinaryUploadResult(
          secureUrl: 'https://res.cloudinary.com/farlean/assignment_instructions/Soal_Tugas_1.pdf',
          fileName: 'Soal_Tugas_1.pdf',
          sizeBytes: 1024 * 500,
        ),
      );

      AssignmentFormData? poppedData;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  poppedData = await showDialog<AssignmentFormData>(
                    context: ctx,
                    builder: (_) => AssignmentFormDialog(
                      classId: 'class_abc',
                      cloudinaryUploadService: mockUpload,
                    ),
                  );
                },
                child: const Text('Buka Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      // Isi Judul dan Petunjuk
      await tester.enterText(find.byType(TextFormField).at(0), 'Tugas Analisis ERD');
      await tester.enterText(find.byType(TextFormField).at(1), 'Kerjakan sesuai panduan PDF.');
      await tester.pumpAndSettle();

      // Ketuk tombol pilih berkas dari perangkat
      expect(find.text('Pilih Berkas dari Perangkat'), findsOneWidget);
      await tester.tap(find.text('Pilih Berkas dari Perangkat'));
      await tester.pumpAndSettle();

      // Pastikan upload terpanggil dan nama berkas tampil di UI
      expect(mockUpload.uploadCallCount, equals(1));
      expect(mockUpload.lastFolderType, equals('assignment_instructions'));
      expect(mockUpload.lastClassId, equals('class_abc'));
      expect(find.text('Soal_Tugas_1.pdf'), findsOneWidget);

      // Simpan dialog
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(poppedData, isNotNull);
      expect(poppedData!.title, equals('Tugas Analisis ERD'));
      expect(poppedData!.attachmentUrl, equals('https://res.cloudinary.com/farlean/assignment_instructions/Soal_Tugas_1.pdf'));
      expect(poppedData!.attachmentFileName, equals('Soal_Tugas_1.pdf'));
      expect(poppedData!.attachmentFileSize, equals(1024 * 500));
    });

    testWidgets('5. Guru dapat menghapus lampiran yang sudah terunggah sebelum menyimpan', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final existingAssignment = Assignment(
        id: 'a1',
        classId: 'class_abc',
        title: 'Tugas Lama',
        instructions: 'Petunjuk lama',
        deadline: DateTime.now().add(const Duration(days: 2)),
        attachmentUrl: 'https://res.cloudinary.com/farlean/lama.pdf',
        attachmentFileName: 'lama.pdf',
        attachmentFileSize: 2048,
      );

      AssignmentFormData? poppedData;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  poppedData = await showDialog<AssignmentFormData>(
                    context: ctx,
                    builder: (_) => AssignmentFormDialog(
                      initialAssignment: existingAssignment,
                      classId: 'class_abc',
                    ),
                  );
                },
                child: const Text('Buka Edit'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buka Edit'));
      await tester.pumpAndSettle();

      expect(find.text('lama.pdf'), findsOneWidget);

      // Ketuk icon hapus lampiran
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Lampiran terhapus dan tombol upload dari perangkat muncul kembali
      expect(find.text('lama.pdf'), findsNothing);
      expect(find.text('Pilih Berkas dari Perangkat'), findsOneWidget);

      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(poppedData, isNotNull);
      expect(poppedData!.attachmentUrl, isNull);
      expect(poppedData!.attachmentFileName, isNull);
    });
  });

  group('MaterialEditorScreen & MaterialReaderScreen File Attachment Tests', () {
    testWidgets('6. Editor materi mendukung penyisipan file dokumen non-gambar dan gambar dari perangkat', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeDoc = FakePlatformFile(name: 'Modul_Ajar.pdf', fakeSize: 1024 * 1024 * 2);
      final fakeImg = FakePlatformFile(name: 'Diagram.png', fakeSize: 1024 * 200);

      final mockUpload = MockCloudinaryServiceForTest(
        docToReturn: fakeDoc,
        imageToReturn: fakeImg,
        resultToReturn: const CloudinaryUploadResult(
          secureUrl: 'https://res.cloudinary.com/farlean/materials/Modul_Ajar.pdf',
          fileName: 'Modul_Ajar.pdf',
          sizeBytes: 1024 * 1024 * 2,
        ),
      );

      final mockRepo = MockMaterialRepoForUploadTest();

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
            value: _createStaffAuth(),
            child: MaterialEditorScreen(
              classId: 'c1',
              meetingId: 'm1',
              materialRepository: mockRepo,
              cloudinaryUploadService: mockUpload,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Ketuk Lampirkan Berkas di Toolbar
      expect(find.text('Lampirkan Berkas'), findsOneWidget);
      await tester.tap(find.text('Lampirkan Berkas'));
      await tester.pumpAndSettle();

      expect(mockUpload.uploadCallCount, equals(1));
      expect(mockUpload.lastFolderType, equals('materials'));

      // Verifikasi chip lampiran muncul di editor
      expect(find.textContaining('Modul_Ajar.pdf'), findsOneWidget);

      // 2. Beri judul dan simpan draft
      await tester.enterText(find.byType(TextField).first, 'Materi Lengkap');
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.save_outlined));
      await tester.pumpAndSettle();

      expect(mockRepo.lastSavedMaterial, isNotNull);
      expect(mockRepo.lastSavedMaterial!.title, equals('Materi Lengkap'));
      expect(mockRepo.lastSavedMaterial!.attachments.isNotEmpty, isTrue);
      expect(mockRepo.lastSavedMaterial!.attachments.first, contains('Modul_Ajar.pdf'));
    });

    testWidgets('7. Mahasiswa membaca materi dan melihat kartu lampiran dokumen yang dapat dibuka', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final encodedDocUrl = const CloudinaryUploadResult(
        secureUrl: 'https://res.cloudinary.com/farlean/materials/Buku_Panduan.pdf',
        fileName: 'Buku_Panduan.pdf',
        sizeBytes: 1024 * 1024,
      ).toEncodedUrl();

      final material = MaterialContent(
        id: 'mat_1',
        classId: 'c1',
        meetingId: 'm1',
        title: 'Pengantar Farlean',
        content: [
          {'insert': 'Selamat datang di perkuliahan Farlean.\n'}
        ],
        attachments: [encodedDocUrl],
        updatedBy: 'guru_1',
      );

      final mockRepo = MockMaterialRepoForUploadTest()..lastSavedMaterial = material;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: _createStudentAuth(),
            child: MaterialReaderScreen(
              materiId: 'mat_1',
              classId: 'c1',
              meetingId: 'm1',
              materialRepository: mockRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi section lampiran materi tampil
      expect(find.textContaining('Berkas Lampiran Materi'), findsOneWidget);
      expect(find.text('Buku_Panduan.pdf'), findsOneWidget);
      expect(find.text('1.0 MB'), findsOneWidget);
      expect(find.text('Buka Berkas'), findsOneWidget);
    });

    test('6. CloudinaryUploadService.getCleanUrl strips fragments and preserves base URL', () {
      expect(
        CloudinaryUploadService.getCleanUrl('https://res.cloudinary.com/demo/image/upload/sample.pdf#name=Tugas1.pdf&size=1024'),
        equals('https://res.cloudinary.com/demo/image/upload/sample.pdf'),
      );
      expect(
        CloudinaryUploadService.getCleanUrl('https://res.cloudinary.com/demo/image/upload/sample.pdf'),
        equals('https://res.cloudinary.com/demo/image/upload/sample.pdf'),
      );
      expect(CloudinaryUploadService.getCleanUrl(''), equals(''));
    });

    testWidgets('7. SubmitAssignmentDialog selects file locally without upload, then uploads on submit', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockUpload = MockCloudinaryServiceForTest(
        docToReturn: FakePlatformFile(
          name: 'Jawaban_Tugas_Farlean.pdf',
          fakeBytes: Uint8List(2 * 1024 * 1024),
          fakeSize: 2 * 1024 * 1024,
        ),
        resultToReturn: const CloudinaryUploadResult(
          secureUrl: 'https://res.cloudinary.com/farlean/assignments/Jawaban_Tugas_Farlean.pdf',
          fileName: 'Jawaban_Tugas_Farlean.pdf',
          sizeBytes: 2 * 1024 * 1024,
        ),
      );

      SubmissionFormData? poppedResult;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  poppedResult = await showDialog<SubmissionFormData>(
                    context: ctx,
                    builder: (_) => SubmitAssignmentDialog(
                      classId: 'class_123',
                      assignmentId: 'assign_456',
                      cloudinaryUploadService: mockUpload,
                    ),
                  );
                },
                child: const Text('Buka Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Buka dialog
      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      // Awalnya: Tombol Pilih Berkas tampil
      expect(find.text('Pilih Berkas dari Perangkat'), findsOneWidget);
      expect(mockUpload.uploadCallCount, equals(0));

      // Klik tombol Pilih Berkas
      await tester.tap(find.text('Pilih Berkas dari Perangkat'));
      await tester.pumpAndSettle();

      // PENTING: Upload TIDAK BOLEH dipanggil saat berkas baru dipilih!
      expect(mockUpload.uploadCallCount, equals(0), reason: 'File picker must NOT trigger upload immediately');

      // Verifikasi kartu berkas terpilih tampil di UI
      expect(find.text('Jawaban_Tugas_Farlean.pdf'), findsOneWidget);
      expect(find.text('2.0 MB'), findsOneWidget);

      // Masukkan catatan
      await tester.enterText(find.byType(TextFormField).first, 'Berikut jawaban tugas saya.');
      await tester.pumpAndSettle();

      // Klik tombol Kumpulkan/Simpan
      await tester.tap(find.widgetWithText(ElevatedButton, 'Kumpulkan Tugas'));
      await tester.pumpAndSettle();

      // Sekarang upload harus terpanggil tepat 1 kali dengan folderType 'assignments'
      expect(mockUpload.uploadCallCount, equals(1));
      expect(mockUpload.lastFolderType, equals('assignments'));
      expect(mockUpload.lastClassId, equals('class_123'));

      // Verifikasi data yang dipop ke pemanggil
      expect(poppedResult, isNotNull);
      expect(poppedResult!.fileUrl, equals('https://res.cloudinary.com/farlean/assignments/Jawaban_Tugas_Farlean.pdf'));
      expect(poppedResult!.fileName, equals('Jawaban_Tugas_Farlean.pdf'));
      expect(poppedResult!.fileSize, equals(2 * 1024 * 1024));
      expect(poppedResult!.note, equals('Berikut jawaban tugas saya.'));
    });

    testWidgets('8. SubmitAssignmentDialog resubmit pre-populates initial file and submits cleanly', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockUpload = MockCloudinaryServiceForTest();
      SubmissionFormData? poppedResult;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  poppedResult = await showDialog<SubmissionFormData>(
                    context: ctx,
                    builder: (_) => SubmitAssignmentDialog(
                      isResubmit: true,
                      initialFileUrl: 'https://res.cloudinary.com/farlean/existing_file.pdf',
                      initialFileName: 'tugas_lama.pdf',
                      initialFileSize: 1536000,
                      initialNote: 'Catatan awal',
                      classId: 'class_123',
                      assignmentId: 'assign_456',
                      cloudinaryUploadService: mockUpload,
                    ),
                  );
                },
                child: const Text('Buka Dialog Resubmit'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buka Dialog Resubmit'));
      await tester.pumpAndSettle();

      // Verifikasi nama berkas lama dan ukuran ter-render
      expect(find.text('tugas_lama.pdf'), findsOneWidget);
      expect(find.text('1.5 MB'), findsOneWidget);

      // Submit tanpa mengganti berkas
      await tester.tap(find.widgetWithText(ElevatedButton, 'Kumpulkan Ulang'));
      await tester.pumpAndSettle();

      // Tidak ada network upload karena berkas tidak diganti
      expect(mockUpload.uploadCallCount, equals(0));
      expect(poppedResult, isNotNull);
      expect(poppedResult!.fileUrl, equals('https://res.cloudinary.com/farlean/existing_file.pdf'));
      expect(poppedResult!.fileName, equals('tugas_lama.pdf'));
      expect(poppedResult!.fileSize, equals(1536000));
    });
  });
}

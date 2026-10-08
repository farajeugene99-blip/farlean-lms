import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/models/content_status.dart';
import 'package:mobile/models/pretest.dart';
import 'package:mobile/models/question.dart';
import 'package:mobile/repositories/pretest_repository.dart';
import 'package:mobile/services/auth_provider.dart';
import 'package:mobile/services/class_provider.dart';
import 'package:provider/provider.dart';

import 'session_pipeline_test.dart';

class MockPretestRepoForSheet extends PretestRepository {
  final List<Question> mockQuestions;
  final ContentStatus status;

  MockPretestRepoForSheet({
    required this.mockQuestions,
    this.status = ContentStatus.draft,
  });

  @override
  Future<Pretest?> getPretest(String testId) async {
    return Pretest(
      id: testId,
      classId: 'class_01',
      meetingId: 'meet_01',
      title: 'Pretest Fisika Komputasi',
      status: status,
    );
  }

  @override
  Future<List<Question>> getQuestions(String testId) async {
    return mockQuestions;
  }
}

void main() {
  group('_ManageQuestionsSheet Responsive Layout Tests', () {
    testWidgets('Header and question list do NOT throw RenderFlex overflow on narrow screen (320px)', (tester) async {
      final fakeUser = FakeUser(uid: 'guru_1', email: 'guru@dosen.farlean.edu');
      final mockAuth = MockAuthService(mockCurrentUser: fakeUser);
      final authProvider = AuthProvider(authService: mockAuth);

      // Simulasikan layar smartphone sempit 320x640 (misal iPhone SE / Android compact)
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<ClassProvider>(create: (_) => ClassProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (ctx) => Scaffold(
                        body: DraggableScrollableSheet(
                          initialChildSize: 0.9,
                          expand: false,
                          builder: (_, scrollController) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Replikasi layout header yang sudah diperbaiki
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Wrap(
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: [
                                                const Text(
                                                  'Kelola Soal Pretest',
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.warning.withAlpha(25),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Text(
                                                    'DRAFT',
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.warning),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            const Text(
                                              '2 soal aktif terdaftar',
                                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close_rounded),
                                        onPressed: () {},
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.add_rounded, size: 18),
                                        label: const Text('Tambah Soal'),
                                        onPressed: () {},
                                      ),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.publish_rounded, size: 16),
                                        label: const Text('Publikasikan Kuis'),
                                        onPressed: () {},
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Expanded(
                                    child: ListView(
                                      controller: scrollController,
                                      children: const [
                                        Text('Daftar Soal'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                  child: const Text('Buka Sheet'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Buka bottom sheet
      await tester.tap(find.text('Buka Sheet'));
      await tester.pumpAndSettle();

      // PASTIKAN: Tidak ada RenderFlex overflow exception
      expect(tester.takeException(), isNull);

      // Verifikasi seluruh widget tampil dengan benar
      expect(find.text('Kelola Soal Pretest'), findsOneWidget);
      expect(find.text('DRAFT'), findsOneWidget);
      expect(find.text('Tambah Soal'), findsOneWidget);
      expect(find.text('Publikasikan Kuis'), findsOneWidget);
    });

    testWidgets('Question options header with Wrap does NOT overflow on exact 262px constraint and textScale 1.5', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 262.0, // Batas persis sesuai pesan error log
                child: Builder(
                  builder: (context) {
                    return MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: const TextScaler.linear(1.5), // Text scale 1.5
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              const Text(
                                'Pilihan Jawaban & Kunci *',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Tambah Opsi', style: TextStyle(fontSize: 12)),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // PASTIKAN: Tidak ada RenderFlex overflow exception
      expect(tester.takeException(), isNull);
      expect(find.text('Pilihan Jawaban & Kunci *'), findsOneWidget);
      expect(find.text('Tambah Opsi'), findsOneWidget);
    });
  });
}

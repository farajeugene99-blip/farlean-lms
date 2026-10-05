import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_constants.dart';
import '../../core/theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(AppConstants.appName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_rounded),
            tooltip: 'Gabung Kelas',
            onPressed: () => context.push(AppConstants.joinClassRoute),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Phase 2: Pembelajaran Aktif',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Selamat Datang di Farlean LMS',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Modul pembelajaran terstruktur, kuis pretest dengan penilaian server, video materi, dan buku panduan telah aktif.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('${AppConstants.materiRoute}?classId=class_test_qa'),
                          icon: const Icon(Icons.menu_book_rounded, size: 18),
                          label: const Text('Materi & Pertemuan'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/manual-books?classId=class_test_qa'),
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                          label: const Text('Buku Panduan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Kelas Anda',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => context.push(AppConstants.joinClassRoute),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Gabung Kelas'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 40,
                      color: AppTheme.primary.withAlpha(160),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Kelas Pemrograman Mobile Terapan',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Status: Anggota Aktif • Akses Penuh ke Pertemuan',
                      style: TextStyle(fontSize: 12, color: AppTheme.success, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () => context.go('${AppConstants.materiRoute}?classId=class_test_qa'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(160, 36)),
                      child: const Text('Buka Sesi Pembelajaran'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

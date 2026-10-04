import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_constants.dart';
import '../../core/theme/app_theme.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi Email')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 56,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Periksa Email Anda',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Kami telah mengirimkan tautan verifikasi ke email Anda. Akun baru belum dapat mengakses kelas sebelum email terverifikasi.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () {
                  // Di Step 1.3: panggil reload() + getIdToken(true)
                  context.go(AppConstants.dashboardRoute);
                },
                icon: const Icon(Icons.check_rounded, size: 20),
                label: const Text('Saya Sudah Verifikasi'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  // Di Step 1.3: kirim ulang email verifikasi
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tautan verifikasi telah dikirim ulang.'),
                    ),
                  );
                },
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Kirim Ulang Email'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go(AppConstants.loginRoute),
                child: const Text('Kembali ke Halaman Masuk'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

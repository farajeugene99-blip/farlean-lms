import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_constants.dart';
import '../../core/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
            onPressed: () {
              // Akan diintegrasikan dengan AuthService di Step 1.3
              context.go(AppConstants.loginRoute);
            },
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
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppTheme.primary.withAlpha(30),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 40,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pengguna Farlean',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'user@example.com',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBadge('Tipe: UMUM', AppTheme.primary),
                      const SizedBox(width: 8),
                      _buildBadge('Role: USER', AppTheme.secondary),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Nomor Induk (NIM / NIP)'),
                  subtitle: const Text('Tersimpan di private identity'),
                  trailing: const Icon(Icons.lock_outline, size: 18),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security_rounded),
                  title: const Text('Status Email'),
                  subtitle: const Text('Terverifikasi'),
                  trailing: const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.success,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/config/app_constants.dart';
import '../presentation/auth/forgot_password_screen.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/auth/register_screen.dart';
import '../presentation/auth/verify_email_screen.dart';
import '../presentation/main/dashboard_screen.dart';
import '../presentation/main/join_class_screen.dart';
import '../presentation/main/main_shell.dart';
import '../presentation/main/placeholder_screen.dart';
import '../presentation/main/profile_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppConstants.loginRoute,
    routes: [
      // Auth Routes
      GoRoute(
        path: AppConstants.loginRoute,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.registerRoute,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppConstants.verifyEmailRoute,
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: AppConstants.forgotPasswordRoute,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Standalone modal / stack route
      GoRoute(
        path: AppConstants.joinClassRoute,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const JoinClassScreen(),
      ),

      // Main Navigation Shell (5 floating menu items)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppConstants.dashboardRoute,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppConstants.materiRoute,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PlaceholderScreen(
                title: 'Materi Pembelajaran',
                description:
                    'Modul pembelajaran terstruktur, video materi, dan manual book akan hadir pada Phase 2.',
                icon: Icons.menu_book_rounded,
                targetPhase: 'Segera Hadir di Phase 2',
              ),
            ),
          ),
          GoRoute(
            path: AppConstants.aiRoute,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PlaceholderScreen(
                title: 'AI Tutor Pintar',
                description:
                    'Asisten belajar cerdas bertenaga AI untuk bimbingan personal akan hadir pada Phase 3.',
                icon: Icons.auto_awesome_rounded,
                targetPhase: 'Segera Hadir di Phase 3',
              ),
            ),
          ),
          GoRoute(
            path: AppConstants.diskusiRoute,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PlaceholderScreen(
                title: 'Forum Diskusi',
                description:
                    'Ruang kolaborasi dan tanya jawab antar peserta kelas dan pengajar akan hadir pada Phase 2.',
                icon: Icons.forum_rounded,
                targetPhase: 'Segera Hadir di Phase 2',
              ),
            ),
          ),
          GoRoute(
            path: AppConstants.profileRoute,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}

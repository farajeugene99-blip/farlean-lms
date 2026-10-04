import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/config/app_constants.dart';
import '../models/material_content.dart';
import '../models/meeting.dart';
import '../models/video_item.dart';
import '../presentation/auth/forgot_password_screen.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/auth/register_screen.dart';
import '../presentation/auth/verify_email_screen.dart';
import '../presentation/main/dashboard_screen.dart';
import '../presentation/main/join_class_screen.dart';
import '../presentation/main/main_shell.dart';
import '../presentation/main/placeholder_screen.dart';
import '../presentation/main/profile_screen.dart';
import '../presentation/manual_book/manual_book_list_screen.dart';
import '../presentation/material/material_editor_screen.dart';
import '../presentation/material/material_reader_screen.dart';
import '../presentation/meeting/meeting_detail_screen.dart';
import '../presentation/meeting/meeting_list_screen.dart';
import '../presentation/video/video_player_screen.dart';
import '../services/auth_provider.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: AppConstants.loginRoute,
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isEmailVerified = authProvider.isEmailVerified;
        final currentPath = state.uri.path;

        final isAuthRoute = currentPath == AppConstants.loginRoute ||
            currentPath == AppConstants.registerRoute ||
            currentPath == AppConstants.forgotPasswordRoute;

        // 1. Jika belum login dan berada di route terproteksi
        if (!isAuthenticated) {
          if (isAuthRoute) return null;
          return AppConstants.loginRoute;
        }

        // 2. Jika sudah login tetapi email belum terverifikasi
        if (!isEmailVerified) {
          if (currentPath == AppConstants.verifyEmailRoute) return null;
          return AppConstants.verifyEmailRoute;
        }

        // 3. Jika sudah login dan terverifikasi, cegah akses ulang halaman auth
        if (isAuthRoute || currentPath == AppConstants.verifyEmailRoute) {
          return AppConstants.dashboardRoute;
        }

        return null;
      },
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
        GoRoute(
          path: '/meetings/:meetingId',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final meetingId = state.pathParameters['meetingId'] ?? '';
            final extraMeeting = state.extra as Meeting?;
            return MeetingDetailScreen(
              meetingId: meetingId,
              initialMeeting: extraMeeting,
            );
          },
        ),
        GoRoute(
          path: '/materials/:materiId',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final materiId = state.pathParameters['materiId'] ?? '';
            final classId = state.uri.queryParameters['classId'] ?? '';
            final meetingId = state.uri.queryParameters['meetingId'] ?? '';
            return MaterialReaderScreen(
              materiId: materiId,
              classId: classId,
              meetingId: meetingId,
            );
          },
        ),
        GoRoute(
          path: '/materials/:materiId/edit',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final materiId = state.pathParameters['materiId'] ?? '';
            final extraMaterial = state.extra as MaterialContent?;
            final classId = state.uri.queryParameters['classId'] ?? '';
            final meetingId = state.uri.queryParameters['meetingId'] ?? '';
            return MaterialEditorScreen(
              materiId: materiId,
              initialMaterial: extraMaterial,
              classId: classId,
              meetingId: meetingId,
            );
          },
        ),
        GoRoute(
          path: '/videos/:videoId',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final videoId = state.pathParameters['videoId'] ?? '';
            final extraVideo = state.extra as VideoItem?;
            return VideoPlayerScreen(
              videoId: videoId,
              initialVideo: extraVideo,
            );
          },
        ),
        GoRoute(
          path: '/manual-books',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final classId = state.uri.queryParameters['classId'] ?? 'default_class';
            return ManualBookListScreen(classId: classId);
          },
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
                child: MeetingListScreen(),
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
}

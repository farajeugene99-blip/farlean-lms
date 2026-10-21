import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/config/app_constants.dart';
import '../models/assignment.dart';
import '../models/material_content.dart';
import '../models/meeting.dart';
import '../models/video_item.dart';
import '../presentation/ai/ai_tutor_screen.dart';
import '../presentation/assignment/assignment_detail_screen.dart';
import '../presentation/auth/complete_profile_screen.dart';
import '../presentation/auth/forgot_password_screen.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/auth/register_screen.dart';
import '../presentation/auth/verify_email_screen.dart';
import '../presentation/class/class_detail_screen.dart';
import '../presentation/discussion/discussion_list_screen.dart';
import '../presentation/discussion/thread_detail_screen.dart';
import '../presentation/main/dashboard_screen.dart';
import '../presentation/main/join_class_screen.dart';
import '../presentation/main/main_shell.dart';
import '../presentation/main/profile_screen.dart';
import '../presentation/manual_book/manual_book_list_screen.dart';
import '../presentation/material/material_editor_screen.dart';
import '../presentation/material/material_reader_screen.dart';
import '../presentation/meeting/meeting_detail_screen.dart';
import '../presentation/meeting/meeting_list_screen.dart';
import '../presentation/posttest/posttest_screen.dart';
import '../presentation/pretest/pretest_screen.dart';
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
        final isProfileComplete = authProvider.isProfileComplete;
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

        // 3. Jika sudah login dan terverifikasi tetapi profil belum lengkap (Onboarding Google)
        if (!isProfileComplete) {
          if (currentPath == AppConstants.completeProfileRoute) return null;
          return AppConstants.completeProfileRoute;
        }

        // 4. Jika sudah login, terverifikasi, dan profil lengkap, cegah akses ulang halaman auth & onboarding
        if (isAuthRoute ||
            currentPath == AppConstants.verifyEmailRoute ||
            currentPath == AppConstants.completeProfileRoute) {
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
        GoRoute(
          path: AppConstants.completeProfileRoute,
          builder: (context, state) => const CompleteProfileScreen(),
        ),

        // Standalone modal / stack route
        GoRoute(
          path: AppConstants.joinClassRoute,
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const JoinClassScreen(),
        ),
        GoRoute(
          path: '/classes/:classId',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final classId = state.pathParameters['classId'] ?? '';
            return ClassDetailScreen(classId: classId);
          },
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
            final classId = state.uri.queryParameters['classId'];
            return ManualBookListScreen(classId: classId);
          },
        ),
        GoRoute(
          path: '/assignments/:assignmentId',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final assignmentId = state.pathParameters['assignmentId'] ?? '';
            final classId = state.uri.queryParameters['classId'] ?? '';
            final initialAssignment = state.extra as Assignment?;
            return AssignmentDetailScreen(
              assignmentId: assignmentId,
              classId: classId,
              initialAssignment: initialAssignment,
            );
          },
        ),
        GoRoute(
          path: '/pretests/:pretestId',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final pretestId = state.pathParameters['pretestId'] ?? '';
            final classId = state.uri.queryParameters['classId'] ?? '';
            final meetingId = state.uri.queryParameters['meetingId'] ?? '';
            return PretestScreen(
              pretestId: pretestId,
              classId: classId,
              meetingId: meetingId,
            );
          },
        ),
        GoRoute(
          path: '/posttests/:posttestId',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final posttestId = state.pathParameters['posttestId'] ?? '';
            final classId = state.uri.queryParameters['classId'] ?? '';
            final meetingId = state.uri.queryParameters['meetingId'] ?? '';
            return PosttestScreen(
              posttestId: posttestId,
              classId: classId,
              meetingId: meetingId,
            );
          },
        ),
        GoRoute(
          path: '/diskusi/:discussionId',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final discussionId = state.pathParameters['discussionId'] ?? '';
            final classId = state.uri.queryParameters['classId'] ?? '';
            return ThreadDetailScreen(
              discussionId: discussionId,
              classId: classId,
            );
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
              pageBuilder: (context, state) {
                final classId = state.uri.queryParameters['classId'];
                return NoTransitionPage(
                  child: MeetingListScreen(classId: classId),
                );
              },
            ),
            GoRoute(
              path: AppConstants.aiRoute,
              pageBuilder: (context, state) {
                final classId = state.uri.queryParameters['classId'];
                final meetingId = state.uri.queryParameters['meetingId'];
                final materiId = state.uri.queryParameters['materiId'];
                final materiTitle = state.uri.queryParameters['materiTitle'];
                final initialPrompt = state.uri.queryParameters['initialPrompt'];
                return NoTransitionPage(
                  child: AiTutorScreen(
                    classId: classId,
                    meetingId: meetingId,
                    materiId: materiId,
                    materiTitle: materiTitle,
                    initialPrompt: initialPrompt,
                  ),
                );
              },
            ),
            GoRoute(
              path: AppConstants.diskusiRoute,
              pageBuilder: (context, state) {
                final classId = state.uri.queryParameters['classId'];
                return NoTransitionPage(
                  child: DiscussionListScreen(classId: classId),
                );
              },
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:shado/features/auth/domain/entities/user_session.dart';

import '../../features/admin/presentation/screens/admin_users_page.dart';
import '../../features/admin/presentation/screens/management_page.dart';
import '../../features/auth/presentation/screens/login_page.dart';
import '../../features/home/presentation/screens/home_page.dart';
import '../../features/lessons/presentation/screens/add_lesson/add_lesson_page.dart';
import '../../features/lessons/presentation/screens/edit_lesson/edit_lesson_page.dart';
import '../../features/lessons/presentation/screens/folder/folder_page.dart';
import '../../features/lessons/presentation/screens/lesson/lesson_page.dart';
import '../../features/lessons/presentation/screens/lessons/lessons_page.dart';
import '../../features/lessons/presentation/screens/main_shell/main_shell.dart';
import '../../features/lessons/presentation/screens/splash/splash_page.dart';
import '../../features/progress/presentation/screens/progress_page.dart';
import '../../features/settings/presentation/screens/settings_page.dart';
import '../../screens/design_gallery/design_gallery_screen.dart';
import '../bootstrap/app_bootstrap.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Routes reachable without a session.
const Set<String> _publicRoutes = {
  LoginPage.routePath,
  LoginPage.registerRoutePath,
};

/// Owner section prefix.
const String _adminSectionPrefix = '/admin';

/// Whether to open the design gallery right at startup.
const bool _openDesignGalleryAtLaunch = bool.fromEnvironment('design_gallery');

/// The app router. [bootstrap] tells it about session and warm-up changes;
/// access rules live in `redirect`.
GoRouter createAppRouter(AppBootstrap bootstrap) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: _openDesignGalleryAtLaunch
        ? DesignGalleryScreen.routePath
        : '/home',
    refreshListenable: bootstrap,
    redirect: (context, state) {
      final auth = bootstrap.session;
      final location = state.matchedLocation;
      final isPublic = _publicRoutes.contains(location);

      // The gallery is outside the session rules.
      if (location == DesignGalleryScreen.routePath) return null;

      // Keep the splash until the refresh token is checked.
      if (auth.status == AuthStatus.unknown) {
        return location == SplashPage.routePath ? null : SplashPage.routePath;
      }
      if (!auth.isAuthenticated) return isPublic ? null : LoginPage.routePath;
      // First-frame data is still warming up — keep the splash.
      if (bootstrap.isWarmingUp) {
        return location == SplashPage.routePath ? null : SplashPage.routePath;
      }
      // A signed-in user has nothing to do on the login or splash screens.
      if (isPublic || location == SplashPage.routePath) {
        return HomePage.routePath;
      }
      // Role-gated sections; the real check happens on the server.
      if (location.startsWith(_adminSectionPrefix) && !auth.isOwner) {
        return HomePage.routePath;
      }
      if (location == AddLessonPage.routePath && !auth.canAuthor) {
        return HomePage.routePath;
      }
      if (location.startsWith(ManagementPage.routePath) && !auth.canManage) {
        return HomePage.routePath;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: SplashPage.routePath,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: DesignGalleryScreen.routePath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DesignGalleryScreen(),
      ),
      GoRoute(
        path: LoginPage.routePath,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: LoginPage.registerRoutePath,
        builder: (context, state) => const LoginPage(isRegistration: true),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: HomePage.routePath,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: LessonsPage.routePath,
                builder: (context, state) => const LessonsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AddLessonPage.routePath,
                builder: (context, state) => const AddLessonPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: ProgressPage.routePath,
                builder: (context, state) => const ProgressPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: SettingsPage.routePath,
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
      // Owner sections open above the shell from the account menu.
      GoRoute(
        path: ManagementPage.routePath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ManagementPage(),
      ),
      GoRoute(
        path: AdminUsersPage.routePath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminUsersPage(),
      ),
      GoRoute(
        path: FolderPage.routePath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            FolderPage(folderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: LessonPage.routePath,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            LessonPage(lessonId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: EditLessonPage.routeSegment,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) =>
                EditLessonPage(lessonId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/pages/management_page.dart';
import '../../features/admin/presentation/pages/users_page.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/lessons/presentation/pages/add_lesson_page.dart';
import '../../features/lessons/presentation/pages/edit_lesson_page.dart';
import '../../features/lessons/presentation/pages/lesson_page.dart';
import '../../features/lessons/presentation/pages/lessons_page.dart';
import '../../features/lessons/presentation/pages/main_shell.dart';
import '../../features/lessons/presentation/pages/splash_page.dart';
import '../../features/progress/presentation/pages/progress_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../screens/design_gallery/design_gallery_screen.dart';
import '../bootstrap/app_bootstrap.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Маршруты, доступные без сессии.
const Set<String> _publicRoutes = {
  LoginPage.routePath,
  LoginPage.registerRoutePath,
};

/// Раздел владельца целиком: под ним могут появиться и другие страницы.
const String _adminSectionPrefix = '/admin';

/// Витрина дизайн-системы. Временная точка входа: живёт вне правил сессии,
/// чтобы её можно было открыть с любого состояния приложения.
///
/// Открыть сразу при запуске:
/// `flutter run --dart-define=design_gallery=true`
const bool _openDesignGalleryAtLaunch = bool.fromEnvironment('design_gallery');

final appRouterProvider = Provider<GoRouter>((ref) {
  // Роутер пересобирать нельзя — потеряется стек навигации, поэтому о смене
  // состояния он узнаёт через слушателя. Будим его и на смене сессии, и на
  // завершении прогрева данных — оба решают, пора ли уходить с заставки.
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(
    authControllerProvider.select((state) => state.status),
    (_, _) => refresh.value++,
    fireImmediately: true,
  );
  ref.listen(appBootstrapProvider, (_, _) => refresh.value++);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: _openDesignGalleryAtLaunch
        ? DesignGalleryScreen.routePath
        : '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final isPublic = _publicRoutes.contains(location);

      // Витрина не участвует в правилах сессии: она ничего не знает о данных
      // пользователя и нужна ровно для того, чтобы посмотреть компоненты.
      if (location == DesignGalleryScreen.routePath) return null;

      // Пока не знаем, жив ли refresh-токен, держим заставку: иначе на старте
      // мелькнёт экран входа у того, кто уже вошёл.
      if (auth.status == AuthStatus.unknown) {
        return location == SplashPage.routePath ? null : SplashPage.routePath;
      }
      if (!auth.isAuthenticated) return isPublic ? null : LoginPage.routePath;
      // Вошли, но данные к первому кадру ещё греются — держим заставку, чтобы
      // главный не мигнул пустыми баннерами прогресса.
      if (ref.read(appBootstrapProvider).isLoading) {
        return location == SplashPage.routePath ? null : SplashPage.routePath;
      }
      // Вошедшему на экранах входа и заставке делать нечего.
      if (isPublic || location == SplashPage.routePath) {
        return HomePage.routePath;
      }
      // Раздел админки — не защита, а порядок: сервер всё равно проверяет роль.
      if (location.startsWith(_adminSectionPrefix) && !auth.isOwner) {
        return HomePage.routePath;
      }
      // «Добавить» — только авторам, «Управление» — только владельцу. Это тоже
      // порядок, а не защита: создание и админку сервер проверяет сам.
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
      // Разделы владельца открываются поверх каркаса из меню аккаунта.
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
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/pages/users_page.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/lessons/presentation/pages/add_lesson_page.dart';
import '../../features/lessons/presentation/pages/edit_lesson_page.dart';
import '../../features/lessons/presentation/pages/home_page.dart';
import '../../features/lessons/presentation/pages/lesson_page.dart';
import '../../features/lessons/presentation/pages/main_shell.dart';
import '../../features/lessons/presentation/pages/splash_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Маршруты, доступные без сессии.
const Set<String> _publicRoutes = {'/login', '/register'};

final appRouterProvider = Provider<GoRouter>((ref) {
  // Роутер пересобирать нельзя — потеряется стек навигации, поэтому о смене
  // состояния сессии он узнаёт через слушателя.
  final refresh = ValueNotifier<AuthStatus>(AuthStatus.unknown);
  ref.onDispose(refresh.dispose);
  ref.listen(
    authControllerProvider.select((state) => state.status),
    (_, next) => refresh.value = next,
    fireImmediately: true,
  );

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final isPublic = _publicRoutes.contains(location);

      // Пока не знаем, жив ли refresh-токен, держим заставку: иначе на старте
      // мелькнёт экран входа у того, кто уже вошёл.
      if (auth.status == AuthStatus.unknown) {
        return location == '/splash' ? null : '/splash';
      }
      if (!auth.isAuthenticated) return isPublic ? null : '/login';
      // Вошедшему на экранах входа делать нечего.
      if (isPublic || location == '/splash') return '/home';
      // Раздел админки — не защита, а порядок: сервер всё равно проверяет роль.
      if (location.startsWith('/admin') && !auth.isOwner) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const LoginPage(isRegistration: true),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/add',
                builder: (context, state) => const AddLessonPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/admin/users',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminUsersPage(),
      ),
      GoRoute(
        path: '/lesson/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            LessonPage(lessonId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'edit',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) =>
                EditLessonPage(lessonId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
});

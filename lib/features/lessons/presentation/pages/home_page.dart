import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/lesson.dart';
import '../controllers/lessons_controller.dart';
import '../widgets/lesson_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(lessonsControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Главная'),
        actions: const [_AccountMenu()],
      ),
      body: lessons.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: '$error',
          onRetry: () => ref.read(lessonsControllerProvider.notifier).refresh(),
        ),
        data: (items) => items.isEmpty
            ? const _EmptyView()
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(lessonsControllerProvider.notifier).refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final lesson = items[index];
                    return LessonCard(
                      lesson: lesson,
                      onTap: () => context.push('/lesson/${lesson.id}'),
                      onDelete: () => _confirmDelete(context, ref, lesson),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Lesson lesson,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить урок?'),
        content: Text('«${lesson.title}» и его аудио будут удалены навсегда.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(lessonsControllerProvider.notifier).delete(lesson.id);
  }
}

/// Кто вошёл, выход и — владельцу — раздел с пользователями.
class _AccountMenu extends ConsumerWidget {
  const _AccountMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final email = auth.user?.email ?? '';

    return PopupMenuButton<String>(
      tooltip: email.isEmpty ? 'Аккаунт' : email,
      icon: const Icon(Icons.account_circle_outlined),
      onSelected: (value) async {
        switch (value) {
          case 'admin':
            context.push('/admin/users');
          case 'logout':
            await ref.read(authControllerProvider.notifier).signOut();
        }
      },
      itemBuilder: (context) => [
        if (email.isNotEmpty)
          PopupMenuItem(
            enabled: false,
            child: Text(email, overflow: TextOverflow.ellipsis),
          ),
        // Раздел показываем владельцу, но полагаться на это как на защиту
        // нельзя: роль проверяет сервер.
        if (auth.isOwner)
          const PopupMenuItem(
            value: 'admin',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.people_outline),
              title: Text('Пользователи'),
            ),
          ),
        const PopupMenuItem(
          value: 'logout',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout),
            title: Text('Выйти'),
          ),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.headphones_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('Уроков пока нет', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Перейдите на вкладку «Добавить», чтобы загрузить аудио '
              'и разметить текст.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}

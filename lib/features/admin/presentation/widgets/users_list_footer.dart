import 'package:flutter/material.dart';

/// Хвост списка пользователей: сколько показано и докачивается ли следующая
/// страница.
class UsersListFooter extends StatelessWidget {
  const UsersListFooter({
    super.key,
    required this.shownCount,
    required this.totalCount,
    required this.isLoadingMore,
  });

  final int shownCount;
  final int totalCount;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: isLoadingMore
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                'Показано $shownCount из $totalCount',
                style: theme.textTheme.bodySmall,
              ),
      ),
    );
  }
}

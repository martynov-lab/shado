import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';

/// Список пользователей не пришёл.
///
/// Отказ по роли — не ошибка, а нормальный ход событий: роль сняли только что,
/// раздел закроется по возврату на главную, и повторять здесь нечего.
class AdminErrorView extends StatelessWidget {
  const AdminErrorView({
    super.key,
    required this.error,
    required this.onRetryPressed,
  });

  final Object error;
  final VoidCallback onRetryPressed;

  @override
  Widget build(BuildContext context) {
    final isForbidden = switch (error) {
      ApiException(:final isForbidden) => isForbidden,
      _ => false,
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isForbidden
                  ? 'Раздел доступен только владельцу'
                  : 'Не удалось получить список: $error',
              textAlign: TextAlign.center,
            ),
            if (!isForbidden) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetryPressed,
                child: const Text('Повторить'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

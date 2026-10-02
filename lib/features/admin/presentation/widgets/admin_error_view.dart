import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';

/// Message shown when the user list failed to load.
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
                  ? 'This section is available to the owner only'
                  : 'Failed to load the list: $error',
              textAlign: TextAlign.center,
            ),
            if (!isForbidden) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetryPressed,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

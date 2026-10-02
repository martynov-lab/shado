import 'package:flutter/material.dart';

import 'package:shado/core/async/async_state.dart';
import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../lessons/domain/entities/lesson_category.dart';
import 'admin_error_view.dart';
import 'topic_tile.dart';

/// Topic directory: create, rename and delete.
class TopicsAdminSection extends StatelessWidget {
  const TopicsAdminSection({
    super.key,
    required this.topics,
    required this.onAdd,
    required this.onRename,
    required this.onDelete,
    required this.onRetry,
  });

  final AsyncState<List<Topic>> topics;
  final VoidCallback onAdd;
  final ValueChanged<Topic> onRename;

  /// Not offered for the default topic: it can only be renamed.
  final ValueChanged<Topic> onDelete;

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Topics',
                  style: AppText.label.copyWith(color: colors.text2),
                ),
              ),
              AppButton(
                label: 'Add',
                icon: Icons.add_rounded,
                size: AppButtonSize.sm,
                variant: AppButtonVariant.secondary,
                onPressed: onAdd,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        Expanded(
          child: switch (topics) {
            AsyncFailed(:final error) => AdminErrorView(
              error: error,
              onRetryPressed: onRetry,
            ),
            AsyncReady(value: final topics) when topics.isEmpty => const Center(
              child: Text('No topics yet'),
            ),
            AsyncReady(value: final topics) => ListView.builder(
              itemCount: topics.length,
              itemBuilder: (context, index) {
                final topic = topics[index];
                return TopicTile(
                  topic: topic,
                  onRename: () => onRename(topic),
                  onDelete: topic.isDefault ? null : () => onDelete(topic),
                );
              },
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ],
    );
  }
}

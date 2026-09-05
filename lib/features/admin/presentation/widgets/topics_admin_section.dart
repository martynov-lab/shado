import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../../core/network/api_exception.dart';
import '../../../lessons/domain/entities/lesson_category.dart';
import '../../../lessons/presentation/controllers/topics_admin_controller.dart';
import '../../../settings/presentation/widgets/settings_text_edit_sheet.dart';
import 'admin_error_view.dart';
import 'delete_topic_dialog.dart';
import 'topic_tile.dart';

/// Topic directory: create, rename and delete.
class TopicsAdminSection extends ConsumerWidget {
  const TopicsAdminSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(topicsAdminControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Темы',
                  style: AppText.label.copyWith(color: colors.text2),
                ),
              ),
              AppButton(
                label: 'Добавить',
                icon: Icons.add_rounded,
                size: AppButtonSize.sm,
                variant: AppButtonVariant.secondary,
                onPressed: () => _create(context, ref),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        Expanded(
          child: switch (state) {
            AsyncError(:final error) => AdminErrorView(
              error: error,
              onRetryPressed: () =>
                  ref.invalidate(topicsAdminControllerProvider),
            ),
            AsyncData(value: final topics) when topics.isEmpty => const Center(
              child: Text('Тем пока нет'),
            ),
            AsyncData(value: final topics) => ListView.builder(
              itemCount: topics.length,
              itemBuilder: (context, index) {
                final topic = topics[index];
                return TopicTile(
                  topic: topic,
                  onRename: () => _rename(context, ref, topic),
                  // The default topic cannot be deleted, only renamed.
                  onDelete: topic.isDefault
                      ? null
                      : () => _delete(context, ref, topic),
                );
              },
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ],
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final name = await _promptName(context, title: 'Новая тема', initial: '');
    if (name == null || !context.mounted) return;
    await _run(
      context,
      () => ref.read(topicsAdminControllerProvider.notifier).create(name),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, Topic topic) async {
    final name = await _promptName(
      context,
      title: 'Переименовать тему',
      initial: topic.name,
    );
    if (name == null || !context.mounted) return;
    await _run(
      context,
      () => ref
          .read(topicsAdminControllerProvider.notifier)
          .rename(id: topic.id, name: name),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Topic topic) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteTopicDialog(topicName: topic.name),
    );
    if (confirmed != true || !context.mounted) return;
    await _run(
      context,
      () => ref.read(topicsAdminControllerProvider.notifier).delete(topic.id),
      success: 'Тема «${topic.name}» удалена',
    );
  }

  /// Name input sheet; `null` when cancelled or left empty.
  Future<String?> _promptName(
    BuildContext context, {
    required String title,
    required String initial,
  }) async {
    final raw = await showAppBottomSheet<String>(
      context: context,
      title: title,
      builder: (_) => SettingsTextEditSheet(
        label: 'Название темы',
        initialValue: initial,
        hint: 'Например, Путешествия',
      ),
    );
    final name = raw?.trim();
    return (name == null || name.isEmpty) ? null : name;
  }

  /// Runs the edit and reports the result.
  Future<void> _run(
    BuildContext context,
    Future<void> Function() action, {
    String? success,
  }) async {
    try {
      await action();
      if (context.mounted && success != null) _showMessage(context, success);
    } on ApiException catch (error) {
      if (context.mounted) _showMessage(context, error.message);
    } catch (error) {
      if (context.mounted) _showMessage(context, 'Не удалось сохранить: $error');
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../controllers/edit_lesson_controller.dart';
import '../widgets/edit_lesson_form.dart';
import '../widgets/version_conflict_dialog.dart';
import 'lesson_page.dart';

/// Правка урока: разбивка текста на куски и границы этих кусков на волне.
///
/// Экран возвращает `true`, если правки сохранены — экрану урока по этому
/// признаку надо перечитать себя.
class EditLessonPage extends ConsumerWidget {
  const EditLessonPage({super.key, required this.lessonId});

  /// Правка — вложенный маршрут урока, поэтому в роутер уходит только хвост.
  static const String routeSegment = 'edit';

  static String routeTo(String lessonId) =>
      '${LessonPage.routeTo(lessonId)}/$routeSegment';

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(editLessonControllerProvider(lessonId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Правка урока'),
        actions: [
          if (stateAsync.value case final state?)
            TextButton(
              onPressed: state.canSave ? () => _save(context, ref) : null,
              child: state.isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Сохранить'),
            ),
        ],
      ),
      body: switch (stateAsync) {
        AsyncError(:final error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('$error', textAlign: TextAlign.center),
          ),
        ),
        AsyncData(:final value) => EditLessonForm(
          lessonId: lessonId,
          state: value,
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(editLessonControllerProvider(lessonId).notifier).save();
      navigator.pop(true);
    } on ApiException catch (error) {
      if (!error.isVersionConflict) {
        messenger.showSnackBar(
          SnackBar(content: Text('Не удалось сохранить: ${error.message}')),
        );
        return;
      }
      if (context.mounted) await _resolveConflict(context, ref);
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Не удалось сохранить: $error')),
      );
    }
  }

  /// Урок правили на другом устройстве: предлагаем открыть свежую версию.
  Future<void> _resolveConflict(BuildContext context, WidgetRef ref) async {
    final reload = await showDialog<bool>(
      context: context,
      builder: (context) => const VersionConflictDialog(),
    );
    if (reload != true) return;
    ref.invalidate(editLessonControllerProvider(lessonId));
  }
}

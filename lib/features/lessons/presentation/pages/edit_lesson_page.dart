import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/theme/theme.dart';

import '../../../../core/network/api_exception.dart';
import '../controllers/edit_lesson_controller.dart';
import '../widgets/edit_lesson_form.dart';
import '../widgets/lesson_editor_header.dart';
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
    final state = stateAsync.value;

    return Scaffold(
      backgroundColor: context.colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            LessonEditorHeader(
              title: 'Редактирование урока',
              onBack: () => Navigator.of(context).pop(),
              onCancel: () => Navigator.of(context).pop(),
              primaryLabel: 'Сохранить',
              onPrimary: (state?.canSave ?? false)
                  ? () => _save(context, ref)
                  : null,
              primaryLoading: state?.isSaving ?? false,
            ),
            Expanded(
              child: switch (stateAsync) {
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
            ),
          ],
        ),
      ),
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

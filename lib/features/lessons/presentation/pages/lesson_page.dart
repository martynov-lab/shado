import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../controllers/lesson_controller.dart';
import '../widgets/lesson_countdown_overlay.dart';
import '../widgets/lesson_mobile_layout.dart';
import '../widgets/lesson_wide_layout.dart';
import 'edit_lesson_page.dart';

class LessonPage extends ConsumerStatefulWidget {
  const LessonPage({super.key, required this.lessonId});

  /// Шаблон маршрута для роутера; путь к конкретному уроку — [routeTo].
  static const String routePath = '/lesson/:id';

  static String routeTo(String lessonId) => '/lesson/$lessonId';

  final String lessonId;

  @override
  ConsumerState<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends ConsumerState<LessonPage> {
  /// Фокус экрана: пока он здесь, работают стрелки и пробел.
  final _pageFocus = FocusNode(debugLabel: 'lesson-page');

  @override
  void dispose() {
    _pageFocus.dispose();
    super.dispose();
  }

  LessonController get _controller =>
      ref.read(lessonControllerProvider(widget.lessonId).notifier);

  /// Клавиатура для десктопа: стрелки ходят по кускам, Shift + стрелки
  /// набирают соседние куски, пробел играет и останавливает.
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final shift = HardwareKeyboard.instance.isShiftPressed;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        _controller.moveFocus(1, extend: shift);
      case LogicalKeyboardKey.arrowUp:
        _controller.moveFocus(-1, extend: shift);
      case LogicalKeyboardKey.space:
        // Повтор автоповтором клавиши здесь только мешает.
        if (event is KeyRepeatEvent) return KeyEventResult.handled;
        _controller.togglePlayFocused();
      case LogicalKeyboardKey.escape:
        // Escape отступает по одному шагу: сначала снимает выделение, потом
        // выходит из режима выбора. Нечего снимать — пусть достанется тому, кто
        // им пользуется.
        final state = ref.read(lessonControllerProvider(widget.lessonId)).value;
        if (state == null) return KeyEventResult.ignored;
        if (state.selection != null) {
          _controller.clearSelection();
        } else if (state.isSelecting) {
          _controller.stopSelecting();
        } else {
          return KeyEventResult.ignored;
        }
      case LogicalKeyboardKey.keyA:
        if (!HardwareKeyboard.instance.isControlPressed &&
            !HardwareKeyboard.instance.isMetaPressed) {
          return KeyEventResult.ignored;
        }
        _controller.selectAll();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  /// Возврат с экрана правки: разбивка могла измениться целиком, поэтому урок
  /// перечитывается, а плеер сбрасывается.
  Future<void> _edit() async {
    final saved = await context.push<bool>(
      EditLessonPage.routeTo(widget.lessonId),
    );
    if (saved != true) return;
    await _controller.reload();
    _pageFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(lessonControllerProvider(widget.lessonId));

    return Focus(
      focusNode: _pageFocus,
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: Scaffold(
        backgroundColor: context.colors.bg,
        body: switch (lessonAsync) {
          AsyncError(:final error) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s8),
              child: Text('$error', textAlign: TextAlign.center),
            ),
          ),
          AsyncData() => Stack(
            children: [
              AppAdaptiveLayout(
                mobile: (context) => LessonMobileLayout(
                  lessonId: widget.lessonId,
                  onBack: () => context.pop(),
                  onEdit: _edit,
                ),
                tablet: (context) => LessonWideLayout(
                  lessonId: widget.lessonId,
                  onBack: () => context.pop(),
                  onEdit: _edit,
                ),
              ),
              Positioned.fill(
                child: LessonCountdownOverlay(lessonId: widget.lessonId),
              ),
            ],
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

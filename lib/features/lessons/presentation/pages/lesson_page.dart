import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/lesson_controller.dart';
import '../widgets/lesson_view.dart';
import '../widgets/selection_bar.dart';
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
    final state = lessonAsync.value;

    return Focus(
      focusNode: _pageFocus,
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            state?.isSelecting == true
                ? 'Выбор кусков'
                : (state?.lesson.title ?? 'Урок'),
          ),
          actions: [
            if (state != null) ...[
              IconButton(
                tooltip: state.isSelecting
                    ? 'Выйти из режима выбора (Esc)'
                    : 'Выбрать несколько кусков',
                onPressed: state.isSelecting
                    ? _controller.stopSelecting
                    : _controller.startSelecting,
                isSelected: state.isSelecting,
                icon: const Icon(Icons.checklist_outlined),
                selectedIcon: const Icon(Icons.checklist),
              ),
              if (state.isSelecting)
                IconButton(
                  tooltip: state.selection == null
                      ? 'Выбрать все куски (Ctrl+A)'
                      : 'Снять выбор (Esc)',
                  onPressed: state.selection == null
                      ? _controller.selectAll
                      : _controller.clearSelection,
                  icon: Icon(
                    state.selection == null ? Icons.select_all : Icons.deselect,
                  ),
                ),
            ],
            IconButton(
              tooltip: 'Править разбивку',
              onPressed: state == null ? null : _edit,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        body: switch (lessonAsync) {
          AsyncError(:final error) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('$error', textAlign: TextAlign.center),
            ),
          ),
          AsyncData(:final value) => Column(
            children: [
              Expanded(
                child: LessonView(
                  state: value,
                  onSpeedChanged: _controller.setSpeed,
                  onPlayPressed: _controller.togglePlay,
                  onLoopPressed: _controller.toggleLoop,
                  onSelectPressed: _controller.toggleSelection,
                  onSegmentPressed: _controller.setFocus,
                ),
              ),
              if (value.selection case final selection?)
                SelectionBar(
                  selectedCount: selection.length,
                  durationMs: value.selectionDurationMs,
                  isPlaying: value.isSelectionPlaying,
                  isLooped: value.isSelectionLooped,
                  onPlayPressed: _controller.togglePlaySelection,
                  onLoopPressed: _controller.toggleSelectionLoop,
                  onClearPressed: _controller.clearSelection,
                ),
            ],
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

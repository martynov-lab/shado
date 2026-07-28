import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/duration_format.dart';
import '../controllers/lesson_controller.dart';
import '../widgets/segment_tile.dart';

class LessonPage extends ConsumerStatefulWidget {
  const LessonPage({super.key, required this.lessonId});

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
        // Нечего снимать — пусть Escape достанется тому, кто им пользуется.
        final selection = ref
            .read(lessonControllerProvider(widget.lessonId))
            .value
            ?.selection;
        if (selection == null) return KeyEventResult.ignored;
        _controller.clearSelection();
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
    final saved = await context.push<bool>('/lesson/${widget.lessonId}/edit');
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
          title: Text(state?.lesson.title ?? 'Урок'),
          actions: [
            if (state != null)
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
            IconButton(
              tooltip: 'Править разбивку',
              onPressed: state == null ? null : _edit,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        body: lessonAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('$error', textAlign: TextAlign.center),
            ),
          ),
          data: (state) => _LessonView(lessonId: widget.lessonId, state: state),
        ),
      ),
    );
  }
}

class _LessonView extends ConsumerStatefulWidget {
  const _LessonView({required this.lessonId, required this.state});

  final String lessonId;
  final LessonState state;

  @override
  ConsumerState<_LessonView> createState() => _LessonViewState();
}

class _LessonViewState extends ConsumerState<_LessonView> {
  /// Ключи плиток: по ним прокручиваем список к куску, на который перешли
  /// стрелкой.
  final _itemKeys = <int, GlobalKey>{};

  @override
  void didUpdateWidget(_LessonView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final index = widget.state.focusedIndex;
    if (index != null && index != oldWidget.state.focusedIndex) {
      _ensureVisible(index);
    }
  }

  void _ensureVisible(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _itemKeys[index]?.currentContext;
      // Плитки далеко за окном ещё не построены — там и прокручивать нечего:
      // стрелки ходят по одному куску, следующий всегда рядом.
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 150),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(
      lessonControllerProvider(widget.lessonId).notifier,
    );
    final state = widget.state;
    final segments = state.lesson.segments;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SegmentedButton<double>(
            segments: const [
              ButtonSegment(value: kSlowSpeed, label: Text('Медленно')),
              ButtonSegment(value: kNormalSpeed, label: Text('Нормально')),
            ],
            selected: {state.speed},
            onSelectionChanged: (selection) =>
                controller.setSpeed(selection.first),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: segments.length,
            itemBuilder: (context, index) {
              final segment = segments[index];
              return SegmentTile(
                key: _itemKeys[index] ??= GlobalKey(),
                segment: segment,
                isActive: state.isSegmentActive(index),
                isPlaying: state.isSegmentPlaying(index),
                isLooped: state.isSegmentLooped(index),
                isSelected: state.isSegmentSelected(index),
                isFocused: state.focusedIndex == index,
                onPlayPressed: () => controller.togglePlay(index),
                onLoopPressed: () => controller.toggleLoop(index),
                onSelectPressed: () => controller.toggleSelection(index),
                onPressed: () => controller.setFocus(index),
              );
            },
          ),
        ),
        if (state.selection != null)
          _SelectionBar(lessonId: widget.lessonId, state: state),
      ],
    );
  }
}

/// Панель выбранных кусков: играет их подряд или зацикливает отрезок целиком.
class _SelectionBar extends ConsumerWidget {
  const _SelectionBar({required this.lessonId, required this.state});

  final String lessonId;
  final LessonState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(lessonControllerProvider(lessonId).notifier);
    final theme = Theme.of(context);
    final count = state.selection!.length;
    final isPlaying = state.isSelectionPlaying;

    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$count ${_segmentsWord(count)} · '
                  '${formatPosition(state.selectionDurationMs)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              IconButton(
                tooltip: state.isSelectionLooped
                    ? 'Выключить повтор'
                    : 'Повторять выбранное',
                onPressed: controller.toggleSelectionLoop,
                isSelected: state.isSelectionLooped,
                icon: const Icon(Icons.repeat),
                selectedIcon: Icon(
                  Icons.repeat_on,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 4),
              FilledButton.icon(
                onPressed: controller.togglePlaySelection,
                icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
                label: Text(isPlaying ? 'Стоп' : 'Играть'),
              ),
              IconButton(
                tooltip: 'Снять выбор',
                onPressed: controller.clearSelection,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// «1 кусок», «2 куска», «5 кусков».
String _segmentsWord(int count) {
  if (count % 100 >= 11 && count % 100 <= 14) return 'кусков';
  switch (count % 10) {
    case 1:
      return 'кусок';
    case 2:
    case 3:
    case 4:
      return 'куска';
    default:
      return 'кусков';
  }
}

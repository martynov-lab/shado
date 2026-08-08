import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/edit_lesson_controller.dart';
import 'edit_lesson_waveform.dart';
import 'lesson_privacy_field.dart';
import 'lesson_section_card.dart';
import 'segment_splitter/marked_text_controller.dart';
import 'segment_splitter/segment_splitter_field.dart';

/// Тело экрана правки: название, разбивка текста и волна с границами.
class EditLessonForm extends ConsumerStatefulWidget {
  const EditLessonForm({
    super.key,
    required this.lessonId,
    required this.state,
  });

  final String lessonId;
  final EditLessonState state;

  @override
  ConsumerState<EditLessonForm> createState() => _EditLessonFormState();
}

class _EditLessonFormState extends ConsumerState<EditLessonForm> {
  late final _titleController = TextEditingController(text: widget.state.title);
  late final _textController = MarkedTextController(text: widget.state.text);

  /// Фокус самого экрана: пока он здесь, пробел работает как play/pause.
  final _pageFocus = FocusNode(debugLabel: 'edit-lesson-page');

  @override
  void didUpdateWidget(EditLessonForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Метку могли удалить с волны — тогда текст правит контроллер, и его нужно
    // вернуть в поле. При обычном вводе текст уже совпадает, синк — no-op.
    if (widget.state.text != _textController.text) {
      _textController.text = widget.state.text;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _pageFocus.dispose();
    super.dispose();
  }

  EditLessonController get _controller =>
      ref.read(editLessonControllerProvider(widget.lessonId).notifier);

  /// Пробел как play/pause — привычка из любого редактора аудио.
  ///
  /// Срабатывает только когда фокус на самом экране: в текстовом поле пробел
  /// остаётся пробелом, а на кнопке ▶ его обрабатывает сама кнопка.
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.space ||
        !node.hasPrimaryFocus) {
      return KeyEventResult.ignored;
    }
    _controller.togglePlay();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final controller = _controller;
    // Тумблер приватности видит только владелец: остальным авторам публичность
    // задаёт роль.
    final isOwner = ref.watch(authControllerProvider).isOwner;

    return Focus(
      focusNode: _pageFocus,
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.s5),
        children: [
          AppTextField(
            controller: _titleController,
            label: 'Название',
            onChanged: controller.setTitle,
            textInputAction: TextInputAction.next,
          ),
          if (isOwner) ...[
            const SizedBox(height: AppSpacing.s4),
            LessonPrivacyField(
              isPrivate: !state.isPublic,
              onChanged: controller.setPrivate,
            ),
          ],
          const SizedBox(height: AppSpacing.s5),
          LessonSectionCard(
            label: 'Аудио',
            note: '— границы сегментов',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Тронули волну — забираем фокус из текстового поля, иначе
                // пробел так и останется пробелом.
                Listener(
                  onPointerDown: (_) => _pageFocus.requestFocus(),
                  child: EditLessonWaveform(
                    lessonId: widget.lessonId,
                    state: state,
                    onPlayPressed: controller.togglePlay,
                    onSeek: controller.seek,
                    onBoundariesChanged: controller.setBoundaries,
                    onBoundaryRemoved: controller.removeMarker,
                    onTrimChanged: controller.updateTrim,
                    onTrimStart: controller.startTrim,
                    onTrimApply: controller.applyTrim,
                    onTrimCancel: controller.cancelTrim,
                  ),
                ),
                const SizedBox(height: AppSpacing.s3),
                Text(
                  _hint(state),
                  style: AppText.caption.copyWith(color: context.colors.text3),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s5),
          LessonSectionCard(
            label: 'Текст',
            note: '— разбей на сегменты',
            hint:
                'Нажмите «Метка» и кликните в тексте, куда поставить '
                'разделитель (или перетащите чип). Иглу можно перетащить или '
                'убрать тапом. На сервер уходит текст с «$kSegmentDelimiter».',
            child: SegmentSplitterField(
              controller: _textController,
              onChanged: controller.setText,
              onMarkerRemoved: controller.removeMarker,
              segmentCount: state.segmentCount,
            ),
          ),
        ],
      ),
    );
  }
}

/// Подсказка под волной: что сейчас можно сделать жестами и клавишами.
String _hint(EditLessonState state) {
  if (state.isTrimming) {
    return 'Тяните метки со стрелочками: затемнённые края отрежутся. '
        '«Применить» оставит только середину, «Отменить» вернёт как было. '
        'Пробел — послушать';
  }
  return 'Метки берутся за кружок сверху, ползунок — за треугольник снизу; '
      'перетаскивание в стороне от них двигает волну. Двойной тап по метке '
      'убирает её (и парную метку в тексте). Растянуть волну: щипок двумя '
      'пальцами или Ctrl + колесо мыши. Пробел — играть или пауза';
}

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

/// Editor screen body: title, text split and the waveform with boundaries.
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

  /// Focus of the screen itself; while it is here space acts as play/pause.
  final _pageFocus = FocusNode(debugLabel: 'edit-lesson-page');

  @override
  void didUpdateWidget(EditLessonForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Text edited by the controller is pushed back into the field.
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

  /// Places the paired boundary of a new marker under the playhead.
  void _insertMarker(String text, int ordinal) {
    final state = widget.state;
    final position = ref
        .read(editPlaybackPositionProvider(widget.lessonId))
        .value;
    final playheadMs = state.isPlaying
        ? (position?.inMilliseconds ?? state.playheadMs)
        : state.playheadMs;
    _controller.insertMarker(text, ordinal, playheadMs);
  }

  /// Space acts as play/pause while the screen itself holds focus.
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
    // The privacy switch is owner-only.
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
                // Touching the waveform takes focus off the text field.
                Listener(
                  onPointerDown: (_) => _pageFocus.requestFocus(),
                  child: EditLessonWaveform(
                    lessonId: widget.lessonId,
                    state: state,
                    onPlayPressed: controller.togglePlay,
                    onSeek: controller.seek,
                    onBoundariesChanged: controller.setBoundaries,
                    onBoundaryRemoved: controller.removeMarker,
                    onMarkerAtPlayheadChanged: controller.setMarkerAtPlayhead,
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
                'Нажмите «Метка» и кликните в тексте, куда поставить разделитель '
                '(или перетащите чип) — граница на волне встанет правее самой '
                'правой. Включённая «Метка по ползунку» сажает её в позицию '
                'ползунка. Иглу можно перетащить или убрать тапом. На сервер '
                'уходит текст с «$kSegmentDelimiter».',
            child: SegmentSplitterField(
              controller: _textController,
              onChanged: controller.setText,
              onMarkerInserted: _insertMarker,
              onMarkerRemoved: controller.removeMarker,
              segmentCount: state.segmentCount,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hint under the waveform about available gestures and keys.
String _hint(EditLessonState state) {
  if (state.isTrimming) {
    return 'Тяните метки со стрелочками: затемнённые края отрежутся. '
        '«Применить» оставит только середину, «Отменить» вернёт как было. '
        'Пробел — послушать';
  }
  return 'Метка в тексте добавляет границу правее самой правой. Чтобы вставить '
      'границу внутрь уже размеченного урока, включите «Метка по ползунку»: '
      'доведите плеер до нужного места, поставьте на паузу и добавьте метку в '
      'тексте — граница встанет в позицию ползунка, а метки правее останутся на '
      'местах. Метки берутся за кружок сверху, ползунок — за треугольник '
      'снизу; перетаскивание в стороне от них двигает волну. Двойной тап по '
      'метке убирает её (и парную метку в тексте). Растянуть волну: щипок двумя '
      'пальцами или Ctrl + колесо мыши. Пробел — играть или пауза';
}

import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/audio_trim.dart';
import '../screens/edit_lesson/edit_lesson_state.dart';
import 'edit_lesson_waveform.dart';
import 'lesson_privacy_field.dart';
import 'lesson_section_card.dart';
import 'segment_splitter/marked_text_controller.dart';
import 'segment_splitter/segment_splitter_field.dart';

/// Editor screen body: title, text split and the waveform with boundaries.
class EditLessonForm extends StatelessWidget {
  const EditLessonForm({
    super.key,
    required this.state,
    required this.playheadMs,
    required this.isOwner,
    required this.titleController,
    required this.textController,
    required this.onTitleChanged,
    required this.onPrivateChanged,
    required this.onTextChanged,
    required this.onMarkerInserted,
    required this.onMarkerRemoved,
    required this.onWaveformTouched,
    required this.onPlayPressed,
    required this.onSeek,
    required this.onBoundariesChanged,
    required this.onMarkerAtPlayheadChanged,
    required this.onTrimChanged,
    required this.onTrimStart,
    required this.onTrimApply,
    required this.onTrimCancel,
  });

  final EditLessonState state;

  /// Playhead in file milliseconds.
  final int playheadMs;

  /// Only the owner gets the privacy switch.
  final bool isOwner;

  final TextEditingController titleController;
  final MarkedTextController textController;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<bool> onPrivateChanged;
  final ValueChanged<String> onTextChanged;
  final void Function(String text, int ordinal) onMarkerInserted;
  final ValueChanged<int> onMarkerRemoved;

  /// Touching the waveform takes the focus off the text field.
  final VoidCallback onWaveformTouched;

  final VoidCallback onPlayPressed;
  final ValueChanged<int> onSeek;
  final ValueChanged<List<int>> onBoundariesChanged;
  final ValueChanged<bool> onMarkerAtPlayheadChanged;
  final ValueChanged<AudioTrim> onTrimChanged;
  final VoidCallback onTrimStart;
  final VoidCallback onTrimApply;
  final VoidCallback onTrimCancel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s5),
      children: [
        AppTextField(
          controller: titleController,
          label: 'Title',
          onChanged: onTitleChanged,
          textInputAction: TextInputAction.next,
        ),
        if (isOwner) ...[
          const SizedBox(height: AppSpacing.s4),
          LessonPrivacyField(
            isPrivate: !state.isPublic,
            onChanged: onPrivateChanged,
          ),
        ],
        const SizedBox(height: AppSpacing.s5),
        LessonSectionCard(
          label: 'Audio',
          note: '— segment boundaries',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Listener(
                onPointerDown: (_) => onWaveformTouched(),
                child: EditLessonWaveform(
                  state: state,
                  playheadMs: playheadMs,
                  onPlayPressed: onPlayPressed,
                  onSeek: onSeek,
                  onBoundariesChanged: onBoundariesChanged,
                  onBoundaryRemoved: onMarkerRemoved,
                  onMarkerAtPlayheadChanged: onMarkerAtPlayheadChanged,
                  onTrimChanged: onTrimChanged,
                  onTrimStart: onTrimStart,
                  onTrimApply: onTrimApply,
                  onTrimCancel: onTrimCancel,
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
          label: 'Text',
          note: '— split into segments',
          hint:
              'Press "Marker" and click in the text where the delimiter goes '
              '(or drag the chip) — the waveform boundary lands right of the '
              'rightmost one. With "Marker at playhead" on, it lands at the '
              'playhead. A needle can be dragged or removed with a tap. The server '
              'receives text with "$kSegmentDelimiter".',
          child: SegmentSplitterField(
            controller: textController,
            onChanged: onTextChanged,
            onMarkerInserted: onMarkerInserted,
            onMarkerRemoved: onMarkerRemoved,
            segmentCount: state.segmentCount,
          ),
        ),
      ],
    );
  }
}

/// Hint under the waveform about available gestures and keys.
String _hint(EditLessonState state) {
  if (state.isTrimming) {
    return 'Drag the arrow markers: the dimmed edges will be cut off. '
        '"Apply" keeps only the middle, "Cancel" restores it as it was. '
        'Space — listen';
  }
  return 'A marker in the text adds a boundary right of the rightmost one. To insert '
      'a boundary inside an already marked-up lesson, turn on "Marker at playhead": '
      'play up to the right spot, pause and add a marker in the '
      'text — the boundary lands at the playhead, and markers to the right stay in '
      'place. Grab markers by the circle on top, the playhead by the triangle '
      'below; dragging elsewhere moves the waveform. A double tap on a '
      'marker removes it (and its paired marker in the text). Zoom the waveform: pinch with two '
      'fingers or Ctrl + mouse wheel. Space — play or pause';
}

import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// A phrase row of the editor: the phrase, its translation, the voice-over
/// status and actions. Keeps its own text controllers and takes outside
/// changes (a filled-in translation) while the field is not being edited.
class PhraseDraftRow extends StatefulWidget {
  const PhraseDraftRow({
    super.key,
    required this.index,
    required this.text,
    required this.translation,
    required this.translationHint,
    required this.hasAudio,
    required this.needsVoice,
    required this.isPlaying,
    required this.isBusy,
    required this.onTextChanged,
    required this.onTranslationChanged,
    required this.onTogglePlay,
    required this.onVoice,
    required this.onRemove,
  });

  /// Position in the list, for the drag handle.
  final int index;
  final String text;
  final String translation;

  /// Hint of the translation field, with the language name.
  final String translationHint;

  final bool hasAudio;

  /// The phrase has no audio or its text changed after voicing.
  final bool needsVoice;
  final bool isPlaying;

  /// A voice-over, translation or save is running.
  final bool isBusy;

  final ValueChanged<String> onTextChanged;
  final ValueChanged<String> onTranslationChanged;
  final VoidCallback onTogglePlay;
  final VoidCallback onVoice;
  final VoidCallback onRemove;

  @override
  State<PhraseDraftRow> createState() => _PhraseDraftRowState();
}

class _PhraseDraftRowState extends State<PhraseDraftRow> {
  late final TextEditingController _text = TextEditingController(
    text: widget.text,
  );
  late final TextEditingController _translation = TextEditingController(
    text: widget.translation,
  );
  final FocusNode _textFocus = FocusNode();
  final FocusNode _translationFocus = FocusNode();

  @override
  void didUpdateWidget(PhraseDraftRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_textFocus.hasFocus && _text.text != widget.text) {
      _text.text = widget.text;
    }
    if (!_translationFocus.hasFocus &&
        _translation.text != widget.translation) {
      _translation.text = widget.translation;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _translation.dispose();
    _textFocus.dispose();
    _translationFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReorderableDragStartListener(
            index: widget.index,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s3),
              child: Icon(
                Icons.drag_indicator_rounded,
                color: colors.text3,
                semanticLabel: 'Drag to reorder',
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The phrase and its translation read as one card: flat
                // inner corners and a shared border line.
                AppTextField(
                  controller: _text,
                  focusNode: _textFocus,
                  hint: 'Phrase',
                  maxLines: 3,
                  minLines: 1,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadii.md),
                  ),
                  onChanged: widget.onTextChanged,
                ),
                Transform.translate(
                  offset: const Offset(0, -AppSizes.borderThin),
                  child: AppTextField(
                    controller: _translation,
                    focusNode: _translationFocus,
                    hint: widget.translationHint,
                    maxLines: 3,
                    minLines: 1,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(AppRadii.md),
                    ),
                    // The translation is secondary to the phrase: muted
                    // and a size smaller.
                    textStyle: AppText.body.copyWith(
                      fontSize: 14,
                      color: colors.text2,
                    ),
                    onChanged: widget.onTranslationChanged,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          Column(
            children: [
              if (widget.needsVoice)
                AppIconButton(
                  icon: Icons.record_voice_over_outlined,
                  semanticLabel: 'Voice this phrase',
                  variant: AppButtonVariant.secondary,
                  onPressed: widget.isBusy ? null : widget.onVoice,
                )
              else if (widget.hasAudio)
                AppIconButton(
                  icon: widget.isPlaying
                      ? Icons.stop_rounded
                      : Icons.play_arrow_rounded,
                  semanticLabel: widget.isPlaying ? 'Stop' : 'Play',
                  onPressed: widget.onTogglePlay,
                ),
              AppIconButton(
                icon: Icons.delete_outline_rounded,
                semanticLabel: 'Remove phrase',
                onPressed: widget.isBusy ? null : widget.onRemove,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

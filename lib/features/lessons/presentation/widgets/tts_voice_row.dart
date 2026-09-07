import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import 'tts_voice_play_button.dart';

/// A voice of the voice-over sheet: name, characteristic and a listen button.
class TtsVoiceRow extends StatelessWidget {
  const TtsVoiceRow({
    super.key,
    required this.name,
    required this.description,
    required this.selected,
    required this.isLoading,
    required this.isPlaying,
    required this.onSelect,
    required this.onPlay,
  });

  final String name;
  final String description;

  /// The voice the synthesis will use.
  final bool selected;

  /// The sample is being fetched from the server.
  final bool isLoading;

  final bool isPlaying;
  final VoidCallback onSelect;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onSelect,
          borderRadius: AppRadii.rMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s3,
              vertical: AppSpacing.s3,
            ),
            child: Row(
              children: [
                TtsVoicePlayButton(
                  isLoading: isLoading,
                  isPlaying: isPlaying,
                  onTap: onPlay,
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: AppText.body.copyWith(
                          color: selected ? colors.primary : colors.text,
                        ),
                      ),
                      if (description.isNotEmpty)
                        Text(
                          description,
                          style: AppText.caption.copyWith(color: colors.text3),
                        ),
                    ],
                  ),
                ),
                if (selected)
                  AppIcon(
                    AppIcons.check,
                    size: AppSizes.iconMd,
                    color: colors.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

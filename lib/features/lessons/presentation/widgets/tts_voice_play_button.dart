import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Listen button of a voice sample.
class TtsVoicePlayButton extends StatelessWidget {
  const TtsVoicePlayButton({
    super.key,
    required this.isLoading,
    required this.isPlaying,
    required this.onTap,
  });

  /// The sample is being fetched from the server.
  final bool isLoading;

  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      label: isPlaying ? 'Остановить' : 'Прослушать',
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: AppRadii.rPill,
          child: Container(
            width: AppSizes.controlSm,
            height: AppSizes.controlSm,
            decoration: BoxDecoration(
              color: colors.primarySoft,
              borderRadius: AppRadii.rPill,
            ),
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.s3),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : AppIcon(
                    isPlaying ? AppIcons.pause : AppIcons.play,
                    size: AppSizes.iconMd,
                    color: colors.primary,
                  ),
          ),
        ),
      ),
    );
  }
}

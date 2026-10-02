import 'package:flutter/material.dart';

import 'package:shado/core/constants/app_constants.dart';
import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../../core/utils/duration_format.dart';
import '../screens/lesson/lesson_state.dart';
import 'lesson_gradients.dart';
import 'lesson_labels.dart';
import 'lesson_player_tag.dart';
import 'lesson_speed_chip.dart';
import 'lesson_transport_button.dart';

/// Dark player panel: segment, waveform, timing and transport buttons.
class LessonPlayerPanel extends StatelessWidget {
  const LessonPlayerPanel({
    super.key,
    required this.state,
    required this.waveform,
    required this.onPrevious,
    required this.onTogglePlay,
    required this.onNext,
    required this.onPickSpeed,
    required this.onToggleLoop,
  });

  final LessonState state;
  final Widget waveform;
  final VoidCallback onPrevious;
  final VoidCallback onTogglePlay;
  final VoidCallback onNext;
  final VoidCallback onPickSpeed;
  final VoidCallback onToggleLoop;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final fg = lessonPlayerForeground;
    final range = state.playerRange;
    // One segment gets a singular caption, a range gets a plural one.
    final rangeLabel = range.isSingle
        ? 'Segment ${segmentNumber(range.start)}'
        : 'Segments ${segmentNumber(range.start)}–${segmentNumber(range.end)}';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s6),
      decoration: BoxDecoration(
        gradient: lessonPlayerGradient(),
        borderRadius: AppRadii.rXxl,
        boxShadow: context.shadows.e3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$rangeLabel · '
                  '${rangeTimecodes(state.playerStartMs, state.playerEndMs)}',
                  style: AppText.label.copyWith(
                    color: fg.withValues(alpha: 0.85),
                  ),
                ),
              ),
              LessonPlayerTag(label: 'SHADOWING', foreground: fg),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          waveform,
          const SizedBox(height: AppSpacing.s2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatPosition(state.playerStartMs),
                style: AppText.monoTime.copyWith(
                  color: fg.withValues(alpha: 0.6),
                ),
              ),
              Text(
                formatPosition(state.playerEndMs),
                style: AppText.monoTime.copyWith(
                  color: fg.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s5),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.s2,
            runSpacing: AppSpacing.s2,
            children: [
              LessonTransportButton(
                icon: AppIcons.prev,
                semanticLabel: 'Previous segment',
                background: fg.withValues(alpha: 0.08),
                foreground: fg,
                onTap: state.canGoPrevious ? onPrevious : null,
              ),
              LessonTransportButton(
                icon: state.isPlayerPlaying ? AppIcons.pause : AppIcons.play,
                semanticLabel: state.isPlayerPlaying ? 'Stop' : 'Play',
                background: colors.primary,
                foreground: colors.primaryOn,
                size: AppSizes.controlLg,
                onTap: onTogglePlay,
              ),
              LessonTransportButton(
                icon: AppIcons.next,
                semanticLabel: 'Next segment',
                background: fg.withValues(alpha: 0.08),
                foreground: fg,
                onTap: state.canGoNext ? onNext : null,
              ),
              LessonSpeedChip(
                label: speedLabel(state.speed),
                foreground: fg,
                onTap: onPickSpeed,
              ),
              LessonTransportButton(
                icon: AppIcons.loop,
                semanticLabel: state.isLooped
                    ? 'Turn off repeat'
                    : 'Repeat',
                background: state.isLooped
                    ? colors.primary.withValues(alpha: 0.35)
                    : fg.withValues(alpha: 0.08),
                foreground: fg,
                onTap: onToggleLoop,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

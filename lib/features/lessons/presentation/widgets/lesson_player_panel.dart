import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/core/constants/app_constants.dart';
import 'package:shado/features/settings/presentation/widgets/playback_speed_sheet.dart';
import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../../core/utils/duration_format.dart';
import '../controllers/lesson_controller.dart';
import 'lesson_gradients.dart';
import 'lesson_labels.dart';
import 'lesson_player_waveform.dart';

/// Тёмная панель плеера: текущий сегмент, волна, тайминг и транспорт
/// (назад / играть / вперёд, скорость, повтор).
///
/// Фон — «обратная» поверхность [AppColors.surfaceInv], текст и кнопки на ней —
/// [AppColors.textInv], поэтому панель контрастно выделяется в обеих темах.
class LessonPlayerPanel extends ConsumerWidget {
  const LessonPlayerPanel({super.key, required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(lessonControllerProvider(lessonId)).value;
    if (state == null) return const SizedBox.shrink();
    final controller = ref.read(lessonControllerProvider(lessonId).notifier);

    final fg = lessonPlayerForeground;
    final range = state.playerRange;
    // Для одного куска — «Сегмент 03», для отрезка — «Сегменты 03–05».
    final rangeLabel = range.isSingle
        ? 'Сегмент ${segmentNumber(range.start)}'
        : 'Сегменты ${segmentNumber(range.start)}–${segmentNumber(range.end)}';

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
              _Tag(label: 'SHADOWING', foreground: fg),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          LessonPlayerWaveform(lessonId: lessonId, color: fg),
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
              _TransportButton(
                icon: AppIcons.prev,
                semanticLabel: 'Предыдущий сегмент',
                background: fg.withValues(alpha: 0.08),
                foreground: fg,
                onTap: state.canGoPrevious ? controller.previous : null,
              ),
              _TransportButton(
                icon: state.isPlayerPlaying ? AppIcons.pause : AppIcons.play,
                semanticLabel: state.isPlayerPlaying ? 'Стоп' : 'Играть',
                background: colors.primary,
                foreground: colors.primaryOn,
                size: AppSizes.controlLg,
                onTap: controller.togglePlayCurrent,
              ),
              _TransportButton(
                icon: AppIcons.next,
                semanticLabel: 'Следующий сегмент',
                background: fg.withValues(alpha: 0.08),
                foreground: fg,
                onTap: state.canGoNext ? controller.next : null,
              ),
              _SpeedChip(
                label: speedLabel(state.speed),
                foreground: fg,
                onTap: () => _pickSpeed(context, ref, state.speed),
              ),
              _TransportButton(
                icon: AppIcons.loop,
                semanticLabel: state.isLooped
                    ? 'Выключить повтор'
                    : 'Повторять',
                background: state.isLooped
                    ? colors.primary.withValues(alpha: 0.35)
                    : fg.withValues(alpha: 0.08),
                foreground: fg,
                onTap: controller.toggleLoop,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Открывает тот же список скоростей, что и в настройках, и применяет выбор к
  /// текущему уроку. Скорость здесь действует на сессию (в отличие от скорости
  /// по умолчанию из настроек), поэтому идёт через контроллер урока, а не в prefs.
  Future<void> _pickSpeed(
    BuildContext context,
    WidgetRef ref,
    double current,
  ) async {
    final selected = await showAppBottomSheet<double>(
      context: context,
      title: 'Скорость воспроизведения',
      builder: (_) => PlaybackSpeedSheet(current: current),
    );
    if (selected == null) return;
    await ref
        .read(lessonControllerProvider(lessonId).notifier)
        .setSpeed(selected);
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.foreground});

  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.14),
        borderRadius: AppRadii.rPill,
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(color: foreground, letterSpacing: 0.6),
      ),
    );
  }
}

class _TransportButton extends StatelessWidget {
  const _TransportButton({
    required this.icon,
    required this.semanticLabel,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.size = AppSizes.controlMd,
  });

  final AppIcons icon;
  final String semanticLabel;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      excludeSemantics: true,
      child: Tooltip(
        message: semanticLabel,
        child: Opacity(
          opacity: enabled ? 1 : AppOpacities.disabled,
          child: Material(
            color: background,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: SizedBox.square(
                dimension: size,
                child: Center(
                  child: AppIcon(
                    icon,
                    size: AppSizes.iconMd,
                    color: foreground,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeedChip extends StatelessWidget {
  const _SpeedChip({
    required this.label,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Скорость $label',
      excludeSemantics: true,
      child: Material(
        color: foreground.withValues(alpha: 0.08),
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: AppSpacing.s3,
            ),
            child: Text(
              label,
              style: AppText.monoTime.copyWith(color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}

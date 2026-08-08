import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../progress/presentation/controllers/progress_providers.dart';
import '../controllers/home_lesson_tile.dart';

/// «Герой» главного экрана — карточка «Продолжить»: градиент, название урока,
/// подзаголовок, эквалайзер, полоса пройденности и кнопка воспроизведения.
///
/// Показывает последний урок, с которым работал пользователь; долю пройденности
/// берёт из [lessonProgressProvider]. Пока продолжать нечего ([lesson] == null)
/// — приглашает выбрать урок.
class ContinueHeroCard extends ConsumerWidget {
  const ContinueHeroCard({super.key, required this.lesson, required this.onOpen});

  /// Последний урок пользователя; `null` — ещё ни одного.
  final HomeLessonTile? lesson;

  /// Открыть урок (или список уроков, если продолжать нечего).
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onGrad = context.colors.primaryOn;
    final tile = lesson;
    final progress = tile == null
        ? 0.0
        : ref
                  .watch(
                    lessonProgressProvider((
                      lessonId: tile.id,
                      segmentCount: tile.segmentCount,
                    )),
                  )
                  .value ??
              0.0;
    final title = tile?.title ?? 'Начните первый урок';
    final subtitle = tile?.subtitle ?? 'Выберите урок из каталога';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s5),
      decoration: BoxDecoration(
        gradient: AppBrand.signGradient,
        borderRadius: AppRadii.rXl,
        boxShadow: context.shadows.e2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Продолжить'.toUpperCase(),
            style: AppText.caption.copyWith(
              color: onGrad.withValues(alpha: 0.85),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            title,
            style: AppText.h2.copyWith(color: onGrad),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(
            subtitle,
            style: AppText.label.copyWith(
              color: onGrad.withValues(alpha: 0.85),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.s4),
          const _HeroWave(),
          const SizedBox(height: AppSpacing.s4),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: AppRadii.rPill,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: onGrad.withValues(alpha: 0.25),
                    valueColor: AlwaysStoppedAnimation<Color>(onGrad),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              _PlayButton(onTap: onOpen),
            ],
          ),
        ],
      ),
    );
  }
}

/// Круглая кнопка воспроизведения на «герое»: белый круг с primary-стрелкой.
class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onTap});

  final VoidCallback onTap;

  static const double _size = 48;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      label: 'Продолжить урок',
      excludeSemantics: true,
      child: Material(
        color: colors.primaryOn,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: _size,
            height: _size,
            child: Center(
              child: AppIcon(
                AppIcons.play,
                size: AppSizes.iconLg,
                color: colors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Декоративный эквалайзер на «герое»: полоски, у которых начало «пройдено».
/// Это украшение, а не данные, — форма считается по индексу полоски.
class _HeroWave extends StatelessWidget {
  const _HeroWave();

  static const double _barWidth = 3;
  static const double _barGap = 2;
  static const double _playedFraction = 0.4;
  static const double _minBarFraction = 0.28;

  @override
  Widget build(BuildContext context) {
    final onGrad = context.colors.primaryOn;

    return SizedBox(
      height: 26,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count =
              ((constraints.maxWidth + _barGap) / (_barWidth + _barGap))
                  .floor();
          final played = (count * _playedFraction).round();

          return Row(
            spacing: _barGap,
            children: [
              for (var i = 0; i < count; i++)
                SizedBox(
                  width: _barWidth,
                  height: constraints.maxHeight * _barHeightFraction(i),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: AppRadii.rPill,
                      color: i <= played
                          ? onGrad
                          : onGrad.withValues(alpha: 0.35),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  double _barHeightFraction(int index) {
    final shape = (math.sin(index * 0.7) * math.cos(index * 0.3)).abs();
    return _minBarFraction + shape * (1 - _minBarFraction);
  }
}

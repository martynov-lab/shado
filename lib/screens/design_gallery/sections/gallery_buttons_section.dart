import 'package:flutter/material.dart';

import 'package:shado/screens/design_gallery/widgets/gallery_label.dart';
import 'package:shado/screens/design_gallery/widgets/gallery_section.dart';
import 'package:shado/screens/design_gallery/widgets/gallery_wrap.dart';
import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Gallery section: buttons in every variant, size and state.
class GalleryButtonsSection extends StatefulWidget {
  const GalleryButtonsSection({super.key});

  @override
  State<GalleryButtonsSection> createState() => _GalleryButtonsSectionState();
}

class _GalleryButtonsSectionState extends State<GalleryButtonsSection> {
  bool _loading = false;

  /// Shows the loading spinner on the button.
  void _fakeLoad() {
    setState(() => _loading = true);
    Future.delayed(AppDurations.slow * 4, () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) => GallerySection(
    title: 'Кнопки',
    caption: 'Варианты, размеры, загрузка и выключенное состояние',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GalleryLabel('Варианты'),
        GalleryWrap(
          children: [
            AppButton(
              label: 'Слушать',
              icon: Icons.play_arrow_rounded,
              onPressed: () {},
            ),
            AppButton(
              label: 'Повторить',
              variant: AppButtonVariant.secondary,
              icon: Icons.replay_rounded,
              onPressed: () {},
            ),
            AppButton(
              label: 'Отмена',
              variant: AppButtonVariant.ghost,
              onPressed: () {},
            ),
          ],
        ),
        const GalleryLabel('Размеры'),
        GalleryWrap(
          children: [
            AppButton(label: 'Small', size: AppButtonSize.sm, onPressed: () {}),
            AppButton(label: 'Medium', onPressed: () {}),
            AppButton(label: 'Large', size: AppButtonSize.lg, onPressed: () {}),
          ],
        ),
        const GalleryLabel('Состояния'),
        GalleryWrap(
          children: [
            AppButton(
              label: _loading ? 'Загружаю' : 'Запустить загрузку',
              loading: _loading,
              onPressed: _fakeLoad,
            ),
            const AppButton(label: 'Выключена'),
            const AppButton(
              label: 'Выключена',
              variant: AppButtonVariant.secondary,
            ),
            const AppButton(
              label: 'Выключена',
              variant: AppButtonVariant.ghost,
            ),
          ],
        ),
        const GalleryLabel('Во всю ширину'),
        AppButton(
          label: 'Начать урок',
          icon: Icons.headphones_rounded,
          size: AppButtonSize.lg,
          expand: true,
          onPressed: () {},
        ),
        const GalleryLabel('Иконочные — круглые и квадратные'),
        GalleryWrap(
          children: [
            AppIconButton(
              icon: Icons.play_arrow_rounded,
              semanticLabel: 'Воспроизвести',
              variant: AppButtonVariant.primary,
              size: AppButtonSize.lg,
              onPressed: () {},
            ),
            AppIconButton(
              icon: Icons.pause_rounded,
              semanticLabel: 'Пауза',
              variant: AppButtonVariant.secondary,
              onPressed: () {},
            ),
            AppIconButton(
              icon: Icons.mic_rounded,
              semanticLabel: 'Записать',
              onPressed: () {},
            ),
            AppIconButton(
              icon: Icons.cut_rounded,
              semanticLabel: 'Обрезать',
              shape: AppIconButtonShape.square,
              variant: AppButtonVariant.secondary,
              onPressed: () {},
            ),
            AppIconButton(
              icon: Icons.tune_rounded,
              semanticLabel: 'Настройки',
              shape: AppIconButtonShape.square,
              size: AppButtonSize.sm,
              onPressed: () {},
            ),
            const AppIconButton(
              icon: Icons.delete_outline_rounded,
              semanticLabel: 'Удалить',
              shape: AppIconButtonShape.square,
            ),
          ],
        ),
      ],
    ),
  );
}

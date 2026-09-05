import 'package:flutter/material.dart';

import 'package:shado/screens/design_gallery/gallery_speed.dart';
import 'package:shado/screens/design_gallery/widgets/gallery_label.dart';
import 'package:shado/screens/design_gallery/widgets/gallery_section.dart';
import 'package:shado/screens/design_gallery/widgets/gallery_speed_sheet.dart';
import 'package:shado/screens/design_gallery/widgets/gallery_wrap.dart';
import 'package:shado/widgets/widgets.dart';

/// Gallery section: modal sheet and snackbars.
class GalleryOverlaysSection extends StatefulWidget {
  const GalleryOverlaysSection({super.key});

  @override
  State<GalleryOverlaysSection> createState() => _GalleryOverlaysSectionState();
}

class _GalleryOverlaysSectionState extends State<GalleryOverlaysSection> {
  GallerySpeed _speed = GallerySpeed.normal;

  Future<void> _showSheet() => showAppBottomSheet<void>(
    context: context,
    title: 'Скорость воспроизведения',
    builder: (context) => GallerySpeedSheet(
      initialSpeed: _speed,
      onSpeedChanged: (speed) => setState(() => _speed = speed),
    ),
  );

  @override
  Widget build(BuildContext context) => GallerySection(
    title: 'Оверлеи',
    caption: 'Модальный лист и всплывающие сообщения',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GalleryWrap(
          children: [
            AppButton(
              label: 'Модальный лист',
              icon: Icons.vertical_align_bottom_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: _showSheet,
            ),
          ],
        ),
        const GalleryLabel('Сообщения'),
        GalleryWrap(
          children: [
            AppButton(
              label: 'Обычное',
              size: AppButtonSize.sm,
              variant: AppButtonVariant.ghost,
              onPressed: () => showAppSnackbar(
                context,
                message: 'Черновик сохранён',
                actionLabel: 'Открыть',
                onAction: () {},
              ),
            ),
            AppButton(
              label: 'Успех',
              size: AppButtonSize.sm,
              variant: AppButtonVariant.ghost,
              onPressed: () => showAppSnackbar(
                context,
                message: 'Урок сохранён',
                variant: AppSnackbarVariant.success,
              ),
            ),
            AppButton(
              label: 'Внимание',
              size: AppButtonSize.sm,
              variant: AppButtonVariant.ghost,
              onPressed: () => showAppSnackbar(
                context,
                message: 'Микрофон занят другим приложением',
                variant: AppSnackbarVariant.warning,
              ),
            ),
            AppButton(
              label: 'Ошибка',
              size: AppButtonSize.sm,
              variant: AppButtonVariant.ghost,
              onPressed: () => showAppSnackbar(
                context,
                message: 'Не удалось прочитать аудиофайл',
                variant: AppSnackbarVariant.danger,
                actionLabel: 'Ещё раз',
                onAction: () {},
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

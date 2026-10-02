import 'dart:async';

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
    title: 'Playback speed',
    builder: (context) => GallerySpeedSheet(
      initialSpeed: _speed,
      onSpeedChanged: (speed) => setState(() => _speed = speed),
    ),
  );

  @override
  Widget build(BuildContext context) => GallerySection(
    title: 'Overlays',
    caption: 'Modal sheet and toast messages',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GalleryWrap(
          children: [
            AppButton(
              label: 'Modal sheet',
              icon: Icons.vertical_align_bottom_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: () => unawaited(_showSheet()),
            ),
          ],
        ),
        const GalleryLabel('Messages'),
        GalleryWrap(
          children: [
            AppButton(
              label: 'Regular',
              size: AppButtonSize.sm,
              variant: AppButtonVariant.ghost,
              onPressed: () => showAppSnackbar(
                context,
                message: 'Draft saved',
                actionLabel: 'Open',
                // TODO: demo controls have no actions yet.
                // ignore: no-empty-block
                onAction: () {},
              ),
            ),
            AppButton(
              label: 'Success',
              size: AppButtonSize.sm,
              variant: AppButtonVariant.ghost,
              onPressed: () => showAppSnackbar(
                context,
                message: 'Lesson saved',
                variant: AppSnackbarVariant.success,
              ),
            ),
            AppButton(
              label: 'Warning',
              size: AppButtonSize.sm,
              variant: AppButtonVariant.ghost,
              onPressed: () => showAppSnackbar(
                context,
                message: 'The microphone is busy with another app',
                variant: AppSnackbarVariant.warning,
              ),
            ),
            AppButton(
              label: 'Error',
              size: AppButtonSize.sm,
              variant: AppButtonVariant.ghost,
              onPressed: () => showAppSnackbar(
                context,
                message: 'Failed to read the audio file',
                variant: AppSnackbarVariant.danger,
                actionLabel: 'Try again',
                // TODO: demo controls have no actions yet.
                // ignore: no-empty-block
                onAction: () {},
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

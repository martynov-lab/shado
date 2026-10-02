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
    title: 'Buttons',
    caption: 'Variants, sizes, loading and disabled state',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GalleryLabel('Variants'),
        GalleryWrap(
          children: [
            AppButton(
              label: 'Listen',
              icon: Icons.play_arrow_rounded,
              onPressed: () {},
            ),
            AppButton(
              label: 'Repeat',
              variant: AppButtonVariant.secondary,
              icon: Icons.replay_rounded,
              onPressed: () {},
            ),
            AppButton(
              label: 'Cancel',
              variant: AppButtonVariant.ghost,
              onPressed: () {},
            ),
          ],
        ),
        const GalleryLabel('Sizes'),
        GalleryWrap(
          children: [
            AppButton(label: 'Small', size: AppButtonSize.sm, onPressed: () {}),
            AppButton(label: 'Medium', onPressed: () {}),
            AppButton(label: 'Large', size: AppButtonSize.lg, onPressed: () {}),
          ],
        ),
        const GalleryLabel('States'),
        GalleryWrap(
          children: [
            AppButton(
              label: _loading ? 'Loading' : 'Start loading',
              loading: _loading,
              onPressed: _fakeLoad,
            ),
            const AppButton(label: 'Disabled'),
            const AppButton(
              label: 'Disabled',
              variant: AppButtonVariant.secondary,
            ),
            const AppButton(
              label: 'Disabled',
              variant: AppButtonVariant.ghost,
            ),
          ],
        ),
        const GalleryLabel('Full width'),
        AppButton(
          label: 'Start lesson',
          icon: Icons.headphones_rounded,
          size: AppButtonSize.lg,
          expand: true,
          onPressed: () {},
        ),
        const GalleryLabel('Icon buttons — round and square'),
        GalleryWrap(
          children: [
            AppIconButton(
              icon: Icons.play_arrow_rounded,
              semanticLabel: 'Play',
              variant: AppButtonVariant.primary,
              size: AppButtonSize.lg,
              onPressed: () {},
            ),
            AppIconButton(
              icon: Icons.pause_rounded,
              semanticLabel: 'Pause',
              variant: AppButtonVariant.secondary,
              onPressed: () {},
            ),
            AppIconButton(
              icon: Icons.mic_rounded,
              semanticLabel: 'Record',
              onPressed: () {},
            ),
            AppIconButton(
              icon: Icons.cut_rounded,
              semanticLabel: 'Trim',
              shape: AppIconButtonShape.square,
              variant: AppButtonVariant.secondary,
              onPressed: () {},
            ),
            AppIconButton(
              icon: Icons.tune_rounded,
              semanticLabel: 'Settings',
              shape: AppIconButtonShape.square,
              size: AppButtonSize.sm,
              onPressed: () {},
            ),
            const AppIconButton(
              icon: Icons.delete_outline_rounded,
              semanticLabel: 'Delete',
              shape: AppIconButtonShape.square,
            ),
          ],
        ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Round play button on the card.
class ContinueHeroPlayButton extends StatelessWidget {
  const ContinueHeroPlayButton({super.key, required this.onTap});

  final VoidCallback onTap;

  static const double _size = 48;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      label: 'Continue lesson',
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

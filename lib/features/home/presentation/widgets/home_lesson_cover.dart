import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Square lesson cover: a gradient with a progress bar at the bottom.
class HomeLessonCover extends StatelessWidget {
  const HomeLessonCover({super.key});

  static const double _size = 44;

  @override
  Widget build(BuildContext context) {
    final onGrad = context.colors.primaryOn;

    return ClipRRect(
      borderRadius: AppRadii.rSm,
      child: SizedBox(
        width: _size,
        height: _size,
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppBrand.signGradient),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: SizedBox(
              height: 5,
              child: Row(
                children: [
                  SizedBox(
                    width: _size * 0.6,
                    child: ColoredBox(color: onGrad),
                  ),
                  Expanded(
                    child: ColoredBox(color: onGrad.withValues(alpha: 0.4)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

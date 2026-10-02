import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';


/// Full-screen countdown before the start; it does not absorb taps.
class LessonCountdownOverlay extends StatelessWidget {
  const LessonCountdownOverlay({super.key, required this.countdown});

  /// `null` hides the overlay.
  final int? countdown;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: context.motion(AppDurations.fast),
        child: countdown == null
            ? const SizedBox.shrink()
            : Container(
                key: const ValueKey('countdown-scrim'),
                color: colors.surfaceInv.withValues(alpha: AppOpacities.scrim),
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: context.motion(AppDurations.fast),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Text(
                    '$countdown',
                    key: ValueKey(countdown),
                    // A custom size on top of the display style.
                    style: AppText.displayLg.copyWith(
                      fontSize: 96,
                      color: colors.textInv,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

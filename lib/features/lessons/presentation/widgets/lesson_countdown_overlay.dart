import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/theme/theme.dart';

import '../controllers/lesson_controller.dart';

/// Full-screen countdown before the start; it does not absorb taps.
class LessonCountdownOverlay extends ConsumerWidget {
  const LessonCountdownOverlay({super.key, required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countdown = ref.watch(
      lessonControllerProvider(
        lessonId,
      ).select((state) => state.value?.countdown),
    );
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

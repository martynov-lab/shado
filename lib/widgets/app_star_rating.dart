import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/app_star.dart';
import 'package:shado/widgets/app_tap_target.dart';

/// Five stars for how well a phrase is known. Tapping the current value
/// clears it; without [onChanged] the stars only show the value.
class AppStarRating extends StatelessWidget {
  const AppStarRating({
    super.key,
    required this.value,
    this.onChanged,
    this.size = AppSizes.iconLg,
  });

  static const int maxStars = 5;

  /// `0..5`; `0` means not rated.
  final int value;

  /// Gets the new value, `0` when the current one is tapped again.
  final ValueChanged<int>? onChanged;

  final double size;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;

    return Semantics(
      label: 'Rated $value of $maxStars',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var star = 1; star <= maxStars; star++)
            if (onChanged == null)
              AppStar(filled: star <= value, size: size)
            else
              Semantics(
                button: true,
                label: '$star of $maxStars',
                child: AppTapTarget(
                  minSize: Size.square(size + AppSpacing.s3),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(star == value ? 0 : star),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.s1),
                      child: AppStar(filled: star <= value, size: size),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

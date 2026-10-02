import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Strip above the sections while the device has no connection.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      liveRegion: true,
      child: ColoredBox(
        color: colors.warningSoft,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: AppSpacing.s2,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: AppSizes.iconSm,
                  color: colors.warning,
                ),
                const SizedBox(width: AppSpacing.s2),
                Expanded(
                  child: Text(
                    'Offline — downloaded lessons are available',
                    style: AppText.caption.copyWith(color: colors.text),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

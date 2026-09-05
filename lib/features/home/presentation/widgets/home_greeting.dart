import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../../lessons/presentation/widgets/account_menu.dart';

/// Home header: greeting, streak chip and the account menu.
class HomeGreeting extends StatelessWidget {
  const HomeGreeting({
    super.key,
    required this.name,
    this.streakDays = 0,
    this.showStreak = false,
    this.showAccount = true,
  });

  /// Name used in the greeting.
  final String name;

  /// Streak length in days for the chip.
  final int streakDays;

  /// Whether to show the streak chip.
  final bool showStreak;

  /// Whether to show the account menu on the right.
  final bool showAccount;

  /// Caption under the greeting.
  static const String _subtitle = 'Продолжим тренировку слуха?';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  text: 'Привет, ',
                  style: AppText.h2.copyWith(color: colors.text),
                  children: [
                    TextSpan(
                      text: name,
                      style: AppText.h2.copyWith(color: colors.primary),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.s1),
              Text(
                _subtitle,
                style: AppText.caption.copyWith(color: colors.text3),
              ),
            ],
          ),
        ),
        if (showStreak) ...[
          _StreakChip(days: streakDays),
          const SizedBox(width: AppSpacing.s2),
        ],
        if (showAccount) const AccountMenu(),
      ],
    );
  }
}

/// Streak chip: a flame icon and the number of days in a row.
class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadii.rPill,
        border: Border.all(color: colors.border, width: AppSizes.borderThin),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(AppIcons.flame, size: AppSizes.iconSm, color: colors.warning),
          const SizedBox(width: AppSpacing.s2),
          Text(
            '$days дней',
            style: AppText.label.copyWith(color: colors.text),
          ),
        ],
      ),
    );
  }
}

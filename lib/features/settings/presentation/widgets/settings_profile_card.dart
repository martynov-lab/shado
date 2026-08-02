import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Карточка профиля: аватар, имя, почта, уровень и метка «Изменить».
///
/// Метка — пока статичная (как в макете); экран редактирования профиля
/// подключим отдельной задачей.
class SettingsProfileCard extends StatelessWidget {
  const SettingsProfileCard({
    super.key,
    required this.name,
    required this.email,
    required this.level,
    this.editLabel = 'Изменить',
  });

  final String name;
  final String email;

  /// Текущий уровень, например «B1».
  final String level;

  final String editLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              gradient: AppBrand.signGradient,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: AppText.title.copyWith(color: colors.text),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.s1),
                Text(
                  email,
                  style: AppText.caption.copyWith(color: colors.text3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.s2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s3,
                    vertical: AppSpacing.s1,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primarySoft,
                    borderRadius: AppRadii.rPill,
                  ),
                  child: Text(
                    'Уровень $level',
                    style: AppText.caption.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: AppSpacing.s2,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadii.rPill,
              border: Border.all(
                color: colors.border,
                width: AppSizes.borderThin,
              ),
            ),
            child: Text(
              editLabel,
              style: AppText.label.copyWith(color: colors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

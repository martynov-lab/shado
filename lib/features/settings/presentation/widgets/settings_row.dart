import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Строка настройки: иконка в квадрате, заголовок с необязательным пояснением
/// и произвольный элемент справа (значение, тумблер, степпер).
///
/// Разделители между строками рисует [SettingsSection]. Интерактивность живёт в
/// [trailing]; сама строка — только разметка. Иконка — из набора Material
/// ([IconData]), как у [AppBadge]: набор Shadowing не покрывает все значки
/// настроек.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// Делает всю строку нажимаемой (открыть редактор значения). `null` — строка
  /// только показывает.
  final VoidCallback? onTap;

  /// Опасное действие — заголовок и иконка красятся в danger.
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tint = danger ? colors.danger : colors.text2;

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.surface2,
              borderRadius: AppRadii.rSm,
            ),
            child: Center(
              child: Icon(icon, size: AppSizes.iconSm, color: tint),
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppText.label.copyWith(
                    color: danger ? colors.danger : colors.text,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.s1),
                  Text(
                    subtitle!,
                    style: AppText.caption.copyWith(color: colors.text3),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.s3),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) return row;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.rSm,
        child: row,
      ),
    );
  }
}

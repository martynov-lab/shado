import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Смысл метки на карточке урока.
enum AppBadgeVariant {
  /// «Новый» — урок ещё не открывали. Зелёный, success.
  fresh,

  /// «Пора повторить» — подошёл срок. Янтарный, warning.
  due,

  /// «В ударе» — серия повторов не прервана. Розовый, accent.
  hot,
}

/// Небольшая пилюля-метка. Не интерактивна: это статус, а не кнопка.
///
/// Цвет берётся парой «мягкий фон + насыщенный текст», поэтому метка читается
/// на карточке и не спорит с основным содержимым.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.fresh,
    this.icon,
    this.semanticLabel,
  });

  final String label;
  final AppBadgeVariant variant;
  final IconData? icon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    final (Color background, Color foreground) = switch (variant) {
      AppBadgeVariant.fresh => (c.successSoft, c.success),
      AppBadgeVariant.due => (c.warningSoft, c.warning),
      AppBadgeVariant.hot => (c.accentSoft, c.accent),
    };

    return Semantics(
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s3,
          vertical: AppSpacing.s1,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadii.rPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: AppSizes.iconSm, color: foreground),
              const SizedBox(width: AppSpacing.s1),
            ],
            Text(label, style: AppText.caption.copyWith(color: foreground)),
          ],
        ),
      ),
    );
  }
}

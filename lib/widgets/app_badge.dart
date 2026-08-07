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

  /// Нейтральный статус вроде «Приватный» — серо-сиреневый, без окраски
  /// смысла, чтобы не спорить с метками прогресса.
  neutral,
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
    final colors = context.colors;

    final (Color background, Color foreground) = switch (variant) {
      AppBadgeVariant.fresh => (colors.successSoft, colors.success),
      AppBadgeVariant.due => (colors.warningSoft, colors.warning),
      AppBadgeVariant.hot => (colors.accentSoft, colors.accent),
      AppBadgeVariant.neutral => (colors.surface2, colors.text2),
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

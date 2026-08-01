import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/app_focus_ring.dart';
import 'package:shado/widgets/app_tap_target.dart';

/// Роль кнопки на экране: главное действие, второстепенное, третьестепенное.
enum AppButtonVariant { primary, secondary, ghost }

/// Цвета варианта во всех состояниях. Живут рядом с enum, чтобы кнопка и
/// иконочная кнопка выглядели одинаково без копирования switch'ей.
extension AppButtonVariantStyle on AppButtonVariant {
  /// Цвет подписи и иконки.
  Color foreground(AppColors colors) => switch (this) {
    AppButtonVariant.primary => colors.primaryOn,
    AppButtonVariant.secondary => colors.primary,
    AppButtonVariant.ghost => colors.text2,
  };

  /// Заливка с учётом наведения и нажатия.
  Color background(
    AppColors colors, {
    bool hovered = false,
    bool pressed = false,
  }) {
    return switch (this) {
      AppButtonVariant.primary when pressed => colors.primaryPress,
      AppButtonVariant.primary when hovered => colors.primaryHover,
      AppButtonVariant.primary => colors.primary,
      // Мягкую заливку темним тем же primary, но почти прозрачным — оттенок
      // остаётся из палитры, а не подбирается на глаз.
      AppButtonVariant.secondary when pressed => Color.alphaBlend(
        colors.primary.withValues(alpha: AppOpacities.press),
        colors.primarySoft,
      ),
      AppButtonVariant.secondary when hovered => Color.alphaBlend(
        colors.primary.withValues(alpha: AppOpacities.hover),
        colors.primarySoft,
      ),
      AppButtonVariant.secondary => colors.primarySoft,
      AppButtonVariant.ghost when pressed => colors.primary.withValues(
        alpha: AppOpacities.press,
      ),
      AppButtonVariant.ghost when hovered => colors.primary.withValues(
        alpha: AppOpacities.hover,
      ),
      AppButtonVariant.ghost => Colors.transparent,
    };
  }

  /// Обводка есть только у «призрачного» варианта — остальные держатся заливкой.
  BorderSide border(AppColors colors) => this == AppButtonVariant.ghost
      ? BorderSide(color: colors.borderStrong, width: AppSizes.borderThin)
      : BorderSide.none;
}

/// Размер кнопки. [sm] — для плотных панелей, [lg] — для главного действия
/// экрана.
enum AppButtonSize { sm, md, lg }

/// Reference component: a pill button built only from design tokens.
/// Use it as the template for every other widget in the library — read colors
/// from `context.colors`, sizes from `AppSpacing`/`AppRadii`, text from `AppText`.
///
/// Состояния (default / hover / pressed / focused / disabled) считаются здесь
/// явно, а не отдаются стоковому Material: цвет нажатия — [AppColors.primaryPress],
/// наведения — [AppColors.primaryHover].
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.expand = false,
    this.loading = false,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final AppButtonSize size;

  /// If true, stretches to the full width of its parent.
  final bool expand;

  /// Показывает индикатор вместо иконки и блокирует нажатия.
  final bool loading;

  /// Замена подписи для скринридера, если [label] без контекста непонятен.
  final String? semanticLabel;

  /// Кнопка нажимается: есть обработчик и не идёт загрузка.
  bool get isEnabled => onPressed != null && !loading;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = widget.isEnabled;

    final (
      double height,
      double padH,
      TextStyle textStyle,
      double iconSize,
    ) = switch (widget.size) {
      AppButtonSize.sm => (
        AppSizes.controlSm,
        AppSpacing.s4,
        AppText.label,
        AppSizes.iconSm,
      ),
      AppButtonSize.md => (
        AppSizes.controlMd,
        AppSpacing.s5,
        AppText.label,
        AppSizes.iconMd,
      ),
      AppButtonSize.lg => (
        AppSizes.controlLg,
        AppSpacing.s6,
        AppText.title,
        AppSizes.iconLg,
      ),
    };

    final fg = widget.variant.foreground(colors);
    final background = widget.variant.background(
      colors,
      hovered: _hovered,
      pressed: _pressed,
    );

    final shape = RoundedRectangleBorder(
      borderRadius: AppRadii.rPill,
      side: widget.variant.border(colors),
    );

    Widget visual = SizedBox(
      height: height,
      child: Material(
        color: background,
        shape: shape,
        animationDuration: context.motion(AppDurations.fast),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? widget.onPressed : null,
          onHover: (value) => setState(() => _hovered = value),
          onHighlightChanged: (value) => setState(() => _pressed = value),
          onFocusChange: (value) =>
              setState(() => _focused = value && AppFocusRing.isKeyboardFocus),
          canRequestFocus: enabled,
          borderRadius: AppRadii.rPill,
          // Подсветку состояний рисуем сами — стоковый оверлей поверх наших
          // цветов дал бы двойное затемнение.
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padH),
            child: Row(
              mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.loading) ...[
                  SizedBox.square(
                    dimension: iconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: AppSizes.spinnerStroke,
                      color: fg,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s2),
                ] else if (widget.icon != null) ...[
                  Icon(widget.icon, size: iconSize, color: fg),
                  const SizedBox(width: AppSpacing.s2),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    style: textStyle.copyWith(color: fg),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!enabled) {
      visual = Opacity(opacity: AppOpacities.disabled, child: visual);
    }

    final button = Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel ?? widget.label,
      excludeSemantics: true,
      child: AppTapTarget(
        child: AppFocusRing(
          visible: _focused,
          borderRadius: AppRadii.rPill,
          child: visual,
        ),
      ),
    );

    return widget.expand
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

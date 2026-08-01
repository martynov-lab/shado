import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/app_focus_ring.dart';

/// Один пункт выпадающего списка.
class AppDropdownItem<T> {
  const AppDropdownItem({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Выпадающий список.
///
/// Меню строится на [MenuAnchor] — он берёт на себя позиционирование, Esc и
/// навигацию стрелками, — но рисуется полностью нами: поверхность surface,
/// радиус rLg, тень e2. Стоковый фон и elevation отключены, иначе поверх нашей
/// тени легла бы вторая, материаловская.
class AppDropdown<T> extends StatefulWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.hint,
    this.semanticLabel,
  });

  final T? value;
  final List<AppDropdownItem<T>> items;

  /// `null` выключает список.
  final ValueChanged<T>? onChanged;

  /// Подпись над контролом.
  final String? label;

  /// Текст, когда ничего не выбрано.
  final String? hint;
  final String? semanticLabel;

  bool get isEnabled => onChanged != null && items.isNotEmpty;

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  final MenuController _menu = MenuController();
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = widget.isEnabled;

    AppDropdownItem<T>? selected;
    for (final item in widget.items) {
      if (item.value == widget.value) {
        selected = item;
        break;
      }
    }

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel ?? widget.label,
      value: selected?.label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: AppText.label.copyWith(color: colors.text2),
            ),
            const SizedBox(height: AppSpacing.s2),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              // Меню должно быть не уже кнопки — иначе выпадающий список
              // выглядит оторванным от неё.
              final menuWidth = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : AppSizes.overlayMaxWidth;
              return MenuAnchor(
                controller: _menu,
                alignmentOffset: const Offset(0, AppSpacing.s1),
                style: MenuStyle(
                  backgroundColor: const WidgetStatePropertyAll(
                    Colors.transparent,
                  ),
                  surfaceTintColor: const WidgetStatePropertyAll(
                    Colors.transparent,
                  ),
                  shadowColor: const WidgetStatePropertyAll(Colors.transparent),
                  elevation: const WidgetStatePropertyAll(0),
                  padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                  maximumSize: const WidgetStatePropertyAll(Size.infinite),
                ),
                menuChildren: [
                  Container(
                    width: menuWidth,
                    padding: const EdgeInsets.all(AppSpacing.s2),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: AppRadii.rLg,
                      border: Border.all(
                        color: colors.border,
                        width: AppSizes.borderThin,
                      ),
                      boxShadow: context.shadows.e2,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final item in widget.items)
                          _DropdownItemButton<T>(
                            item: item,
                            selected: item.value == widget.value,
                            onPressed: () {
                              widget.onChanged?.call(item.value);
                              _menu.close();
                            },
                          ),
                      ],
                    ),
                  ),
                ],
                builder: (context, controller, child) {
                  return AppFocusRing(
                    visible: _focused,
                    borderRadius: AppRadii.rMd,
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        onTap: enabled
                            ? () => controller.isOpen
                                  ? controller.close()
                                  : controller.open()
                            : null,
                        onHover: (value) => setState(() => _hovered = value),
                        onFocusChange: (value) => setState(
                          () =>
                              _focused = value && AppFocusRing.isKeyboardFocus,
                        ),
                        canRequestFocus: enabled,
                        borderRadius: AppRadii.rMd,
                        overlayColor: const WidgetStatePropertyAll(
                          Colors.transparent,
                        ),
                        child: Opacity(
                          opacity: enabled ? 1 : AppOpacities.disabled,
                          child: AnimatedContainer(
                            duration: context.motion(AppDurations.fast),
                            curve: AppCurves.standard,
                            constraints: const BoxConstraints(
                              minHeight: AppSizes.controlLg,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s4,
                              vertical: AppSpacing.s3,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surface2,
                              borderRadius: AppRadii.rMd,
                              border: Border.all(
                                color: _hovered
                                    ? colors.borderStrong
                                    : colors.border,
                                width: AppSizes.borderThin,
                              ),
                            ),
                            child: Row(
                              children: [
                                if (selected?.icon != null) ...[
                                  Icon(
                                    selected!.icon,
                                    size: AppSizes.iconMd,
                                    color: colors.text2,
                                  ),
                                  const SizedBox(width: AppSpacing.s3),
                                ],
                                Expanded(
                                  child: Text(
                                    selected?.label ?? widget.hint ?? '',
                                    style: AppText.body.copyWith(
                                      color: selected == null
                                          ? colors.text3
                                          : colors.text,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.s2),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: AppSizes.iconMd,
                                  color: colors.text2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Строка меню. Отдельный [MenuItemButton], чтобы работали стрелки и Esc.
class _DropdownItemButton<T> extends StatelessWidget {
  const _DropdownItemButton({
    required this.item,
    required this.selected,
    required this.onPressed,
  });

  final AppDropdownItem<T> item;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MenuItemButton(
      onPressed: onPressed,
      leadingIcon: item.icon == null
          ? null
          : Icon(
              item.icon,
              size: AppSizes.iconMd,
              color: selected ? colors.primary : colors.text2,
            ),
      trailingIcon: selected
          ? Icon(
              Icons.check_rounded,
              size: AppSizes.iconMd,
              color: colors.primary,
            )
          : null,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size(0, AppSizes.minTouchTarget),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpacing.s3),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppRadii.rSm),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return colors.primary.withValues(alpha: AppOpacities.press);
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return colors.primary.withValues(alpha: AppOpacities.hover);
          }
          return selected ? colors.primarySoft : Colors.transparent;
        }),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        textStyle: WidgetStatePropertyAll(AppText.body),
        foregroundColor: WidgetStatePropertyAll(
          selected ? colors.primary : colors.text,
        ),
      ),
      child: Text(item.label, overflow: TextOverflow.ellipsis),
    );
  }
}

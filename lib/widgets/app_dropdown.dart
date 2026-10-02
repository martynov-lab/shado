import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/app_dropdown_item_button.dart';
import 'package:shado/widgets/app_focus_ring.dart';

/// A single dropdown item.
class AppDropdownItem<T> {
  const AppDropdownItem({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Dropdown built on [MenuAnchor] and styled by tokens.
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

  /// `null` disables the dropdown.
  final ValueChanged<T>? onChanged;

  /// Label above the control.
  final String? label;

  /// Text shown when nothing is selected.
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
              // The menu is as wide as the button.
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
                          AppDropdownItemButton<T>(
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

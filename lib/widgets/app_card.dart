import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/app_focus_ring.dart';

/// Карточка: поверхность surface, скругление rXl, мягкая тень e1 и отступ s6.
///
/// Если задан [onTap], карточка становится кнопкой: на наведении поднимается
/// до тени e2, получает кольцо фокуса и объявляется скринридеру как нажимаемая.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.s6),
    this.selected = false,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  /// Выделяет карточку рамкой primary — например, текущий урок в списке.
  final bool selected;

  final String? semanticLabel;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final interactive = widget.onTap != null;

    final surface = AnimatedContainer(
      duration: context.motion(AppDurations.base),
      curve: AppCurves.standard,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadii.rXl,
        border: Border.all(
          color: widget.selected ? colors.primary : colors.border,
          width: widget.selected ? AppSizes.borderThick : AppSizes.borderThin,
        ),
        boxShadow: interactive && _hovered
            ? context.shadows.e2
            : context.shadows.e1,
      ),
      child: widget.child,
    );

    if (!interactive) {
      return Semantics(
        label: widget.semanticLabel,
        container: widget.semanticLabel != null,
        child: surface,
      );
    }

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: AppFocusRing(
        visible: _focused,
        borderRadius: AppRadii.rXl,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            onHover: (value) => setState(() => _hovered = value),
            onFocusChange: (value) => setState(
              () => _focused = value && AppFocusRing.isKeyboardFocus,
            ),
            borderRadius: AppRadii.rXl,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            child: surface,
          ),
        ),
      ),
    );
  }
}

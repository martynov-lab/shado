import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/app_focus_ring.dart';
import 'package:shado/widgets/app_segmented_control.dart';

/// Один сегмент внутри [AppSegmentedControl]: выбранный приподнят на surface
/// и тени e1, остальные лежат на дорожке.
class AppSegmentTile<T> extends StatefulWidget {
  const AppSegmentTile({
    super.key,
    required this.segment,
    required this.isSelected,
    required this.onPressed,
  });

  final AppSegment<T> segment;
  final bool isSelected;

  /// `null` — переключатель выключен целиком.
  final VoidCallback? onPressed;

  @override
  State<AppSegmentTile<T>> createState() => _AppSegmentTileState<T>();
}

class _AppSegmentTileState<T> extends State<AppSegmentTile<T>> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selected = widget.isSelected;

    final foreground = selected
        ? colors.primary
        : (_hovered ? colors.text : colors.text2);
    final hasLabel = widget.segment.label.isNotEmpty;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      button: true,
      label: widget.segment.semanticLabel ?? widget.segment.label,
      excludeSemantics: true,
      child: AppFocusRing(
        visible: _focused,
        borderRadius: AppRadii.rPill,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onPressed,
            onHover: (value) => setState(() => _hovered = value),
            onFocusChange: (value) => setState(
              () => _focused = value && AppFocusRing.isKeyboardFocus,
            ),
            canRequestFocus: widget.onPressed != null,
            borderRadius: AppRadii.rPill,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            child: AnimatedContainer(
              duration: context.motion(AppDurations.base),
              curve: AppCurves.standard,
              // Сегмент сам по себе — тач-цель, поэтому не меньше 48×48;
              // дорожка получается на s1 выше с каждой стороны.
              height: AppSizes.minTouchTarget,
              constraints: const BoxConstraints(
                minWidth: AppSizes.minTouchTarget,
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              decoration: BoxDecoration(
                color: selected ? colors.surface : Colors.transparent,
                borderRadius: AppRadii.rPill,
                boxShadow: selected ? context.shadows.e1 : const [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.segment.icon != null)
                    Icon(
                      widget.segment.icon,
                      size: AppSizes.iconSm,
                      color: foreground,
                    ),
                  // Пустая подпись — законный случай: на узком экране сегмент
                  // остаётся одной иконкой, и лишний отступ там не нужен.
                  if (widget.segment.icon != null && hasLabel)
                    const SizedBox(width: AppSpacing.s2),
                  if (hasLabel)
                    Flexible(
                      child: Text(
                        widget.segment.label,
                        style: AppText.label.copyWith(color: foreground),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

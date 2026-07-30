import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/app_focus_ring.dart';

/// Один сегмент переключателя.
class AppSegment<T> {
  const AppSegment({
    required this.value,
    required this.label,
    this.icon,
    this.semanticLabel,
  });

  final T value;
  final String label;
  final IconData? icon;
  final String? semanticLabel;
}

/// Переключатель нескольких взаимоисключающих режимов — «пилюля» с дорожкой
/// surface2, внутри которой выбранный сегмент приподнят на surface и тени e1.
///
/// Подходит для коротких наборов (2–4 пункта): скорость, режим повтора, тема.
/// Для длинных списков берите [AppDropdown].
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.value,
    required this.segments,
    required this.onChanged,
    this.expand = false,
    this.semanticLabel,
  });

  final T value;
  final List<AppSegment<T>> segments;

  /// `null` выключает переключатель целиком.
  final ValueChanged<T>? onChanged;

  /// Растянуть на всю ширину, разделив её между сегментами поровну.
  final bool expand;

  final String? semanticLabel;

  bool get isEnabled => onChanged != null;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    Widget track = Container(
      padding: const EdgeInsets.all(AppSpacing.s1),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: AppRadii.rPill,
        border: Border.all(color: c.border, width: AppSizes.borderThin),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (final segment in segments)
            if (expand)
              Expanded(child: _buildSegment(context, segment))
            else
              _buildSegment(context, segment),
        ],
      ),
    );

    if (!isEnabled) {
      track = Opacity(opacity: AppOpacities.disabled, child: track);
    }

    return Semantics(label: semanticLabel, container: true, child: track);
  }

  Widget _buildSegment(BuildContext context, AppSegment<T> segment) {
    return _Segment<T>(
      segment: segment,
      selected: segment.value == value,
      onTap: isEnabled ? () => onChanged!(segment.value) : null,
    );
  }
}

class _Segment<T> extends StatefulWidget {
  const _Segment({
    required this.segment,
    required this.selected,
    required this.onTap,
  });

  final AppSegment<T> segment;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<_Segment<T>> createState() => _SegmentState<T>();
}

class _SegmentState<T> extends State<_Segment<T>> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final selected = widget.selected;

    final foreground = selected ? c.primary : (_hovered ? c.text : c.text2);
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
            onTap: widget.onTap,
            onHover: (value) => setState(() => _hovered = value),
            onFocusChange: (value) => setState(
              () => _focused = value && AppFocusRing.isKeyboardFocus,
            ),
            canRequestFocus: widget.onTap != null,
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
                color: selected ? c.surface : Colors.transparent,
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

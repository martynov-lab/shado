import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/app_segment_tile.dart';

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
    final colors = context.colors;

    Widget track = Container(
      padding: const EdgeInsets.all(AppSpacing.s1),
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: AppRadii.rPill,
        border: Border.all(color: colors.border, width: AppSizes.borderThin),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (final segment in segments)
            if (expand)
              Expanded(
                child: AppSegmentTile<T>(
                  segment: segment,
                  isSelected: segment.value == value,
                  onPressed: isEnabled ? () => onChanged!(segment.value) : null,
                ),
              )
            else
              AppSegmentTile<T>(
                segment: segment,
                isSelected: segment.value == value,
                onPressed: isEnabled ? () => onChanged!(segment.value) : null,
              ),
        ],
      ),
    );

    if (!isEnabled) {
      track = Opacity(opacity: AppOpacities.disabled, child: track);
    }

    return Semantics(label: semanticLabel, container: true, child: track);
  }
}

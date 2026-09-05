import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Design system slider: speed, seeking, volume.
class AppSlider extends StatelessWidget {
  const AppSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.label,
    this.valueLabel,
    this.semanticLabel,
    this.semanticFormatter,
  });

  final double value;

  /// `null` disables the slider.
  final ValueChanged<double>? onChanged;

  /// Called when dragging ends.
  final ValueChanged<double>? onChangeEnd;

  final double min;
  final double max;

  /// Number of divisions; `null` means continuous movement.
  final int? divisions;

  /// Label above the slider on the left.
  final String? label;

  /// Current value above the slider on the right.
  final String? valueLabel;

  final String? semanticLabel;

  /// How to announce the value to a screen reader.
  final SemanticFormatterCallback? semanticFormatter;

  bool get isEnabled => onChanged != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final slider = SliderTheme(
      data: SliderThemeData(
        trackHeight: AppSizes.sliderTrack,
        activeTrackColor: colors.primary,
        inactiveTrackColor: colors.waveOff,
        disabledActiveTrackColor: colors.borderStrong,
        disabledInactiveTrackColor: colors.border,
        thumbColor: colors.primary,
        disabledThumbColor: colors.borderStrong,
        overlayColor: colors.primary.withValues(alpha: AppOpacities.hover),
        trackShape: const RoundedRectSliderTrackShape(),
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: AppSizes.sliderThumb / 2,
        ),
        overlayShape: const RoundSliderOverlayShape(
          overlayRadius: AppSizes.minTouchTarget / 2,
        ),
        valueIndicatorColor: colors.surfaceInv,
        valueIndicatorTextStyle: AppText.monoTime.copyWith(
          color: colors.textInv,
        ),
        showValueIndicator: ShowValueIndicator.onlyForDiscrete,
      ),
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        label: valueLabel,
        onChanged: onChanged,
        onChangeEnd: onChangeEnd,
        semanticFormatterCallback: semanticFormatter,
      ),
    );

    if (label == null && valueLabel == null) {
      return Semantics(label: semanticLabel, child: slider);
    }

    return Semantics(
      label: semanticLabel ?? label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (label != null)
                Expanded(
                  child: Text(
                    label!,
                    style: AppText.label.copyWith(color: colors.text2),
                  ),
                ),
              if (valueLabel != null)
                Text(
                  valueLabel!,
                  style: AppText.monoTime.copyWith(color: colors.text),
                ),
            ],
          ),
          slider,
        ],
      ),
    );
  }
}

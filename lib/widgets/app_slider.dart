import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';

/// Ползунок: скорость воспроизведения, перемотка, громкость.
///
/// Внутри — материаловский [Slider], но целиком перекрашенный через
/// [SliderTheme]: он даёт бесплатно перетаскивание, шаги и управление
/// стрелками с клавиатуры, а вид всё равно наш. Неактивная часть трека
/// красится в waveOff — тот же цвет, что у «непройденной» волны.
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

  /// `null` выключает ползунок.
  final ValueChanged<double>? onChanged;

  /// Вызывается по окончании перетаскивания — удобно, чтобы не дёргать
  /// перемотку на каждый кадр.
  final ValueChanged<double>? onChangeEnd;

  final double min;
  final double max;

  /// Число шагов. `null` — плавное движение.
  final int? divisions;

  /// Подпись слева над ползунком.
  final String? label;

  /// Текущее значение справа над ползунком — моноширинным, чтобы цифры не
  /// прыгали при изменении.
  final String? valueLabel;

  final String? semanticLabel;

  /// Как озвучить значение скринридеру.
  final SemanticFormatterCallback? semanticFormatter;

  bool get isEnabled => onChanged != null;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    final slider = SliderTheme(
      data: SliderThemeData(
        trackHeight: AppSizes.sliderTrack,
        activeTrackColor: c.primary,
        inactiveTrackColor: c.waveOff,
        disabledActiveTrackColor: c.borderStrong,
        disabledInactiveTrackColor: c.border,
        thumbColor: c.primary,
        disabledThumbColor: c.borderStrong,
        overlayColor: c.primary.withValues(alpha: AppOpacities.hover),
        trackShape: const RoundedRectSliderTrackShape(),
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: AppSizes.sliderThumb / 2,
        ),
        overlayShape: const RoundSliderOverlayShape(
          overlayRadius: AppSizes.minTouchTarget / 2,
        ),
        valueIndicatorColor: c.surfaceInv,
        valueIndicatorTextStyle: AppText.monoTime.copyWith(color: c.textInv),
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
                    style: AppText.label.copyWith(color: c.text2),
                  ),
                ),
              if (valueLabel != null)
                Text(
                  valueLabel!,
                  style: AppText.monoTime.copyWith(color: c.text),
                ),
            ],
          ),
          slider,
        ],
      ),
    );
  }
}

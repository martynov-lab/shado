import 'package:flutter/material.dart';

import 'package:shado/core/constants/app_constants.dart';
import 'package:shado/widgets/widgets.dart';

/// Лист выбора скорости по умолчанию: варианты из [kPlaybackSpeeds]. Тап по
/// строке сразу возвращает выбранную скорость через `Navigator.pop`.
class PlaybackSpeedSheet extends StatelessWidget {
  const PlaybackSpeedSheet({super.key, required this.current});

  final double current;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final speed in kPlaybackSpeeds)
          AppRadio<double>(
            value: speed,
            groupValue: current,
            label: speedLabel(speed),
            onChanged: (value) => Navigator.of(context).pop(value),
          ),
      ],
    );
  }
}

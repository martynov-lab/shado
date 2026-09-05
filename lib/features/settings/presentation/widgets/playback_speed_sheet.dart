import 'package:flutter/material.dart';

import 'package:shado/core/constants/app_constants.dart';
import 'package:shado/widgets/widgets.dart';

/// Default speed picker sheet; a tap returns the selected value.
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

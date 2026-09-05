import 'package:flutter/material.dart';

import 'package:shado/widgets/widgets.dart';

/// The marker-at-playhead checkbox: where a new marker lands.
class MarkerAtPlayheadCheckbox extends StatelessWidget {
  const MarkerAtPlayheadCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;

  /// `null` disables the checkbox, for example while trimming.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: value
          ? 'Новая метка встанет в позицию ползунка'
          : 'Новая метка встанет правее самой правой',
      child: AppCheckbox(
        value: value,
        onChanged: onChanged,
        label: 'Метка по ползунку',
      ),
    );
  }
}

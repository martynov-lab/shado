import 'package:flutter/material.dart';

import 'package:shado/widgets/widgets.dart';

/// Флажок у кнопки воспроизведения: куда садится новая метка на волне.
///
/// Стоит — в позицию ползунка: доводят плеер до нужного места и ставят метку в
/// тексте. Снят — вплотную правее самой правой метки, а разносят их потом
/// руками по волне.
class MarkerAtPlayheadCheckbox extends StatelessWidget {
  const MarkerAtPlayheadCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;

  /// `null` выключает флажок — например, пока идёт обрезка.
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

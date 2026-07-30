import 'package:flutter/material.dart';

import 'package:shado/widgets/app_chip.dart';

/// Чип-фильтр: то же, что [AppChip], но переключается сам и показывает галочку
/// в выбранном состоянии.
///
/// Отдельный виджет, а не флаг у [AppChip], потому что у него другая роль в
/// разметке: набор фильтров — это множественный выбор, и скринридер должен
/// объявлять элементы как переключаемые.
///
/// ```dart
/// AppFilterChip(
///   label: 'Идиомы',
///   selected: tags.contains(tag),
///   onSelected: (value) => setState(() => value ? tags.add(tag) : tags.remove(tag)),
/// )
/// ```
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.style = AppChipStyle.onSoft,
    this.semanticLabel,
  });

  final String label;
  final bool selected;

  /// `null` выключает фильтр.
  final ValueChanged<bool>? onSelected;

  /// Иконка для невыбранного состояния; выбранное показывает галочку.
  final IconData? icon;

  final AppChipStyle style;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return AppChip(
      label: label,
      selected: selected,
      style: style,
      icon: selected ? Icons.check_rounded : icon,
      semanticLabel: semanticLabel,
      onTap: onSelected == null ? null : () => onSelected!(!selected),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:shado/widgets/widgets.dart';

import 'settings_row.dart';

/// Строка настройки с тумблером справа.
///
/// Управляемый режим — заданы [value] и [onChanged]: значение приходит извне и
/// сохраняется контроллером. Локальный режим — задан только [initialValue]:
/// тумблер живёт в самом виджете и ничего не сохраняет (заготовки настроек).
class SettingsSwitchRow extends StatefulWidget {
  const SettingsSwitchRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.initialValue,
    this.value,
    this.onChanged,
  }) : assert(
         value != null || initialValue != null,
         'Задайте value (управляемый) или initialValue (локальный)',
       );

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Управляемый режим: текущее значение и обработчик изменения.
  final bool? value;
  final ValueChanged<bool>? onChanged;

  /// Локальный режим (заготовка): стартовое значение тумблера.
  final bool? initialValue;

  @override
  State<SettingsSwitchRow> createState() => _SettingsSwitchRowState();
}

class _SettingsSwitchRowState extends State<SettingsSwitchRow> {
  late bool _local = widget.initialValue ?? false;

  bool get _controlled => widget.onChanged != null;
  bool get _value => _controlled ? widget.value! : _local;

  void _onChanged(bool value) {
    if (_controlled) {
      widget.onChanged!(value);
    } else {
      setState(() => _local = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsRow(
      icon: widget.icon,
      title: widget.title,
      subtitle: widget.subtitle,
      trailing: AppSwitch(
        value: _value,
        semanticLabel: widget.title,
        onChanged: _onChanged,
      ),
    );
  }
}

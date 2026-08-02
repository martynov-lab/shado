import 'package:flutter/material.dart';

import 'package:shado/widgets/widgets.dart';

import 'settings_row.dart';

/// Строка настройки с тумблером справа.
///
/// Состояние переключается локально и пока не сохраняется — привязку к
/// настройкам добавим отдельной задачей.
class SettingsSwitchRow extends StatefulWidget {
  const SettingsSwitchRow({
    super.key,
    required this.icon,
    required this.title,
    required this.initialValue,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool initialValue;

  @override
  State<SettingsSwitchRow> createState() => _SettingsSwitchRowState();
}

class _SettingsSwitchRowState extends State<SettingsSwitchRow> {
  late bool _value = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    return SettingsRow(
      icon: widget.icon,
      title: widget.title,
      subtitle: widget.subtitle,
      trailing: AppSwitch(
        value: _value,
        semanticLabel: widget.title,
        onChanged: (value) => setState(() => _value = value),
      ),
    );
  }
}

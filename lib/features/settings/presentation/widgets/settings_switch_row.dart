import 'package:flutter/material.dart';

import 'package:shado/widgets/widgets.dart';

import 'settings_row.dart';

/// Settings row with a switch; with [initialValue] the switch is local.
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

  /// Controlled mode: the current value and a change handler.
  final bool? value;
  final ValueChanged<bool>? onChanged;

  /// Local mode: the initial switch value.
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

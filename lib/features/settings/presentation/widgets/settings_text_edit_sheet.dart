import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Sheet for editing one profile text field; returns the entered string.
class SettingsTextEditSheet extends StatefulWidget {
  const SettingsTextEditSheet({
    super.key,
    required this.label,
    required this.initialValue,
    this.hint,
    this.keyboardType,
  });

  final String label;
  final String initialValue;
  final String? hint;
  final TextInputType? keyboardType;

  @override
  State<SettingsTextEditSheet> createState() => _SettingsTextEditSheetState();
}

class _SettingsTextEditSheetState extends State<SettingsTextEditSheet> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    // Bottom padding for the keyboard.
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _controller,
            label: widget.label,
            hint: widget.hint,
            autofocus: true,
            keyboardType: widget.keyboardType,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.s5),
          AppButton(
            label: 'Сохранить',
            size: AppButtonSize.lg,
            expand: true,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

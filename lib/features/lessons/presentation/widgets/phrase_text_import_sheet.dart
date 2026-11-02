import 'package:flutter/material.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

/// Sheet for pasting a text that turns into phrases; returns the text.
class PhraseTextImportSheet extends StatefulWidget {
  const PhraseTextImportSheet({super.key});

  @override
  State<PhraseTextImportSheet> createState() => _PhraseTextImportSheetState();
}

class _PhraseTextImportSheetState extends State<PhraseTextImportSheet> {
  final _controller = TextEditingController();

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
            label: 'Text',
            hint: 'Where is the check-in desk? I would like a window seat.',
            helperText:
                'A phrase ends at . ? or !; translations are filled in after.',
            autofocus: true,
            minLines: 6,
            maxLines: 12,
            keyboardType: TextInputType.multiline,
          ),
          const SizedBox(height: AppSpacing.s5),
          AppButton(
            label: 'Split into phrases',
            size: AppButtonSize.lg,
            expand: true,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

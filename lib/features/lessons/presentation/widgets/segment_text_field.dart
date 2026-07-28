import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

/// Текст урока с разделителями кусков. Общее поле для создания и правки.
class SegmentTextField extends StatelessWidget {
  const SegmentTextField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.segmentCount,
    this.enabled = true,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final int segmentCount;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: const InputDecoration(
            labelText: 'Текст',
            helperText: 'Разделяйте предложения символом «$kSegmentDelimiter»',
            alignLabelWithHint: true,
          ),
          minLines: 4,
          maxLines: 10,
          keyboardType: TextInputType.multiline,
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
        Text(
          'Кусков получится: $segmentCount',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

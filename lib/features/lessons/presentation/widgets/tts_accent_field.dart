import 'package:flutter/material.dart';

import '../../../languages/domain/entities/language.dart';

/// Voice-over accent picker; shown for languages that have accents.
class TtsAccentField extends StatelessWidget {
  const TtsAccentField({
    super.key,
    required this.accents,
    required this.selected,
    required this.onChanged,
  });

  final List<Accent> accents;

  /// Code of the chosen accent; a code missing from [accents] shows nothing.
  final String? selected;

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    // The dropdown throws when the selected value is not among the items.
    final value = accents.any((accent) => accent.code == selected)
        ? selected
        : null;

    return DropdownButtonFormField<String>(
      key: const ValueKey('dropdown-tts-accent'),
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Voiceover accent'),
      items: [
        for (final accent in accents)
          DropdownMenuItem(
            value: accent.code,
            child: Text(accent.label, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (code) {
        if (code != null) onChanged(code);
      },
    );
  }
}

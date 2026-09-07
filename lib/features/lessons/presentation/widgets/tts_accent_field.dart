import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../languages/presentation/controllers/language_providers.dart';
import '../controllers/tts_voice_controller.dart';

/// Voice-over accent picker; shown for languages that have accents.
class TtsAccentField extends ConsumerWidget {
  const TtsAccentField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accents = ref.watch(currentAccentsProvider);
    if (accents.isEmpty) return const SizedBox.shrink();

    final selected = ref.watch(
      ttsVoiceControllerProvider.select((state) => state.value?.accent),
    );
    // The dropdown throws when the selected value is not among the items.
    final value = accents.any((accent) => accent.code == selected)
        ? selected
        : null;

    return DropdownButtonFormField<String>(
      key: const ValueKey('dropdown-tts-accent'),
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Акцент озвучки'),
      items: [
        for (final accent in accents)
          DropdownMenuItem(
            value: accent.code,
            child: Text(accent.label, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (code) {
        if (code == null) return;
        ref.read(ttsVoiceControllerProvider.notifier).selectAccent(code);
      },
    );
  }
}

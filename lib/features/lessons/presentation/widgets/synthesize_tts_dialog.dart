import 'package:flutter/material.dart';

/// Confirms replacing the chosen audio with a voice-over; `true` proceeds.
class SynthesizeTtsDialog extends StatelessWidget {
  const SynthesizeTtsDialog({super.key});

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Replace audio with a voiceover?'),
    content: const Text(
      'Audio is already uploaded. The AI voiceover will replace it, and the placed '
      'segment boundaries will be reset.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('Voice'),
      ),
    ],
  );
}

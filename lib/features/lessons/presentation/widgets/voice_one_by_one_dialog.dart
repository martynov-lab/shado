import 'package:flutter/material.dart';

/// Offer to voice phrases separately after the batch failed to split;
/// `true` means go ahead.
class VoiceOneByOneDialog extends StatelessWidget {
  const VoiceOneByOneDialog({super.key, required this.count});

  /// How many phrases, and so voice-overs from today's quota, it takes.
  final int count;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Voice phrases one by one?'),
    content: Text(
      'The AI read the phrases together and the audio could not be split. '
      'Voicing them separately takes $count voice-overs from today.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('Voice separately'),
      ),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/theme/theme.dart';

import '../controllers/lesson_providers.dart';

/// Подпись под плашкой аудио: сколько озвучек через ИИ осталось на сегодня
/// (TTS_CLIENT_SPEC §4.1). Видеть остаток заранее приятнее, чем упереться в
/// отказ.
///
/// Пока квота грузится или запрос упал — не показываем ничего: подсказка
/// необязательна и не должна мигать ошибкой. При «без ограничения» счётчик тоже
/// не нужен.
class TtsQuotaHint extends ConsumerWidget {
  const TtsQuotaHint({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(ttsQuotaProvider).value?.day;
    final remaining = day?.remaining;
    if (day == null || day.isUnlimited || remaining == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s2),
      child: Text(
        'Осталось озвучек сегодня: $remaining',
        style: AppText.caption.copyWith(color: context.colors.text3),
      ),
    );
  }
}

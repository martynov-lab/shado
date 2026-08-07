import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/theme/theme.dart';
import 'package:shado/widgets/widgets.dart';

import '../../domain/entities/progress_summary.dart';
import '../controllers/progress_providers.dart';
import '../controllers/progress_view_model.dart';
import '../widgets/progress_desktop_view.dart';
import '../widgets/progress_mobile_view.dart';
import '../widgets/progress_tablet_view.dart';

/// Экран прогресса: серия, статистика, график минут, тепловая карта и цель.
///
/// Каркас (Scaffold, навигация) даёт [MainShell]; раскладку выбирает
/// [AppAdaptiveLayout]. Метрики — реальные (сводка `GET /v1/progress` и история);
/// «Уровень» и «Достижения» пока демонстрационные — под них нет серверных данных.
class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  static const String routePath = '/progress';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(progressSummaryProvider);
    // История — вторична: график и серия рисуются и без неё.
    final history =
        ref.watch(progressHistoryProvider).value ?? const <ProgressDay>[];

    return switch (summaryAsync) {
      AsyncError(:final error) => _ProgressError(
        message: '$error',
        onRetry: () => ref.read(progressSummaryProvider.notifier).refresh(),
      ),
      AsyncData(:final value) => _ProgressData(
        model: ProgressViewModel.from(value, history),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _ProgressData extends StatelessWidget {
  const _ProgressData({required this.model});

  final ProgressViewModel model;

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveLayout(
      mobile: (context) => ProgressMobileView(model: model),
      tablet: (context) => ProgressTabletView(model: model),
      desktop: (context) => ProgressDesktopView(model: model),
    );
  }
}

class _ProgressError extends StatelessWidget {
  const _ProgressError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Не удалось загрузить прогресс',
              style: AppText.title.copyWith(color: colors.text),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              message,
              style: AppText.caption.copyWith(color: colors.text3),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s5),
            AppButton(label: 'Повторить', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

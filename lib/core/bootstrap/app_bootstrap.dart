import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/progress/presentation/controllers/progress_providers.dart';

/// Прогрев данных, которые должны быть готовы к первому кадру после входа.
///
/// Пока сессии нет — делать нечего. Как только пользователь вошёл, заранее
/// тянем сводку прогресса (её показывают и главный экран, и «Прогресс»), чтобы
/// баннеры «Минуты по дням» и «Эта неделя» не мигали пустыми, пока идёт запрос.
/// Роутер держит заставку, пока этот провайдер в состоянии загрузки.
///
/// Ошибку наружу не отдаём: из-за недоступной статистики запирать пользователя
/// на заставке нельзя — экраны сами покажут пустое состояние или ошибку.
final appBootstrapProvider = FutureProvider<void>((ref) async {
  final status = ref.watch(
    authControllerProvider.select((state) => state.status),
  );
  if (status != AuthStatus.authenticated) return;

  try {
    // Таймаут — страховка от мёртвой сети: заставку держим недолго, дальше
    // пускаем в приложение, а запрос сам дойдёт и обновит экраны позже.
    await ref
        .read(progressSummaryProvider.future)
        .timeout(const Duration(seconds: 6));
  } catch (_) {
    // Провайдер сводки сохранит ошибку у себя; заставку из-за неё не держим.
  }
});

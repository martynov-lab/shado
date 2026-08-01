import 'package:flutter/widgets.dart';

import 'package:shado/theme/theme.dart';

/// Брендовый градиент из макета (`--grad`): диагональ primary → accent.
///
/// Им заливаются обложки уроков и логотип в навигации. Держим одним местом,
/// чтобы фиолетово-розовый переход не разъезжался по экранам.
LinearGradient lessonBrandGradient(AppColors colors) => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [colors.primary, colors.accent],
);

/// Тёмная поверхность панели плеера (в макете — токен `--player`).
///
/// Всегда тёмная — и в светлой теме, и в тёмной, — поэтому собрана из тёмной
/// палитры, а не из текущих `context.colors`, которые в тёмной теме
/// инвертировались бы в светлые.
LinearGradient lessonPlayerGradient() => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.dark.surface2, AppColors.dark.bg],
);

/// Текст и иконки на тёмной панели плеера — всегда светлые.
final Color lessonPlayerForeground = AppColors.dark.text;

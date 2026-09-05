import 'package:flutter/widgets.dart';

import 'package:shado/theme/theme.dart';

/// Brand gradient: a primary to accent diagonal.
LinearGradient lessonBrandGradient(AppColors colors) => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [colors.primary, colors.accent],
);

/// Player panel surface; dark in both themes.
LinearGradient lessonPlayerGradient() => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.dark.surface2, AppColors.dark.bg],
);

/// Text and icons on the dark player panel are always light.
final Color lessonPlayerForeground = AppColors.dark.text;

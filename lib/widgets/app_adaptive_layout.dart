import 'package:flutter/widgets.dart';

import 'package:shado/theme/theme.dart';

/// Раскладка под платформу: телефон, планшет, десктоп. Вариант выбирается по
/// ширине окна ([AppBreakpoints]) и строится только он — соседние раскладки не
/// собираются, поэтому тяжёлую разметку десктопа не платим на телефоне.
///
/// [tablet] и [desktop] необязательны: если вариант не задан, берётся ближайший
/// меньший (десктоп → планшет → телефон). Экрану, которому хватает одной широкой
/// раскладки, задаём её в [tablet] и оставляем [desktop] пустым.
///
/// ```dart
/// AppAdaptiveLayout(
///   mobile: (context) => LessonMobileView(state: state),
///   tablet: (context) => LessonTabletView(state: state),
///   desktop: (context) => LessonDesktopView(state: state),
/// );
/// ```
///
/// Раскладки отличаются только компоновкой (колонки, панели, отступы). Данные и
/// колбэки одни и те же — их раздаёт экран выше [AppAdaptiveLayout]. Мелкие
/// отличия без отдельного виджета берём через [AppThemeContext.responsive].
class AppAdaptiveLayout extends StatelessWidget {
  const AppAdaptiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  /// Телефон (ширина < [AppBreakpoints.tablet]) — обязательная базовая раскладка.
  final WidgetBuilder mobile;

  /// Планшет ([AppBreakpoints.tablet]..[AppBreakpoints.desktop)).
  final WidgetBuilder? tablet;

  /// Десктоп и веб (ширина ≥ [AppBreakpoints.desktop]).
  final WidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) return (desktop ?? tablet ?? mobile)(context);
    if (context.isTablet) return (tablet ?? mobile)(context);
    return mobile(context);
  }
}

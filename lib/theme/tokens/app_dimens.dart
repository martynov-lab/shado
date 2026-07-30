import 'package:flutter/widgets.dart';

/// 4pt spacing scale. Use for padding, gaps, and margins everywhere so
/// rhythm stays consistent across screens.
abstract final class AppSpacing {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;
  static const double s16 = 64;
}

/// Corner radii. Raw `double`s plus ready-made [BorderRadius] constants.
abstract final class AppRadii {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double xxl = 30;
  static const double pill = 999;

  static const BorderRadius rXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius rSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius rMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius rLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius rXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius rXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius rPill = BorderRadius.all(Radius.circular(pill));
}

/// Layout breakpoints. Below [tablet] is phone; [tablet]..[desktop) is tablet;
/// [desktop] and up is desktop / web.
abstract final class AppBreakpoints {
  static const double tablet = 600;
  static const double desktop = 1024;

  /// Ширина, шире которой контент не растягивается на desktop/web — иначе
  /// строки текста становятся нечитаемо длинными.
  static const double maxContent = 1040;
}

/// Размеры контролов и элементов внутри них. Держит компоненты в одной
/// вертикальной сетке и гарантирует тач-цели не меньше [minTouchTarget].
abstract final class AppSizes {
  /// Минимальная область нажатия (WCAG 2.5.5 / Material a11y).
  static const double minTouchTarget = 48;

  // Высота интерактивных контролов по размерам sm / md / lg.
  static const double controlSm = 36;
  static const double controlMd = 44;
  static const double controlLg = 52;

  // Иконки.
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;

  // Обводки.
  static const double borderThin = 1;
  static const double borderThick = 2;

  /// Толщина кольца фокуса с клавиатуры.
  static const double focusRing = 3;

  // Элементы форм.
  static const double checkbox = 22;
  static const double radio = 22;
  static const double radioDot = 10;
  static const double switchWidth = 48;
  static const double switchHeight = 28;
  static const double switchThumb = 22;
  static const double sliderTrack = 6;
  static const double sliderThumb = 20;

  /// Обложка урока в строке списка.
  static const double cover = 48;

  /// Диаметр индикатора загрузки внутри кнопки.
  static const double spinner = 18;
  static const double spinnerStroke = 2;

  // «Ручка» модального листа.
  static const double sheetHandleWidth = 40;
  static const double sheetHandleHeight = 4;

  /// Максимальная ширина всплывающего меню и тоста.
  static const double overlayMaxWidth = 420;
}

/// Прозрачности для наложений и выключенных состояний. Вынесены в токены,
/// чтобы в виджетах не встречались «сырые» альфы.
abstract final class AppOpacities {
  /// Выключенный контрол целиком.
  static const double disabled = 0.45;

  /// Подсветка при наведении и нажатии.
  static const double hover = 0.08;
  static const double press = 0.14;

  /// То же самое поверх залитой primary-поверхности — нужен светлый оверлей.
  static const double hoverOnPrimary = 0.10;
  static const double pressOnPrimary = 0.18;

  /// Кольцо фокуса и затемнение фона под оверлеями.
  static const double focusRing = 0.55;
  static const double scrim = 0.45;
}

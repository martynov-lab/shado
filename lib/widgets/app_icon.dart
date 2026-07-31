import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:shado/theme/theme.dart';

/// Иконки набора Shadowing. Значение — имя SVG-файла в `assets/app_icons/`,
/// поэтому новая иконка добавляется двумя шагами: положить файл в папку и
/// дописать сюда строку.
///
/// Набор — слепок макетов: иконки линейные, нарисованы в сетке 24×24 и
/// красятся через `currentColor`, отсюда единый тинт в [AppIcon].
enum AppIcons {
  bell('bell'),
  brandApple('brand_apple'),
  brandGoogle('brand_google', multicolor: true),
  chart('chart'),
  check('check'),
  chevronDown('chevron_down'),
  chevronLeft('chevron_left'),
  chevronRight('chevron_right'),
  clock('clock'),
  clockAlt('clock_alt'),
  close('close'),
  database('database'),
  download('download'),
  eye('eye'),
  eyeOff('eye_off'),
  flame('flame'),
  globe('globe'),
  headphones('headphones'),
  home('home'),
  list('list'),
  listBullets('list_bullets'),
  lock('lock'),
  lockAlt('lock_alt'),
  logoWave('logo_wave'),
  loop('loop'),
  mail('mail'),
  moreHorizontal('more_horizontal'),
  moreVertical('more_vertical'),
  music('music'),
  next('next'),
  pause('pause'),
  pauseOutline('pause_outline'),
  play('play'),
  plus('plus'),
  prev('prev'),
  refresh('refresh'),
  rewind('rewind'),
  search('search'),
  settings('settings'),
  translate('translate'),
  trash('trash'),
  user('user'),
  waveform('waveform');

  const AppIcons(this.fileName, {this.multicolor = false});

  /// Имя файла без расширения — оно же имя иконки в макетах.
  final String fileName;

  /// Иконка нарисована фирменными цветами (логотип) и не перекрашивается.
  final bool multicolor;

  /// Путь к ассету для [AppIcon].
  String get asset => 'assets/app_icons/$fileName.svg';
}

/// Иконка дизайн-системы: SVG-ассет из набора Shadowing.
///
/// Ведёт себя как [Icon]: размер и цвет берутся из [IconTheme], если не заданы
/// явно, — поэтому иконку можно класть внутрь кнопок, полей и списков, не
/// подбирая цвет руками.
///
/// ```dart
/// const AppIcon(AppIcons.play);
/// AppIcon(AppIcons.home, size: AppSizes.iconLg, color: context.colors.primary);
/// ```
///
/// Без [semanticLabel] иконка считается декоративной и скрыта от скринридера:
/// подпись задаёт тот, кто вставляет иконку, — рядом с ней обычно уже есть
/// текст или `Semantics` кнопки.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  final AppIcons icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final side = size ?? iconTheme.size ?? AppSizes.iconMd;
    final tint = color ?? iconTheme.color ?? context.colors.text;

    return SvgPicture.asset(
      icon.asset,
      width: side,
      height: side,
      colorFilter: icon.multicolor
          ? null
          : ColorFilter.mode(tint, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}

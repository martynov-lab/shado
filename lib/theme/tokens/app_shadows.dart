import 'package:flutter/material.dart';

/// Elevation tokens as box-shadow lists. Three levels:
/// e1 = cards, e2 = hover / raised, e3 = player & bottom sheets.
@immutable
class AppShadows extends ThemeExtension<AppShadows> {
  const AppShadows({required this.e1, required this.e2, required this.e3});

  final List<BoxShadow> e1;
  final List<BoxShadow> e2;
  final List<BoxShadow> e3;

  static const AppShadows light = AppShadows(
    e1: [
      BoxShadow(
        color: Color(0x1A7C5CFF), // rgba(124,92,255,.10)
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
    e2: [
      BoxShadow(
        color: Color(0x247C5CFF), // rgba(124,92,255,.14)
        blurRadius: 26,
        offset: Offset(0, 10),
      ),
    ],
    e3: [
      BoxShadow(
        color: Color(0x241A1626), // rgba(26,22,38,.14)
        blurRadius: 48,
        offset: Offset(0, 20),
      ),
    ],
  );

  static const AppShadows dark = AppShadows(
    e1: [
      BoxShadow(color: Color(0x59000000), blurRadius: 10, offset: Offset(0, 2)),
    ],
    e2: [
      BoxShadow(
        color: Color(0x73000000),
        blurRadius: 30,
        offset: Offset(0, 12),
      ),
    ],
    e3: [
      BoxShadow(
        color: Color(0x8C000000),
        blurRadius: 54,
        offset: Offset(0, 24),
      ),
    ],
  );

  @override
  AppShadows copyWith({
    List<BoxShadow>? e1,
    List<BoxShadow>? e2,
    List<BoxShadow>? e3,
  }) {
    return AppShadows(e1: e1 ?? this.e1, e2: e2 ?? this.e2, e3: e3 ?? this.e3);
  }

  @override
  AppShadows lerp(ThemeExtension<AppShadows>? other, double t) {
    if (other is! AppShadows) return this;
    return AppShadows(
      e1: BoxShadow.lerpList(e1, other.e1, t)!,
      e2: BoxShadow.lerpList(e2, other.e2, t)!,
      e3: BoxShadow.lerpList(e3, other.e3, t)!,
    );
  }
}

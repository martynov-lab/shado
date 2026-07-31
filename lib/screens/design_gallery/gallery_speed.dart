/// Скорость воспроизведения — демонстрационные данные витрины: на ней
/// показываются переключатели, сегменты и модальный лист.
enum GallerySpeed {
  slow,
  normal,
  fast;

  String get label => switch (this) {
    GallerySpeed.slow => 'Медленно — 0.75×',
    GallerySpeed.normal => 'Обычно — 1.0×',
    GallerySpeed.fast => 'Быстро — 1.5×',
  };

  String get shortLabel => switch (this) {
    GallerySpeed.slow => '0.75×',
    GallerySpeed.normal => '1.0×',
    GallerySpeed.fast => '1.5×',
  };
}

/// Playback speed — demo data for the gallery.
enum GallerySpeed {
  slow,
  normal,
  fast;

  String get label => switch (this) {
    GallerySpeed.slow => 'Slow — 0.75×',
    GallerySpeed.normal => 'Normal — 1.0×',
    GallerySpeed.fast => 'Fast — 1.5×',
  };

  String get shortLabel => switch (this) {
    GallerySpeed.slow => '0.75×',
    GallerySpeed.normal => '1.0×',
    GallerySpeed.fast => '1.5×',
  };
}

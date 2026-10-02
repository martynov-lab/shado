/// Whether a lesson is kept on the device for offline study.
sealed class LessonDownload {
  const LessonDownload();
}

final class NotDownloaded extends LessonDownload {
  const NotDownloaded();
}

final class Downloading extends LessonDownload {
  const Downloading([this.progress]);

  /// Transferred part of the audio, `0..1`; `null` while unknown.
  final double? progress;
}

final class Downloaded extends LessonDownload {
  const Downloaded();
}

import 'package:flutter/foundation.dart';

import '../../../domain/entities/audio_trim.dart';
import '../../../domain/entities/audio_upload.dart';
import '../../../domain/entities/lesson_category.dart';
import '../../../domain/entities/segment_boundaries.dart';
import '../../widgets/segment_splitter/segment_boundary_math.dart' as marks;
import 'add_lesson_form_state.dart';

/// The lesson creation form: text, markers, trimming and the audio status.
/// Every change keeps the waveform boundaries in step with the text.
class AddLessonForm extends ValueNotifier<AddLessonFormState> {
  AddLessonForm() : super(const AddLessonFormState());

  void setTitle(String title) => value = value.copyWith(title: title);

  /// Changes the text and refits the layout.
  void setText(String text) {
    final next = value.copyWith(text: text);
    value = next.copyWith(boundaries: _fitBoundaries(next));
  }

  void setBoundaries(List<int> boundaries) =>
      value = value.copyWith(boundaries: boundaries);

  /// The marker-at-playhead checkbox next to the play button.
  void setMarkerAtPlayhead(bool enabled) =>
      value = value.copyWith(markerAtPlayhead: enabled);

  /// Puts marker [ordinal] into the text and its boundary on the waveform:
  /// at [playheadMs] when "marker at playhead" is on, otherwise right of the
  /// previous one.
  void insertMarker(String text, int ordinal, int playheadMs) {
    final boundaries = value.boundaries;
    final inSync = boundaries.length == value.segmentCount + 1;
    final next = value.copyWith(text: text);
    if (!inSync) {
      value = next.copyWith(boundaries: _fitBoundaries(next));
      return;
    }
    // The marker is placed inside the range that is kept.
    final span = AudioTrim(startMs: boundaries.first, endMs: boundaries.last);
    final ms = value.markerAtPlayhead
        ? playheadMs
        : SegmentBoundaries.afterPrevious(boundaries, ordinal);
    value = next.copyWith(
      boundaries: SegmentBoundaries.insertAt(boundaries, ordinal, ms, span),
    );
  }

  /// Removes marker [ordinal] from the text and its boundary from the wave.
  void removeMarker(int ordinal) {
    final indices = marks.markerIndices(value.text);
    if (ordinal < 1 || ordinal > indices.length) return;
    final nextText = marks.removeMarker(value.text, indices[ordinal - 1]);
    final boundaries = value.boundaries;
    final inSync = boundaries.length == value.segmentCount + 1;
    final next = value.copyWith(text: nextText);
    value = next.copyWith(
      boundaries: inSync && ordinal < boundaries.length - 1
          ? ([...boundaries]..removeAt(ordinal))
          : _fitBoundaries(next),
    );
  }

  void setAccent(String? accent) => value = value.copyWith(accent: accent);

  void setLevel(LessonLevel? level) => value = value.copyWith(level: level);

  void setPrivate(bool isPrivate) =>
      value = value.copyWith(isPublic: !isPrivate);

  /// `null` means no topic.
  void setTopic(String? topicId) => value = topicId == null
      ? value.copyWith(clearTopic: true)
      : value.copyWith(topicId: topicId);

  /// Drops the chosen topic when it is gone from the directory.
  void dropTopicUnless(Iterable<String> availableIds) {
    final selected = value.topicId;
    if (selected == null || availableIds.contains(selected)) return;
    value = value.copyWith(clearTopic: true);
  }

  void reset() => value = const AddLessonFormState();

  /// Enters trim mode and brings the whole file back into the window.
  void startTrim() {
    if (!value.hasWaveform || value.isTrimming) return;
    value = value.copyWith(pendingTrim: value.trim);
  }

  void updateTrim(AudioTrim trim) {
    if (!value.isTrimming) return;
    value = value.copyWith(pendingTrim: trim);
  }

  void cancelTrim() => value = value.copyWith(clearPendingTrim: true);

  /// Applies the trim, moving segment markers inside the new range.
  void applyTrim() {
    final pending = value.pendingTrim;
    if (pending == null) return;
    final next = value.copyWith(trim: pending, clearPendingTrim: true);
    value = next.copyWith(
      // Trimming keeps the segment count; only the markers move.
      boundaries: next.boundaries.length == next.segmentCount + 1
          ? SegmentBoundaries.refit(next.boundaries, next.trim)
          : _fitBoundaries(next),
    );
  }

  /// Forgets the current audio while a new file or a voice-over is coming.
  void startUpload(String fileName, {bool isSynthesis = false}) =>
      value = value.copyWith(
        clearAudio: true,
        audioFileName: fileName,
        durationMs: 0,
        trim: const AudioTrim.full(0),
        clearPendingTrim: true,
        boundaries: const [],
        isUploading: true,
        isSynthesizing: isSynthesis,
        uploadProgress: 0,
      );

  void setUploadProgress(double progress) =>
      value = value.copyWith(uploadProgress: progress);

  /// The new audio arrives untrimmed.
  void finishUpload(AudioUpload upload) {
    final next = value.copyWith(
      audioId: upload.audioId,
      audioPath: upload.localPath.isEmpty ? null : upload.localPath,
      durationMs: upload.durationMs,
      trim: AudioTrim.full(upload.durationMs),
      isUploading: false,
      isSynthesizing: false,
      uploadProgress: 1,
    );
    value = next.copyWith(boundaries: _fitBoundaries(next));
  }

  /// After a failure or a cancel: no audio.
  void dropUpload() => value = value.copyWith(
    isUploading: false,
    isSynthesizing: false,
    uploadProgress: 0,
    durationMs: 0,
    clearAudio: true,
  );

  void setSubmitting(bool submitting) =>
      value = value.copyWith(isSubmitting: submitting);

  List<int> _fitBoundaries(AddLessonFormState form) {
    if (form.durationMs <= 0 || form.segmentCount == 0) return const [];
    return SegmentBoundaries.resize(
      form.boundaries,
      form.segmentCount,
      form.trim,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../controllers/lesson_controller.dart';
import '../controllers/waveform_controller.dart';
import '../widgets/segment_tile.dart';
import '../widgets/waveform_editor.dart';

class LessonPage extends ConsumerWidget {
  const LessonPage({super.key, required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonAsync = ref.watch(lessonControllerProvider(lessonId));
    return Scaffold(
      appBar: AppBar(
        title: Text(lessonAsync.value?.lesson.title ?? 'Урок'),
      ),
      body: lessonAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('$error', textAlign: TextAlign.center),
          ),
        ),
        data: (state) => _LessonView(lessonId: lessonId, state: state),
      ),
    );
  }
}

class _LessonView extends ConsumerWidget {
  const _LessonView({required this.lessonId, required this.state});

  final String lessonId;
  final LessonState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(lessonControllerProvider(lessonId).notifier);
    final segments = state.lesson.segments;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SegmentedButton<double>(
            segments: const [
              ButtonSegment(value: kSlowSpeed, label: Text('Медленно')),
              ButtonSegment(value: kNormalSpeed, label: Text('Нормально')),
            ],
            selected: {state.speed},
            onSelectionChanged: (selection) =>
                controller.setSpeed(selection.first),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: segments.length,
            itemBuilder: (context, index) {
              final segment = segments[index];
              return SegmentTile(
                segment: segment,
                isActive: state.activeSegmentIndex == index,
                isPlaying: state.isSegmentPlaying(index),
                isLooped: state.isSegmentLooped(index),
                onPlayPressed: () => controller.togglePlay(index),
                onLoopPressed: () => controller.toggleLoop(index),
              );
            },
          ),
        ),
        _WaveformSection(lessonId: lessonId, state: state),
      ],
    );
  }
}

class _WaveformSection extends ConsumerWidget {
  const _WaveformSection({required this.lessonId, required this.state});

  final String lessonId;
  final LessonState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(lessonControllerProvider(lessonId).notifier);
    final peaksAsync = ref.watch(waveformPeaksProvider(state.lesson.audioPath));
    // Плеер отдаёт позицию внутри вырезанного куска — на волне её нужно
    // отложить от начала этого куска.
    final position = ref.watch(playbackPositionProvider(lessonId)).value;
    final activeIndex = state.activeSegmentIndex;
    final absolutePositionMs = activeIndex == null
        ? 0
        : state.lesson.segments[activeIndex].startMs +
              (position?.inMilliseconds ?? 0);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 152,
        child: peaksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Волна недоступна: $error',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          data: (peaks) => WaveformEditor(
            peaks: peaks,
            durationMs: state.lesson.durationMs,
            boundaries: state.lesson.boundaries,
            positionMs: absolutePositionMs,
            activeSegmentIndex: activeIndex,
            showCursor: activeIndex != null,
            height: 152,
            onBoundariesChanged: controller.updateBoundaries,
          ),
        ),
      ),
    );
  }
}

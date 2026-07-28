import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../controllers/lesson_controller.dart';
import '../widgets/segment_tile.dart';

class LessonPage extends ConsumerWidget {
  const LessonPage({super.key, required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonAsync = ref.watch(lessonControllerProvider(lessonId));
    return Scaffold(
      appBar: AppBar(
        title: Text(lessonAsync.value?.lesson.title ?? 'Урок'),
        actions: [
          IconButton(
            tooltip: 'Править разбивку',
            onPressed: lessonAsync.hasValue ? () => _edit(context, ref) : null,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
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

  /// Возврат с экрана правки: разбивка могла измениться целиком, поэтому урок
  /// перечитывается, а плеер сбрасывается.
  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final saved = await context.push<bool>('/lesson/$lessonId/edit');
    if (saved != true) return;
    await ref.read(lessonControllerProvider(lessonId).notifier).reload();
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
            padding: const EdgeInsets.only(bottom: 16),
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
      ],
    );
  }
}

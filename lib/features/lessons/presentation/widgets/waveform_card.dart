import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/waveform_datasource.dart';
import '../../domain/entities/audio_trim.dart';
import '../controllers/waveform_controller.dart';
import 'trim_bar.dart';
import 'waveform_editor.dart';

/// Карточка с волной аудио: сама тянет пики и показывает состояние загрузки.
///
/// Используется и на экране урока, и на экранах создания/правки — разметка
/// границ везде одна и та же.
///
/// Под карточкой при заданном [onTrimStart] появляется полоска обрезки: пока
/// [trim] пуст — одна кнопка «Обрезать», а в режиме обрезки — «Применить» и
/// «Отменить» рядом с длительностью того, что останется.
class WaveformCard extends ConsumerWidget {
  const WaveformCard({
    super.key,
    required this.audioId,
    required this.durationMs,
    required this.view,
    required this.boundaries,
    required this.onBoundariesChanged,
    this.onBoundaryRemoved,
    this.audioPath,
    this.onSeek,
    this.cachePeaks = true,
    this.positionMs = 0,
    this.activeSegmentIndex,
    this.showCursor = false,
    this.height = 168,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 16),
    this.trim,
    this.onTrimChanged,
    this.onTrimStart,
    this.onTrimApply,
    this.onTrimCancel,
  });

  /// Аудио на сервере: по нему приходят пики.
  final String audioId;

  /// Локальная копия файла, если она уже есть. Нужна только запасному пути,
  /// когда сервер недоступен.
  final String? audioPath;

  /// Длительность файла целиком: по ней разложены пики.
  final int durationMs;

  /// Отрезок файла, который показываем. В режиме обрезки — файл целиком,
  /// чтобы обрезанное можно было вернуть.
  final AudioTrim view;

  final List<int> boundaries;
  final ValueChanged<List<int>> onBoundariesChanged;

  /// Удаление внутренней метки по её индексу — двойным тапом. `null` — метки
  /// удалять нельзя.
  final ValueChanged<int>? onBoundaryRemoved;

  /// Задан — на волне появляется перетаскиваемый ползунок воспроизведения.
  final ValueChanged<int>? onSeek;

  /// Кеш пиков рядом с файлом уместен только для аудио, которое уже
  /// принадлежит приложению.
  final bool cachePeaks;

  final int positionMs;
  final int? activeSegmentIndex;
  final bool showCursor;
  final double height;
  final EdgeInsets margin;

  /// Отрезок, который останется после обрезки. `null` — обрезка не идёт.
  final AudioTrim? trim;

  final ValueChanged<AudioTrim>? onTrimChanged;

  /// Задан — под волной появляется кнопка «Обрезать».
  final VoidCallback? onTrimStart;

  final VoidCallback? onTrimApply;
  final VoidCallback? onTrimCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Для необрезанного файла отрезок не задаём: волна на весь файл — это тот
    // же ответ сервера, и переспрашивать её при каждом входе в режим обрезки
    // незачем.
    final peaksAsync = ref.watch(
      waveformPeaksProvider(
        WaveformQuery(
          audioId: audioId,
          localPath: audioPath,
          durationMs: durationMs,
          cache: cachePeaks,
          range: view.isTrimmedFrom(durationMs) ? view : null,
        ),
      ),
    );
    final card = Card(
      margin: margin,
      // Клип не ставим: волну со скруглением рисует сам painter, зато кружки
      // ручек границ могут выступать за верхний край карточки, как в макете.
      clipBehavior: Clip.none,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(kWaveCornerRadius)),
      ),
      child: SizedBox(
        height: height,
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
            view: view,
            boundaries: boundaries,
            positionMs: positionMs,
            activeSegmentIndex: activeSegmentIndex,
            showCursor: showCursor,
            height: height,
            onBoundariesChanged: onBoundariesChanged,
            onBoundaryRemoved: onBoundaryRemoved,
            onSeek: onSeek,
            trim: trim,
            onTrimChanged: onTrimChanged,
          ),
        ),
      ),
    );
    if (onTrimStart == null) return card;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card,
        Padding(
          padding: EdgeInsets.only(
            left: margin.left,
            right: margin.right,
            top: 8,
          ),
          child: TrimBar(
            trim: trim,
            isEnabled: peaksAsync.hasValue,
            onStartPressed: onTrimStart,
            onApplyPressed: onTrimApply,
            onCancelPressed: onTrimCancel,
          ),
        ),
      ],
    );
  }
}

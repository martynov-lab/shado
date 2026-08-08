import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/constants/app_constants.dart';
import 'package:shado/core/theme/app_theme.dart';
import 'package:shado/features/lessons/data/models/waveform_peaks.dart';
import 'package:shado/features/lessons/domain/entities/audio_trim.dart';
import 'package:shado/features/lessons/presentation/widgets/waveform_editor.dart';

void main() {
  const durationMs = 9000;
  const width = 400.0;
  const height = 160.0;
  const full = AudioTrim.full(durationMs);

  /// Ручка границы — кружок под шкалой времени, ручка ползунка — треугольник у
  /// нижнего края. Тесты берут метки ровно за них.
  const handleY = 22.0;
  const playheadHandleY = height - 7;

  /// Середина волны: здесь ручек нет, поэтому перетаскивание двигает волну.
  /// Там же лежат язычки меток обрезки — но только когда она включена.
  const bodyY = 80.0;

  /// Ровная волна: для проверки жестов форма пиков не важна.
  final peaks = WaveformPeaks(
    minima: List<double>.filled(100, -0.5),
    maxima: List<double>.filled(100, 0.5),
  );

  Future<void> pumpEditor(
    WidgetTester tester, {
    required List<int> boundaries,
    ValueChanged<List<int>>? onBoundariesChanged,
    ValueChanged<int>? onBoundaryRemoved,
    ValueChanged<int>? onSeek,
    int positionMs = 0,
    AudioTrim view = full,
    AudioTrim? trim,
    ValueChanged<AudioTrim>? onTrimChanged,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: width,
            height: height,
            child: WaveformEditor(
              peaks: peaks,
              view: view,
              boundaries: boundaries,
              positionMs: positionMs,
              showCursor: onSeek != null,
              height: height,
              onBoundariesChanged: onBoundariesChanged ?? (_) {},
              onBoundaryRemoved: onBoundaryRemoved,
              onSeek: onSeek,
              trim: trim,
              onTrimChanged: onTrimChanged,
            ),
          ),
        ),
      ),
    );
  }

  /// Ctrl + колесо мыши: масштаб меняется в `exp(-dy / 300)` раз, момент под
  /// курсором остаётся на месте.
  Future<void> ctrlWheel(WidgetTester tester, Offset at, double dy) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(at));
    await tester.sendEventToBinding(pointer.scroll(Offset(0, dy)));
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  }

  group('метки границ', () {
    testWidgets('тянутся за верхний кружок', (tester) async {
      List<int>? reported;
      await pumpEditor(
        tester,
        boundaries: const [0, 3000, 6000, 9000],
        onBoundariesChanged: (value) => reported = value,
      );

      // Метка 3000 мс стоит на x = 3000 / 9000 * 400.
      await tester.dragFrom(const Offset(133, handleY), const Offset(100, 0));
      await tester.pumpAndSettle();

      expect(reported, isNotNull);
      expect(reported!.first, 0);
      expect(reported!.last, durationMs);
      expect(reported![2], 6000);
      // 233 / 400 * 9000 ≈ 5243.
      expect(reported![1], closeTo(5243, 60));
    });

    testWidgets('за середину волны не тянутся', (tester) async {
      List<int>? reported;
      await pumpEditor(
        tester,
        boundaries: const [0, 3000, 6000, 9000],
        onBoundariesChanged: (value) => reported = value,
      );

      // Тот же x, но ниже кружка — это перетаскивание волны, не метки.
      await tester.dragFrom(const Offset(133, bodyY), const Offset(100, 0));
      await tester.pumpAndSettle();

      expect(reported, isNull);
    });

    testWidgets('крайние метки не двигаются', (tester) async {
      List<int>? reported;
      await pumpEditor(
        tester,
        boundaries: const [0, 4500, 9000],
        onBoundariesChanged: (value) => reported = value,
      );

      // Тянем от самого края: там только неподвижная граница 0.
      await tester.dragFrom(const Offset(2, handleY), const Offset(80, 0));
      await tester.pumpAndSettle();

      expect(reported, isNull);
    });
  });

  group('удаление метки', () {
    testWidgets('двойной тап по кружку сообщает индекс метки', (tester) async {
      int? removed;
      await pumpEditor(
        tester,
        boundaries: const [0, 3000, 6000, 9000],
        onBoundaryRemoved: (index) => removed = index,
      );

      // Кружок метки 3000 мс стоит на x = 133, у верхнего края волны.
      const at = Offset(133, handleY);
      await tester.tapAt(at);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(at);
      await tester.pumpAndSettle();

      expect(removed, 1);
    });

    testWidgets('двойной тап мимо кружка метку не трогает', (tester) async {
      int? removed;
      await pumpEditor(
        tester,
        boundaries: const [0, 3000, 6000, 9000],
        onBoundaryRemoved: (index) => removed = index,
      );

      // Тот же x, но по центру волны — ниже полосы захвата метки.
      const at = Offset(133, bodyY);
      await tester.tapAt(at);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(at);
      await tester.pumpAndSettle();

      expect(removed, isNull);
    });
  });

  group('масштаб и перетаскивание волны', () {
    testWidgets('Ctrl + колесо растягивает волну вокруг курсора', (
      tester,
    ) async {
      int? seeked;
      await pumpEditor(
        tester,
        boundaries: const [0, 9000],
        onSeek: (value) => seeked = value,
      );

      // Курсор в середине окна — под ним 4500 мс, там же и останется.
      await ctrlWheel(tester, const Offset(200, bodyY), -300);
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(200, bodyY));
      await tester.pumpAndSettle();
      expect(seeked, closeTo(4500, 60));

      // Правее курсора время теперь идёт вчетверо (e ≈ 2.72) медленнее.
      final zoom = math.exp(1);
      await tester.tapAt(const Offset(300, bodyY));
      await tester.pumpAndSettle();
      expect(seeked, closeTo(4500 + 100 / (width * zoom) * durationMs, 60));
    });

    testWidgets('перетаскивание волны сдвигает окно', (tester) async {
      int? seeked;
      await pumpEditor(
        tester,
        boundaries: const [0, 9000],
        onSeek: (value) => seeked = value,
      );

      await ctrlWheel(tester, const Offset(200, bodyY), -300);
      await tester.pumpAndSettle();

      // Тянем волну влево: под точкой x = 200 оказывается более позднее время.
      await tester.dragFrom(const Offset(200, bodyY), const Offset(-100, 0));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(200, bodyY));
      await tester.pumpAndSettle();

      // Волна поехала не на все 100 пикселей: первые kDragSlopDefault уходят
      // на распознавание жеста — до него ещё не известно, перетаскивание это
      // или тап.
      final zoom = math.exp(1);
      const pannedPixels = 100 - kDragSlopDefault;
      expect(
        seeked,
        closeTo(4500 + pannedPixels / (width * zoom) * durationMs, 40),
      );
    });

    testWidgets('щипок двумя пальцами растягивает волну', (tester) async {
      int? seeked;
      await pumpEditor(
        tester,
        boundaries: const [0, 9000],
        onSeek: (value) => seeked = value,
      );

      // Пальцы разъезжаются симметрично: центр (x = 200, он же 4500 мс) стоит
      // на месте, расстояние между ними растёт втрое.
      final first = await tester.startGesture(const Offset(150, bodyY));
      final second = await tester.startGesture(const Offset(250, bodyY));
      await first.moveTo(const Offset(50, bodyY));
      await second.moveTo(const Offset(350, bodyY));
      await first.up();
      await second.up();
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(300, bodyY));
      await tester.pumpAndSettle();
      expect(seeked, closeTo(4500 + 100 / (width * 3) * durationMs, 120));
    });

    testWidgets('на растянутой волне метка ставится точнее', (tester) async {
      List<int>? reported;
      await pumpEditor(
        tester,
        boundaries: const [0, 4500, 9000],
        onBoundariesChanged: (value) => reported = value,
      );

      // Растягиваем вокруг середины — метка 4500 мс остаётся на x = 200.
      await ctrlWheel(tester, const Offset(200, bodyY), -300);
      await tester.pumpAndSettle();

      await tester.dragFrom(const Offset(200, handleY), const Offset(40, 0));
      await tester.pumpAndSettle();

      expect(reported, isNotNull);
      // Те же 40 пикселей стоят во столько же раз меньше времени, во сколько
      // растянута волна: ~330 мс вместо 900.
      final zoom = math.exp(1);
      expect(
        reported![1] - 4500,
        closeTo(40 / (width * zoom) * durationMs, 60),
      );
    });
  });

  group('ползунок воспроизведения', () {
    testWidgets('тап по волне переносит ползунок', (tester) async {
      int? seeked;
      await pumpEditor(
        tester,
        boundaries: const [0, 9000],
        onSeek: (value) => seeked = value,
      );

      await tester.tapAt(const Offset(300, bodyY));
      await tester.pumpAndSettle();

      // 300 / 400 * 9000 = 6750.
      expect(seeked, closeTo(6750, 40));
    });

    testWidgets('тянется за нижний треугольник', (tester) async {
      int? seeked;
      await pumpEditor(
        tester,
        boundaries: const [0, 9000],
        positionMs: 2250,
        onSeek: (value) => seeked = value,
      );

      // Ползунок 2250 мс стоит на x = 100.
      await tester.dragFrom(
        const Offset(100, playheadHandleY),
        const Offset(80, 0),
      );
      await tester.pumpAndSettle();

      // 180 / 400 * 9000 = 4050.
      expect(seeked, closeTo(4050, 60));
    });

    testWidgets('за середину волны не тянется', (tester) async {
      int? seeked;
      await pumpEditor(
        tester,
        boundaries: const [0, 9000],
        positionMs: 2250,
        onSeek: (value) => seeked = value,
      );

      await tester.dragFrom(const Offset(100, bodyY), const Offset(80, 0));
      await tester.pumpAndSettle();

      expect(seeked, isNull);
    });

    testWidgets('без onSeek волна ползунком не управляет', (tester) async {
      int? seeked;
      await pumpEditor(tester, boundaries: const [0, 9000]);

      await tester.tapAt(const Offset(300, bodyY));
      await tester.pumpAndSettle();

      expect(seeked, isNull);
    });

    testWidgets('ручки границы и ползунка не мешают друг другу', (
      tester,
    ) async {
      List<int>? reported;
      int? seeked;
      await pumpEditor(
        tester,
        boundaries: const [0, 3000, 6000, 9000],
        positionMs: 3000,
        onBoundariesChanged: (value) => reported = value,
        onSeek: (value) => seeked = value,
      );

      // Обе ручки на x = 133, но по вертикали разведены: сверху — граница.
      await tester.dragFrom(const Offset(133, handleY), const Offset(60, 0));
      await tester.pumpAndSettle();
      expect(seeked, isNull);
      expect(reported?[1], greaterThan(3000));

      // Снизу — ползунок.
      await tester.dragFrom(
        const Offset(133, playheadHandleY),
        const Offset(60, 0),
      );
      await tester.pumpAndSettle();
      expect(seeked, greaterThan(3000));
    });
  });

  group('обрезка', () {
    /// Язычок левой метки стоит справа от неё, правой — слева; оба на середине
    /// волны, поэтому берут их около [bodyY].
    const leftHandleX = 7.5;
    const rightHandleX = width - 7.5;

    testWidgets('левая метка тянется за язычок', (tester) async {
      AudioTrim? reported;
      await pumpEditor(
        tester,
        boundaries: const [0, 4500, 9000],
        trim: full,
        onTrimChanged: (value) => reported = value,
      );

      await tester.dragFrom(
        const Offset(leftHandleX, bodyY),
        const Offset(100, 0),
      );
      await tester.pumpAndSettle();

      expect(reported, isNotNull);
      expect(reported!.endMs, durationMs);
      // 107.5 / 400 * 9000 ≈ 2419.
      expect(reported!.startMs, closeTo(2419, 60));
    });

    testWidgets('правая метка тянется за язычок', (tester) async {
      AudioTrim? reported;
      await pumpEditor(
        tester,
        boundaries: const [0, 4500, 9000],
        trim: full,
        onTrimChanged: (value) => reported = value,
      );

      await tester.dragFrom(
        const Offset(rightHandleX, bodyY),
        const Offset(-100, 0),
      );
      await tester.pumpAndSettle();

      expect(reported, isNotNull);
      expect(reported!.startMs, 0);
      // 292.5 / 400 * 9000 ≈ 6581.
      expect(reported!.endMs, closeTo(6581, 60));
    });

    testWidgets('метки не сходятся ближе kMinTrimMs', (tester) async {
      AudioTrim? reported;
      await pumpEditor(
        tester,
        boundaries: const [0, 4500, 9000],
        trim: full,
        onTrimChanged: (value) => reported = value,
      );

      // Тянем левую метку через всю волну — она упрётся в правую.
      await tester.dragFrom(
        const Offset(leftHandleX, bodyY),
        const Offset(width, 0),
      );
      await tester.pumpAndSettle();

      expect(reported, isNotNull);
      expect(reported!.startMs, durationMs - kMinTrimMs);
    });

    testWidgets('пока идёт обрезка, метки границ кусков не двигаются', (
      tester,
    ) async {
      List<int>? reported;
      await pumpEditor(
        tester,
        boundaries: const [0, 3000, 6000, 9000],
        trim: full,
        onBoundariesChanged: (value) => reported = value,
        onTrimChanged: (_) {},
      );

      // Тот же жест, что двигает метку в обычном режиме.
      await tester.dragFrom(const Offset(133, handleY), const Offset(100, 0));
      await tester.pumpAndSettle();

      expect(reported, isNull);
    });

    testWidgets('обрезанная дорожка занимает окно целиком', (tester) async {
      int? seeked;
      await pumpEditor(
        tester,
        boundaries: const [1000, 8000],
        view: const AudioTrim(startMs: 1000, endMs: 8000),
        onSeek: (value) => seeked = value,
      );

      // Левый край окна — начало обрезки, правый — её конец.
      await tester.tapAt(const Offset(0, bodyY));
      await tester.pumpAndSettle();
      expect(seeked, closeTo(1000, 40));

      await tester.tapAt(const Offset(width - 1, bodyY));
      await tester.pumpAndSettle();
      expect(seeked, closeTo(8000, 40));
    });
  });
}

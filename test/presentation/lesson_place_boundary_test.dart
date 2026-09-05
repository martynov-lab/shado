import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/presentation/controllers/add_lesson_controller.dart';

/// Where the paired boundary lands, per the marker-at-playhead flag.
void main() {
  /// Prepares the form with text and matching markers.
  AddLessonController prime(
    ProviderContainer container, {
    required String text,
    required List<int> boundaries,
    bool markerAtPlayhead = false,
  }) {
    final controller = container.read(addLessonControllerProvider.notifier);
    controller.setText(text);
    controller.setBoundaries(boundaries);
    controller.setMarkerAtPlayhead(markerAtPlayhead);
    return controller;
  }

  group('флажок стоит', () {
    test('метка текста встаёт в позицию плеера', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = prime(
        container,
        text: 'one two three',
        boundaries: const [0, 9000],
        markerAtPlayhead: true,
      );

      controller.insertMarker('one two | three', 1, 2000);

      final state = container.read(addLessonControllerProvider);
      expect(state.boundaries, [0, 2000, 9000]);
      expect(state.text, 'one two | three');
      expect(state.segmentCount, 2);
    });

    test('следующая метка встаёт правее, сохраняя прежние', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = prime(
        container,
        text: 'one two three four',
        boundaries: const [0, 9000],
        markerAtPlayhead: true,
      );

      controller.insertMarker('one two | three four', 1, 2000);
      controller.insertMarker('one two | three | four', 2, 6000);

      final state = container.read(addLessonControllerProvider);
      expect(state.boundaries, [0, 2000, 6000, 9000]);
    });

    test('метка внутрь готовой разметки не двигает метки правее', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = prime(
        container,
        text: 'one two | three | four',
        boundaries: const [0, 3000, 6000, 9000],
        markerAtPlayhead: true,
      );

      // The marker went into the first segment; the ones on the right stayed.
      controller.insertMarker('one | two | three | four', 1, 1500);

      final state = container.read(addLessonControllerProvider);
      expect(state.boundaries, [0, 1500, 3000, 6000, 9000]);
    });

    test('перед последней меткой новая встаёт вплотную к ней', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = prime(
        container,
        text: 'one two three four',
        boundaries: const [0, 9000],
        markerAtPlayhead: true,
      );

      // The second marker keeps a gap after the first instead of jumping it.
      controller.insertMarker('one two | three four', 1, 5000);
      controller.insertMarker('one two | three | four', 2, 0);

      final state = container.read(addLessonControllerProvider);
      expect(state.boundaries, [0, 5000, 5200, 9000]);
    });
  });

  group('флажок снят', () {
    test('первая метка встаёт чуть правее начала, а не под ползунок', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = prime(
        container,
        text: 'one two three',
        boundaries: const [0, 9000],
      );

      controller.insertMarker('one two | three', 1, 2000);

      final state = container.read(addLessonControllerProvider);
      expect(state.boundaries, [0, 200, 9000]);
    });

    test('следующие метки копятся правее самой правой', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = prime(
        container,
        text: 'one two three four',
        boundaries: const [0, 9000],
      );

      controller.insertMarker('one two | three four', 1, 2000);
      controller.insertMarker('one two | three | four', 2, 6000);

      final state = container.read(addLessonControllerProvider);
      expect(state.boundaries, [0, 200, 400, 9000]);
    });

    test('метка внутрь готовой разметки не двигает метки правее', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = prime(
        container,
        text: 'one two | three | four',
        boundaries: const [0, 3000, 6000, 9000],
      );

      controller.insertMarker('one | two | three | four', 1, 8000);

      final state = container.read(addLessonControllerProvider);
      expect(state.boundaries, [0, 200, 3000, 6000, 9000]);
    });
  });
}

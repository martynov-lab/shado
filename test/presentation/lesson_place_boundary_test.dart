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

  group('checkbox on', () {
    test('the text marker lands at the player position', () {
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

    test('the next marker lands further right, keeping the earlier ones', () {
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

    test('a marker inside finished markup does not move the markers to its right', () {
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

    test('before the last marker a new one lands right next to it', () {
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

  group('checkbox off', () {
    test('the first marker lands slightly right of the start, not under the slider', () {
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

    test('further markers pile up to the right of the rightmost one', () {
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

    test('a marker inside finished markup does not move the markers to its right', () {
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

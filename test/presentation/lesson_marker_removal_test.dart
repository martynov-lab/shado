import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/presentation/controllers/add_lesson_controller.dart';

/// Paired marker removal: the delimiter and its boundary on the waveform.
void main() {
  /// Prepares the form with text and matching markers.
  AddLessonController prime(
    ProviderContainer container, {
    required String text,
    required List<int> boundaries,
  }) {
    final controller = container.read(addLessonControllerProvider.notifier);
    controller.setText(text);
    controller.setBoundaries(boundaries);
    return controller;
  }

  test('убирает первый разделитель и парную границу №1', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = prime(
      container,
      text: 'one | two | three',
      boundaries: const [0, 3000, 6000, 9000],
    );

    controller.removeMarker(1);

    final state = container.read(addLessonControllerProvider);
    expect(state.text, 'one two | three');
    // Boundary 1 (3000) was removed; 6000 and 9000 stayed in place.
    expect(state.boundaries, [0, 6000, 9000]);
    expect(state.segmentCount, 2);
  });

  test('вторую метку убирает, не трогая первую', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = prime(
      container,
      text: 'one | two | three',
      boundaries: const [0, 3000, 6000, 9000],
    );

    controller.removeMarker(2);

    final state = container.read(addLessonControllerProvider);
    expect(state.text, 'one | two three');
    expect(state.boundaries, [0, 3000, 9000]);
    expect(state.segmentCount, 2);
  });

  test('номер вне диапазона ничего не меняет', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = prime(
      container,
      text: 'one | two',
      boundaries: const [0, 4500, 9000],
    );

    controller.removeMarker(2); // there is only one marker
    controller.removeMarker(0);

    final state = container.read(addLessonControllerProvider);
    expect(state.text, 'one | two');
    expect(state.boundaries, [0, 4500, 9000]);
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/presentation/controllers/add_lesson_controller.dart';

/// Парное удаление метки: убрать №k — значит убрать и k-й разделитель в тексте,
/// и границу `boundaries[k]` на волне, не трогая остальные границы.
///
/// Проверяем на контроллере создания: экран правки использует ровно тот же
/// алгоритм `removeMarker`, но его контроллер поднимает реальный плеер и в
/// юнит-тесте без платформы не заводится.
void main() {
  /// Готовит форму с текстом и согласованной с ним разметкой. Аудио не грузим —
  /// границы ставим напрямую, они и так согласованы с числом сегментов.
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
    // Убрали границу №1 (3000); 6000 и 9000 остались на местах.
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

    controller.removeMarker(2); // метка всего одна
    controller.removeMarker(0);

    final state = container.read(addLessonControllerProvider);
    expect(state.text, 'one | two');
    expect(state.boundaries, [0, 4500, 9000]);
  });
}

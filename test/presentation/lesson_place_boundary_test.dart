import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/presentation/controllers/add_lesson_controller.dart';

/// Расстановка меток на слух: кнопка сажает следующую по счёту внутреннюю метку
/// в текущую позицию плеера. Метки идут по очереди слева направо, а если плеер
/// оказался перед уже проставленной — новая встаёт вплотную к ней.
///
/// Проверяем на контроллере создания: экран правки использует ровно тот же
/// алгоритм `placeBoundaryAtPlayhead`, но его контроллер поднимает реальный
/// плеер и в юнит-тесте без платформы не заводится.
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

  test('ставит метки по очереди в позицию плеера', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = prime(
      container,
      text: 'one | two | three',
      boundaries: const [0, 3000, 6000, 9000],
    );

    controller.placeBoundaryAtPlayhead(2000);
    controller.placeBoundaryAtPlayhead(6000);

    final state = container.read(addLessonControllerProvider);
    expect(state.boundaries, [0, 2000, 6000, 9000]);
    expect(state.placedBoundaryCount, 2);
  });

  test('перед уже проставленной метка встаёт вплотную к ней', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = prime(
      container,
      text: 'one | two | three',
      boundaries: const [0, 3000, 6000, 9000],
    );

    controller.placeBoundaryAtPlayhead(5000); // метка №1 в 5000
    controller.placeBoundaryAtPlayhead(3000); // плеер раньше метки №1

    final state = container.read(addLessonControllerProvider);
    // Метка №2 не перескочила через №1, а прижалась к ней с зазором.
    expect(state.boundaries, [0, 5000, 5200, 9000]);
  });

  test('когда все метки расставлены, кнопка больше не срабатывает', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = prime(
      container,
      text: 'one | two | three',
      boundaries: const [0, 3000, 6000, 9000],
    );

    controller.placeBoundaryAtPlayhead(2000);
    controller.placeBoundaryAtPlayhead(6000);
    final before = container.read(addLessonControllerProvider).boundaries;

    controller.placeBoundaryAtPlayhead(7000); // внутренних меток больше нет

    final state = container.read(addLessonControllerProvider);
    expect(state.canPlaceBoundary, isFalse);
    expect(state.boundaries, before);
  });

  test('смена текста начинает расстановку заново', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = prime(
      container,
      text: 'one | two | three',
      boundaries: const [0, 3000, 6000, 9000],
    );

    controller.placeBoundaryAtPlayhead(2000);
    expect(container.read(addLessonControllerProvider).placedBoundaryCount, 1);

    controller.setText('one | two | three | four');

    expect(container.read(addLessonControllerProvider).placedBoundaryCount, 0);
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/presentation/controllers/add_lesson_controller.dart';

/// Разметка на слух: добавили метку в тексте — парная граница встаёт в текущую
/// позицию плеера. Метки идут по тексту слева направо, а если плеер оказался
/// перед предыдущей меткой (аудио ещё не играли — ползунок в самом начале),
/// новая встаёт вплотную к ней.
///
/// Проверяем на контроллере создания: экран правки использует тот же
/// `insertMarker`, но его контроллер поднимает реальный плеер и в юнит-тесте без
/// платформы не заводится.
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

  test('метка текста встаёт в позицию плеера', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = prime(
      container,
      text: 'one two three',
      boundaries: const [0, 9000],
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
    );

    controller.insertMarker('one two | three four', 1, 2000);
    controller.insertMarker('one two | three | four', 2, 6000);

    final state = container.read(addLessonControllerProvider);
    expect(state.boundaries, [0, 2000, 6000, 9000]);
  });

  test('перед последней меткой новая встаёт вплотную к ней', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = prime(
      container,
      text: 'one two three four',
      boundaries: const [0, 9000],
    );

    // Метку №1 поставили в 5000, ползунок вернулся в начало (0) — метка №2 не
    // перескочила через №1, а прижалась к ней с зазором.
    controller.insertMarker('one two | three four', 1, 5000);
    controller.insertMarker('one two | three | four', 2, 0);

    final state = container.read(addLessonControllerProvider);
    expect(state.boundaries, [0, 5000, 5200, 9000]);
  });
}

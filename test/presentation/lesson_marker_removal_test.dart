import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/presentation/screens/add_lesson/add_lesson_form.dart';

/// Paired marker removal: the delimiter and its boundary on the waveform.
void main() {
  /// Prepares the form with text and matching markers.
  AddLessonForm prime({required String text, required List<int> boundaries}) {
    final form = AddLessonForm()
      ..setText(text)
      ..setBoundaries(boundaries);
    addTearDown(form.dispose);
    return form;
  }

  test('removes the first separator and its paired boundary #1', () {
    final form = prime(
      text: 'one | two | three',
      boundaries: const [0, 3000, 6000, 9000],
    );

    form.removeMarker(1);

    final state = form.value;
    expect(state.text, 'one two | three');
    // Boundary 1 (3000) was removed; 6000 and 9000 stayed in place.
    expect(state.boundaries, [0, 6000, 9000]);
    expect(state.segmentCount, 2);
  });

  test('removes the second marker without touching the first', () {
    final form = prime(
      text: 'one | two | three',
      boundaries: const [0, 3000, 6000, 9000],
    );

    form.removeMarker(2);

    final state = form.value;
    expect(state.text, 'one | two three');
    expect(state.boundaries, [0, 3000, 9000]);
    expect(state.segmentCount, 2);
  });

  test('an ordinal out of range changes nothing', () {
    final form = prime(text: 'one | two', boundaries: const [0, 4500, 9000]);

    form.removeMarker(2); // there is only one marker
    form.removeMarker(0);

    final state = form.value;
    expect(state.text, 'one | two');
    expect(state.boundaries, [0, 4500, 9000]);
  });
}

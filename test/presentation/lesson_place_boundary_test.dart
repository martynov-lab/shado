import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/presentation/screens/add_lesson/add_lesson_form.dart';

/// Where the paired boundary lands, per the marker-at-playhead flag.
void main() {
  /// Prepares the form with text and matching markers.
  AddLessonForm prime({
    required String text,
    required List<int> boundaries,
    bool markerAtPlayhead = false,
  }) {
    final form = AddLessonForm()
      ..setText(text)
      ..setBoundaries(boundaries);
    form.setMarkerAtPlayhead(markerAtPlayhead);
    addTearDown(form.dispose);
    return form;
  }

  group('checkbox on', () {
    test('the text marker lands at the player position', () {
      final form = prime(
        text: 'one two three',
        boundaries: const [0, 9000],
        markerAtPlayhead: true,
      );

      form.insertMarker('one two | three', 1, 2000);

      final state = form.value;
      expect(state.boundaries, [0, 2000, 9000]);
      expect(state.text, 'one two | three');
      expect(state.segmentCount, 2);
    });

    test('the next marker lands further right, keeping the earlier ones', () {
      final form = prime(
        text: 'one two three four',
        boundaries: const [0, 9000],
        markerAtPlayhead: true,
      );

      form.insertMarker('one two | three four', 1, 2000);
      form.insertMarker('one two | three | four', 2, 6000);

      final state = form.value;
      expect(state.boundaries, [0, 2000, 6000, 9000]);
    });

    test(
      'a marker inside finished markup does not move the markers to its right',
      () {
        final form = prime(
          text: 'one two | three | four',
          boundaries: const [0, 3000, 6000, 9000],
          markerAtPlayhead: true,
        );

        // The marker went into the first segment; the ones on the right stayed.
        form.insertMarker('one | two | three | four', 1, 1500);

        final state = form.value;
        expect(state.boundaries, [0, 1500, 3000, 6000, 9000]);
      },
    );

    test('before the last marker a new one lands right next to it', () {
      final form = prime(
        text: 'one two three four',
        boundaries: const [0, 9000],
        markerAtPlayhead: true,
      );

      // The second marker keeps a gap after the first instead of jumping it.
      form.insertMarker('one two | three four', 1, 5000);
      form.insertMarker('one two | three | four', 2, 0);

      final state = form.value;
      expect(state.boundaries, [0, 5000, 5200, 9000]);
    });
  });

  group('checkbox off', () {
    test(
      'the first marker lands slightly right of the start, not under the slider',
      () {
        final form = prime(text: 'one two three', boundaries: const [0, 9000]);

        form.insertMarker('one two | three', 1, 2000);

        final state = form.value;
        expect(state.boundaries, [0, 200, 9000]);
      },
    );

    test('further markers pile up to the right of the rightmost one', () {
      final form = prime(
        text: 'one two three four',
        boundaries: const [0, 9000],
      );

      form.insertMarker('one two | three four', 1, 2000);
      form.insertMarker('one two | three | four', 2, 6000);

      final state = form.value;
      expect(state.boundaries, [0, 200, 400, 9000]);
    });

    test(
      'a marker inside finished markup does not move the markers to its right',
      () {
        final form = prime(
          text: 'one two | three | four',
          boundaries: const [0, 3000, 6000, 9000],
        );

        form.insertMarker('one | two | three | four', 1, 8000);

        final state = form.value;
        expect(state.boundaries, [0, 200, 3000, 6000, 9000]);
      },
    );
  });
}

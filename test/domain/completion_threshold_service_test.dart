import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/error/failures.dart';
import 'package:shado/features/settings/domain/repositories/server_settings_repository.dart';
import 'package:shado/features/settings/domain/services/completion_threshold_service.dart';

class _FakeServerSettings implements ServerSettingsRepository {
  final List<int> saved = [];

  @override
  Future<int> getCompletionReps() async => 10;

  @override
  Future<int> setCompletionReps(int reps) async {
    saved.add(reps);
    return reps;
  }
}

void main() {
  ({CompletionThresholdService service, _FakeServerSettings settings}) build() {
    final settings = _FakeServerSettings();
    final service = CompletionThresholdService(settings);
    addTearDown(service.dispose);
    return (service: service, settings: settings);
  }

  test('a threshold outside 1..1000 is rejected before the network', () async {
    final env = build();

    await expectLater(env.service.save(0), throwsA(isA<ValidationFailure>()));
    await expectLater(
      env.service.save(1001),
      throwsA(isA<ValidationFailure>()),
    );
    expect(env.settings.saved, isEmpty);
  });

  test('a valid threshold is saved and becomes the current one', () async {
    final env = build();
    final changes = <int>[];
    env.service.changes.listen(changes.add);

    await env.service.save(15);
    await pumpEventQueue();

    expect(env.settings.saved, equals([15]));
    expect(env.service.reps, equals(15));
    expect(changes, equals([15]));
  });
}

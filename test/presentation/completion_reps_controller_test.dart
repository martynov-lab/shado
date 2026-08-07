import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/progress/presentation/controllers/progress_providers.dart';
import 'package:shado/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:shado/features/settings/presentation/controllers/completion_reps_controller.dart';

class _FakeSettings implements SettingsRemoteDataSource {
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
  ({ProviderContainer container, _FakeSettings settings}) build() {
    final settings = _FakeSettings();
    final container = ProviderContainer(
      overrides: [
        settingsRemoteDataSourceProvider.overrideWithValue(settings),
      ],
    );
    addTearDown(container.dispose);
    return (container: container, settings: settings);
  }

  test('порог вне 1..1000 отвергается до сети', () async {
    final env = build();
    final controller = env.container.read(
      completionRepsControllerProvider.notifier,
    );

    expect(await controller.save(0), isNotNull);
    expect(await controller.save(1001), isNotNull);
    expect(env.settings.saved, isEmpty);
  });

  test('корректный порог уходит в датасорс', () async {
    final env = build();
    final controller = env.container.read(
      completionRepsControllerProvider.notifier,
    );

    expect(await controller.save(15), isNull);
    expect(env.settings.saved, [15]);
  });
}

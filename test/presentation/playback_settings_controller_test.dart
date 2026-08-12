import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/constants/app_constants.dart';
import 'package:shado/features/settings/presentation/controllers/playback_settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  test('без сохранённого — значения по умолчанию', () async {
    final container = makeContainer();
    final settings = await container.read(
      playbackSettingsControllerProvider.future,
    );

    expect(settings.defaultSpeed, kNormalSpeed);
    expect(settings.repeatsInCycle, kDefaultRepeatsInCycle);
    expect(settings.pauseBetweenRepeats, isTrue);
    expect(settings.countdownEnabled, isFalse);
  });

  test('выбор скорости применяется сразу и переживает перезапуск', () async {
    final container = makeContainer();
    await container.read(playbackSettingsControllerProvider.future);
    await container
        .read(playbackSettingsControllerProvider.notifier)
        .setDefaultSpeed(1.25);

    expect(
      container.read(playbackSettingsControllerProvider).value?.defaultSpeed,
      1.25,
    );

    // «Перезапуск»: свежий контейнер читает уже сохранённое значение.
    final restarted = makeContainer();
    final restored = await restarted.read(
      playbackSettingsControllerProvider.future,
    );
    expect(restored.defaultSpeed, 1.25);
  });

  test('число повторов зажимается в допустимые границы', () async {
    final container = makeContainer();
    await container.read(playbackSettingsControllerProvider.future);
    final controller = container.read(
      playbackSettingsControllerProvider.notifier,
    );

    await controller.setRepeatsInCycle(999);
    expect(
      container.read(playbackSettingsControllerProvider).value?.repeatsInCycle,
      kMaxRepeatsInCycle,
    );

    await controller.setRepeatsInCycle(0);
    expect(
      container.read(playbackSettingsControllerProvider).value?.repeatsInCycle,
      kMinRepeatsInCycle,
    );
  });

  test('тумблеры паузы и отсчёта сохраняются между запусками', () async {
    final container = makeContainer();
    await container.read(playbackSettingsControllerProvider.future);
    final controller = container.read(
      playbackSettingsControllerProvider.notifier,
    );

    await controller.setPauseBetweenRepeats(false);
    await controller.setCountdownEnabled(true);

    final restarted = makeContainer();
    final restored = await restarted.read(
      playbackSettingsControllerProvider.future,
    );
    expect(restored.pauseBetweenRepeats, isFalse);
    expect(restored.countdownEnabled, isTrue);
  });
}

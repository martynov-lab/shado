import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/constants/app_constants.dart';
import 'package:shado/features/settings/data/repositories/playback_settings_repository_impl.dart';
import 'package:shado/features/settings/domain/entities/playback_settings.dart';
import 'package:shado/features/settings/domain/services/playback_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  PlaybackSettingsService makeService() {
    final service = PlaybackSettingsService(PlaybackSettingsRepositoryImpl());
    addTearDown(service.dispose);
    return service;
  }

  test('with nothing saved the defaults apply', () async {
    final settings = await makeService().load();

    expect(settings.defaultSpeed, kNormalSpeed);
    expect(settings.repeatsInCycle, kDefaultRepeatsInCycle);
    expect(settings.pauseBetweenRepeats, isTrue);
    expect(settings.countdownEnabled, isFalse);
  });

  test('the chosen speed applies at once and survives a restart', () async {
    final service = makeService();
    await service.load();
    final changes = <PlaybackSettings>[];
    service.changes.listen(changes.add);

    await service.setDefaultSpeed(1.25);
    await pumpEventQueue();

    expect(service.settings.defaultSpeed, 1.25);
    expect(changes.single.defaultSpeed, 1.25);

    final restored = await makeService().load();
    expect(restored.defaultSpeed, 1.25);
  });

  test('the repeat count is clamped to the allowed range', () async {
    final service = makeService();
    await service.load();

    await service.setRepeatsInCycle(999);
    expect(service.settings.repeatsInCycle, kMaxRepeatsInCycle);

    await service.setRepeatsInCycle(0);
    expect(service.settings.repeatsInCycle, kMinRepeatsInCycle);
  });

  test('the pause and countdown switches persist between runs', () async {
    final service = makeService();
    await service.load();

    await service.setPauseBetweenRepeats(false);
    await service.setCountdownEnabled(true);

    final restored = await makeService().load();
    expect(restored.pauseBetweenRepeats, isFalse);
    expect(restored.countdownEnabled, isTrue);
  });
}

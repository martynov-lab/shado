// Builds the Android arm64 APK and sends it to the Telegram bot.
// Usage: dart run installer/build_release_android.dart [--no-send]
import 'dart:io';

import 'release_utils.dart';

Future<void> main(List<String> args) async {
  final send = !args.contains('--no-send');
  await buildAndroid(bot: send ? TelegramBot.fromEnvFile() : null);
}

/// Builds the arm64 APK into `build/release` and sends it via [bot] when given.
Future<void> buildAndroid({TelegramBot? bot}) async {
  final version = readVersion();
  // The universal APK exceeds the 50 MB Bot API limit, so only the arm64 split is shipped.
  await run('flutter', ['build', 'apk', '--release', '--split-per-abi'], error: 'flutter build apk failed');

  final source = File(repoPath(['build', 'app', 'outputs', 'flutter-apk', 'app-arm64-v8a-release.apk']));
  if (!source.existsSync()) fail('APK not found: ${source.path}');
  final apk = source.copySync(releasePath('Shado-$version-android-arm64.apk'));

  if (bot == null) {
    stdout.writeln('Built: ${apk.path} (sending skipped: --no-send)');
    return;
  }
  await bot.sendRelease(apk, version: version);
}

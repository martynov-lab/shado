// Builds the macOS release, zips the .app and sends it to the Telegram bot.
// Usage: dart run installer/build_release_macos.dart [--no-send]
import 'dart:io';

import 'release_utils.dart';

Future<void> main(List<String> args) async {
  final send = !args.contains('--no-send');
  await buildMacos(bot: send ? TelegramBot.fromEnvFile() : null);
}

/// Builds `build/release/Shado-<version>-macos.zip` and sends it via [bot] when given.
Future<void> buildMacos({TelegramBot? bot}) async {
  if (!Platform.isMacOS) fail('The macOS build can only be built on macOS.');

  final version = readVersion();
  await run('flutter', ['build', 'macos', '--release'], error: 'flutter build macos failed');

  final app = Directory(repoPath(['build', 'macos', 'Build', 'Products', 'Release', 'shado.app']));
  if (!app.existsSync()) fail('Release build not found: ${app.path}');
  final zip = File(releasePath('Shado-$version-macos.zip'));
  if (zip.existsSync()) zip.deleteSync();
  // ditto keeps the framework symlinks inside the .app bundle intact.
  await run('ditto', ['-c', '-k', '--keepParent', app.path, zip.path], error: 'ditto failed');

  if (bot == null) {
    stdout.writeln('Built: ${zip.path} (sending skipped: --no-send)');
    return;
  }
  await bot.sendRelease(
    zip,
    version: version,
    note: 'The build is not notarized. After unpacking: xattr -dr com.apple.quarantine shado.app',
  );
}

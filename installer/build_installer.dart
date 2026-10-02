// Release orchestrator: builds the current desktop platform and Android.
// Usage: dart run installer/build_installer.dart [--target=all|android|windows|macos] [--no-send]
import 'dart:io';

import 'build_release_android.dart' show buildAndroid;
import 'build_release_macos.dart' show buildMacos;
import 'build_release_windows.dart' show buildWindows;
import 'release_utils.dart';

const _usage = 'Usage: dart run installer/build_installer.dart '
    '[--target=all|android|windows|macos] [--no-send]';

Future<void> main(List<String> args) async {
  var target = 'all';
  var send = true;
  for (final arg in args) {
    switch (arg) {
      case '--no-send':
        send = false;
      case final value when value.startsWith('--target='):
        target = value.substring('--target='.length);
      default:
        fail('Unknown argument: $arg\n$_usage');
    }
  }
  if (!const {'all', 'android', 'windows', 'macos'}.contains(target)) {
    fail('Unknown target: $target\n$_usage');
  }

  final desktop = Platform.isWindows ? 'windows' : (Platform.isMacOS ? 'macos' : null);
  final buildDesktop = target == 'all' ? desktop : (target == 'android' ? null : target);
  final buildsAndroid = target == 'all' || target == 'android';
  if (target == 'all' && desktop == null) {
    stdout.writeln('Desktop build for ${Platform.operatingSystem} is not supported — Android only.');
  }

  // Secrets are read before building so a missing file fails fast.
  final needsBot = send && (buildsAndroid || buildDesktop == 'macos');
  final bot = needsBot ? TelegramBot.fromEnvFile() : null;

  switch (buildDesktop) {
    case 'windows':
      await buildWindows();
    case 'macos':
      await buildMacos(bot: bot);
  }
  if (buildsAndroid) await buildAndroid(bot: bot);
}

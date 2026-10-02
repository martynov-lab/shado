// Builds the Windows release and packs it into an Inno Setup installer.
// Usage: dart run installer/build_release_windows.dart [--skip-flutter-build]
import 'dart:io';

import 'release_utils.dart';

Future<void> main(List<String> args) async {
  await buildWindows(skipFlutterBuild: args.contains('--skip-flutter-build'));
}

/// Builds `build/release/Shado-<version>-windows-x64-setup.exe`.
Future<void> buildWindows({bool skipFlutterBuild = false}) async {
  if (!Platform.isWindows) fail('The Windows installer can only be built on Windows.');

  final env = Platform.environment;
  final iscc = [
    if (env['LOCALAPPDATA'] case final dir?) '$dir\\Programs\\Inno Setup 6\\ISCC.exe',
    if (env['ProgramFiles(x86)'] case final dir?) '$dir\\Inno Setup 6\\ISCC.exe',
    if (env['ProgramFiles'] case final dir?) '$dir\\Inno Setup 6\\ISCC.exe',
  ].where((path) => File(path).existsSync()).firstOrNull;
  if (iscc == null) fail('ISCC.exe not found. winget install --id JRSoftware.InnoSetup');

  final version = readVersion();
  if (!skipFlutterBuild) {
    await run('flutter', ['build', 'windows', '--release'], error: 'flutter build windows failed');
  }
  if (!File(repoPath(['build', 'windows', 'x64', 'runner', 'Release', 'shado.exe'])).existsSync()) {
    fail('Release build not found');
  }

  await run(iscc, ['/DAppVersion=$version', repoPath(['installer', 'shado.iss'])], error: 'ISCC failed');
  stdout.writeln('Installer: ${releasePath('Shado-$version-windows-x64-setup.exe')}');
}

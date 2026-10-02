// Shared helpers for the release build scripts.
import 'dart:convert';
import 'dart:io';

/// Repository root: the parent of the `installer` directory.
final String repoRoot = File.fromUri(Platform.script).parent.parent.path;

/// Absolute path inside the repository built from [segments].
String repoPath(List<String> segments) =>
    [repoRoot, ...segments].join(Platform.pathSeparator);

/// Path of [fileName] in `build/release`, creating the directory if needed.
String releasePath(String fileName) {
  final dir = Directory(repoPath(['build', 'release']))
    ..createSync(recursive: true);
  return '${dir.path}${Platform.pathSeparator}$fileName';
}

/// Prints [message] to stderr and exits with a failure code.
Never fail(String message) {
  stderr.writeln(message);
  exit(1);
}

/// App version from `pubspec.yaml` without the build number.
String readVersion() {
  final pubspec = File(repoPath(['pubspec.yaml'])).readAsStringSync();
  final match = RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(pubspec);
  if (match == null) fail('version not found in pubspec.yaml');
  return match.group(1)!.split('+').first;
}

/// Runs [executable] in the repository root with inherited output; fails with [error].
Future<void> run(
  String executable,
  List<String> args, {
  required String error,
}) async {
  final process = await Process.start(
    executable,
    args,
    workingDirectory: repoRoot,
    mode: ProcessStartMode.inheritStdio,
    // flutter on Windows is a .bat file and starts only through the shell.
    runInShell: Platform.isWindows && !executable.toLowerCase().endsWith('.exe'),
  );
  if (await process.exitCode != 0) fail(error);
}

/// Short hash of the current commit, or null outside git.
Future<String?> _commitSha() async {
  try {
    final result = await Process.run('git', ['-C', repoRoot, 'rev-parse', '--short', 'HEAD']);
    return result.exitCode == 0 ? (result.stdout as String).trim() : null;
  } on ProcessException {
    return null;
  }
}

/// Telegram bot that receives release artifacts.
class TelegramBot {
  TelegramBot._(this._token, this._chatId);

  /// Reads the bot secrets from `installer/telegram.env`.
  factory TelegramBot.fromEnvFile() {
    final file = File(repoPath(['installer', 'telegram.env']));
    if (!file.existsSync()) {
      fail('${file.path} not found. Copy telegram.env.example to telegram.env or run with --no-send.');
    }
    final values = <String, String>{};
    for (final line in file.readAsLinesSync()) {
      if (RegExp(r'^\s*([A-Z_]+)\s*=\s*(.*)$').firstMatch(line) case final m?) {
        values[m.group(1)!] = m.group(2)!.trim();
      }
    }
    final token = values['TELEGRAM_BOT_TOKEN'] ?? '';
    final chatId = values['TELEGRAM_CHAT_ID'] ?? '';
    if (token.isEmpty || chatId.isEmpty) {
      fail('telegram.env: TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID are required.');
    }
    return TelegramBot._(token, chatId);
  }

  /// Bot API sendDocument limit (50 MB) with a margin.
  static const _sizeLimit = 49 * 1024 * 1024;

  final String _token;
  final String _chatId;

  /// Sends [file] captioned with [version], commit and optional [note].
  Future<void> sendRelease(File file, {required String version, String? note}) async {
    final name = file.uri.pathSegments.last;
    final size = file.lengthSync();
    if (size > _sizeLimit) {
      final mb = (size / 1024 / 1024).toStringAsFixed(1);
      stderr.writeln('$name — $mb MB > 50 MB, the Bot API limit. The file is built in build/release/ but not sent.');
      return;
    }

    final sha = await _commitSha();
    final caption = ['Shado $version — $name', if (sha != null) 'commit: $sha', ?note].join('\n');

    final boundary = 'shado-${DateTime.now().microsecondsSinceEpoch}';
    String field(String key, String value) =>
        '--$boundary\r\nContent-Disposition: form-data; name="$key"\r\n\r\n$value\r\n';
    final head = utf8.encode(
      '${field('chat_id', _chatId)}${field('caption', caption)}'
      '--$boundary\r\nContent-Disposition: form-data; name="document"; filename="$name"\r\n'
      'Content-Type: application/octet-stream\r\n\r\n',
    );
    final tail = utf8.encode('\r\n--$boundary--\r\n');

    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse('https://api.telegram.org/bot$_token/sendDocument'));
      request.headers.contentType = ContentType('multipart', 'form-data', parameters: {'boundary': boundary});
      request.contentLength = head.length + size + tail.length;
      request.add(head);
      await request.addStream(file.openRead());
      request.add(tail);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      final Object? json;
      try {
        json = jsonDecode(body);
      } on FormatException {
        fail('Telegram: unexpected response for $name: $body');
      }
      switch (json) {
        case {'ok': true}:
          stdout.writeln('Sent to Telegram: $name');
        case {'description': final String description}:
          fail('Telegram rejected $name: $description');
        default:
          fail('Telegram: unexpected response for $name: $body');
      }
    } finally {
      client.close();
    }
  }
}

# Local build and delivery to Telegram

Builds Shado release builds on this machine: the Android APK and the macOS
archive go to a Telegram bot, the Windows installer is built locally. The
general recipe (and a CI option) is in
[`docs/BUILD_AND_DELIVERY.md`](../docs/BUILD_AND_DELIVERY.md).

The scripts are written in Dart and run the same way on Windows and macOS: `dart`
ships with the Flutter SDK, nothing else needs installing. Run the commands from
the repository root.

| Script | What it does |
| --- | --- |
| `build_release_android.dart` | Android APK → Telegram bot |
| `build_release_macos.dart` | macOS `.app` in a zip → Telegram bot (macOS only) |
| `build_release_windows.dart` | Windows installer (`.exe`) locally (Windows only) |
| `build_installer.dart` | orchestrator: the current desktop platform + Android |
| `release_utils.dart` | shared helpers: version, running processes, sending to the bot |

## One-time setup

Copy `installer/telegram.env.example` to `installer/telegram.env` and fill in
`TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID`. The `telegram.env` file is in
`.gitignore` — the token never reaches the repository.

## Everything at once

```bash
dart run installer/build_installer.dart                   # current OS desktop + Android
dart run installer/build_installer.dart --target=android  # Android only
dart run installer/build_installer.dart --target=macos    # macOS only (on a Mac)
dart run installer/build_installer.dart --target=windows  # Windows only (on Windows)
dart run installer/build_installer.dart --no-send         # build, do not send to the bot
```

On Windows `all` = the Windows installer + Android, on macOS — the macOS
archive + Android. A target for another platform fails with an error.

## Android

```bash
dart run installer/build_release_android.dart            # build the APK and send it to the bot
dart run installer/build_release_android.dart --no-send  # only build into build/release/
```

`flutter build apk --release --split-per-abi`; the bot receives the `arm64-v8a`
split (~26 MB) with a "version + file name + commit" caption. The universal APK
(~62 MB) does not fit the 50 MB Bot API limit.

The APK is signed with the **debug key** — fine for installing on your own
device, not for Google Play.

## macOS

```bash
dart run installer/build_release_macos.dart            # build the zip and send it to the bot
dart run installer/build_release_macos.dart --no-send  # only build into build/release/
```

`flutter build macos --release`, then `ditto` packs `shado.app` into
`build/release/Shado-<version>-macos.zip`. The build is **not notarized**: on the
Mac where the archive is downloaded, remove the quarantine before launching —
`xattr -dr com.apple.quarantine shado.app` (the file caption includes a hint).
If the archive is larger than 50 MB, it stays in `build/release/` and is not
sent.

## Windows installer (not sent to the bot)

```bash
winget install --id JRSoftware.InnoSetup                  # one-time: ISCC is required
dart run installer/build_release_windows.dart             # → build/release/Shado-<version>-windows-x64-setup.exe
```

`--skip-flutter-build` repackages without rebuilding Flutter. Limitations: the
installer is **not signed** (SmartScreen warns on another machine), and it does
not include the **Visual C++ Redistributable** — on a clean Windows the exe may
not start (add `msvcp140.dll`, `vcruntime140.dll`, `vcruntime140_1.dll` to the
`[Files]` section in `shado.iss`).

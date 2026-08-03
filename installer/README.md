# Локальная сборка и доставка в Telegram

Собирает релизные сборки Shado на этой машине: Android APK уходит в Telegram-бота,
Windows-установщик собирается локально. Общий рецепт (и вариант через CI) —
в [`docs/BUILD_AND_DELIVERY.md`](../docs/BUILD_AND_DELIVERY.md).

Скрипты в этой директории:

| Скрипт | Что делает |
| --- | --- |
| `build_release_android.ps1` | Android APK → Telegram-бот |
| `build_release_windows.ps1` | Windows-установщик (`.exe`) локально |
| `build_installer.ps1` | оркестратор: вызывает оба |

## Разовая настройка

Секреты бота:

```powershell
Copy-Item installer\telegram.env.example installer\telegram.env
```

и вписать `TELEGRAM_BOT_TOKEN` и `TELEGRAM_CHAT_ID`. Файл `telegram.env`
в `.gitignore` — токен в репозиторий не попадает.

## Отправить сборку в бот

```powershell
pwsh installer\build_release_android.ps1          # собрать APK и отправить в бота
pwsh installer\build_release_android.ps1 -NoSend  # только собрать в build\release\, без отправки
```

Что происходит: `flutter build apk --release --split-per-abi`; в бота уходит
`arm64-v8a`-срез (~26 МБ) с подписью «версия + имя файла + commit». Универсальный
APK ~62 МБ не проходит лимит Bot API 50 МБ. Готовый файл кладётся в `build\release\`.

APK подписан **debug-ключом** — годится «поставить себе», не для Google Play.

## Windows-установщик (в бот не отправляется)

Собрать локально, если нужен `.exe`-установщик:

```powershell
winget install --id JRSoftware.InnoSetup     # разово: нужен ISCC
pwsh installer\build_release_windows.ps1     # → build\release\Shado-<версия>-windows-x64-setup.exe
```

`-SkipFlutterBuild` — переупаковать без пересборки Flutter. Ограничения:
установщик **не подписан** (SmartScreen предупредит на чужой машине), и в него
не входит **Visual C++ Redistributable** — на чистой Windows exe может не
стартовать (добавьте `msvcp140.dll`, `vcruntime140.dll`, `vcruntime140_1.dll`
в секцию `[Files]` в `shado.iss`).

## Обе платформы разом

`build_installer.ps1` — оркестратор: вызывает оба скрипта выше.

```powershell
pwsh installer\build_installer.ps1                  # Windows-установщик + Android APK (APK → в бота)
pwsh installer\build_installer.ps1 -Target android  # только Android
pwsh installer\build_installer.ps1 -Target windows  # только Windows
pwsh installer\build_installer.ps1 -NoSend          # собрать обе, APK в бота не отправлять
```

Windows-установщик в бота не уходит ни при каком флаге — доставляется только
Android-срез.

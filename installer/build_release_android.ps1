# Собирает Android APK и отправляет его в Telegram-бота.
# Использование: pwsh installer\build_release_android.ps1 [-NoSend]
#
#   -NoSend   только собрать в build\release\, без отправки в Telegram.
#
# Секреты бота — installer\telegram.env (в .gitignore). В бота уходит arm64-срез
# (--split-per-abi): универсальный APK ~62 МБ не проходит лимит Bot API 50 МБ.
# Windows-установщик в бота не отправляется; собрать его локально можно отдельно:
# pwsh installer\build_release_windows.ps1.
param([switch]$NoSend)
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$outDir   = Join-Path $repoRoot 'build\release'
$pubspec  = Get-Content (Join-Path $repoRoot 'pubspec.yaml')
$version  = ($pubspec | Select-String '^version:\s*(.+)$').Matches[0].Groups[1].Value.Trim().Split('+')[0]
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# Лимит Bot API на sendDocument — 50 МБ; берём с запасом.
$botLimit = 49MB

# Секреты читаем до сборки, чтобы не собирать зря ради ошибки в конце.
$token = $null; $chatId = $null
if (-not $NoSend) {
    $tgFile = Join-Path $repoRoot 'installer\telegram.env'
    if (-not (Test-Path $tgFile)) {
        throw "$tgFile не найден. Скопируйте telegram.env.example в telegram.env или запустите с -NoSend."
    }
    $tg = @{}
    foreach ($line in Get-Content $tgFile) {
        if ($line -match '^\s*([A-Z_]+)\s*=\s*(.*)$') { $tg[$Matches[1]] = $Matches[2].Trim() }
    }
    $token = $tg['TELEGRAM_BOT_TOKEN']; $chatId = $tg['TELEGRAM_CHAT_ID']
    if (-not $token -or -not $chatId) { throw "telegram.env: нужны TELEGRAM_BOT_TOKEN и TELEGRAM_CHAT_ID." }
}

& flutter build apk --release --split-per-abi
if ($LASTEXITCODE -ne 0) { throw "flutter build apk failed" }
$arm64src = Join-Path $repoRoot 'build\app\outputs\flutter-apk\app-arm64-v8a-release.apk'
if (-not (Test-Path $arm64src)) { throw "APK не найден: $arm64src" }
$apk = Join-Path $outDir "Shado-$version-android-arm64.apk"
Copy-Item $arm64src $apk -Force

$name = [IO.Path]::GetFileName($apk)
if ($NoSend) { Write-Host "Собрано: $apk (отправка пропущена: -NoSend)"; return }

$size = (Get-Item $apk).Length
if ($size -gt $botLimit) {
    Write-Warning "$name — $([math]::Round($size/1MB,1)) МБ > 50 МБ, лимит Bot API. Файл собран в build\release\, но не отправлен."
    return
}

$sha = (& git -C $repoRoot rev-parse --short HEAD 2>$null)
$caption = "Shado $version — $name"
if ($sha) { $caption += "`ncommit: $sha" }
# Прямые слэши в пути к файлу — чтобы curl не спотыкался об экранирование.
$filePath = $apk -replace '\\','/'
$resp = & curl.exe -sS -X POST "https://api.telegram.org/bot$token/sendDocument" `
    -F "chat_id=$chatId" `
    -F "document=@$filePath" `
    -F "caption=$caption"
try { $json = $resp | ConvertFrom-Json } catch { throw "Telegram: неожиданный ответ на $name`: $resp" }
if (-not $json.ok) { throw "Telegram отклонил $name`: $($json.description)" }
Write-Host "Отправлено в Telegram: $name"

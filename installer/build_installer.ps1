# Оркестратор релизных сборок: вызывает профильные скрипты рядом.
# Использование: pwsh installer\build_installer.ps1 [-Target all|windows|android] [-NoSend]
#
#   -Target   что собирать (по умолчанию all).
#   -NoSend   передаётся в android-скрипт: собрать APK, но не отправлять в бот.
#
# Оба артефакта кладутся в build\release\. Android-срез уходит в Telegram-бота
# (если не -NoSend); Windows-установщик в бота не отправляется — только собирается.
param(
    [ValidateSet('all','windows','android')][string]$Target = 'all',
    [switch]$NoSend
)
$ErrorActionPreference = 'Stop'

# Каждый скрипт — в своём процессе: их param/ErrorActionPreference не мешают друг
# другу, а $LASTEXITCODE даёт чёткую точку отказа.
if ($Target -in @('all', 'windows')) {
    & pwsh -NoProfile -File (Join-Path $PSScriptRoot 'build_release_windows.ps1')
    if ($LASTEXITCODE -ne 0) { throw "Windows build failed" }
}

if ($Target -in @('all', 'android')) {
    $androidArgs = @()
    if ($NoSend) { $androidArgs += '-NoSend' }
    & pwsh -NoProfile -File (Join-Path $PSScriptRoot 'build_release_android.ps1') @androidArgs
    if ($LASTEXITCODE -ne 0) { throw "Android build failed" }
}

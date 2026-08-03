# Собирает Flutter Windows release и упаковывает его в установщик Inno Setup.
# Использование: pwsh installer\build_release_windows.ps1 [-SkipFlutterBuild]
#
# --dart-define не передаём: SHADO_API_BASE_URL уже по умолчанию указывает на
# прод (см. lib/core/config/app_config.dart), поэтому релиз без флагов рабочий.
param([switch]$SkipFlutterBuild)
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$issFile  = Join-Path $PSScriptRoot 'shado.iss'

$iscc = @(
    "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) { throw "ISCC.exe не найден. winget install --id JRSoftware.InnoSetup" }

$pubspec = Get-Content (Join-Path $repoRoot 'pubspec.yaml')
$version = ($pubspec | Select-String '^version:\s*(.+)$').Matches[0].Groups[1].Value.Trim().Split('+')[0]

if (-not $SkipFlutterBuild) {
    & flutter build windows --release
    if ($LASTEXITCODE -ne 0) { throw "flutter build windows failed" }
}

$releaseDir = Join-Path $repoRoot 'build\windows\x64\runner\Release'
if (-not (Test-Path (Join-Path $releaseDir 'shado.exe'))) { throw "Release-сборка не найдена" }

& $iscc "/DAppVersion=$version" $issFile
if ($LASTEXITCODE -ne 0) { throw "ISCC failed" }
Write-Host "Установщик: build\release\Shado-$version-windows-x64-setup.exe"

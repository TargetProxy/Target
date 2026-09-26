<#
.SYNOPSIS
Packages a release build for distribution. Runs on the target platform.

.EXAMPLE
.\scripts\stage.ps1 -Target windows
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('windows', 'linux', 'macos', 'ios', 'apk')]
    [string]$Target
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$targetLibRoot = [IO.Path]::GetFullPath((Join-Path $root '..' 'TargetLib'))
$versionLine = Select-String -LiteralPath (Join-Path $root 'pubspec.yaml') -Pattern '^version:\s*([^+\s]+)' | Select-Object -First 1
if (-not $versionLine) { throw 'Unable to read the application version from pubspec.yaml.' }
$appVersion = $versionLine.Matches[0].Groups[1].Value

switch ($Target) {
    'windows' {
        $outputDir = Join-Path $root 'build\windows\installer'
        $releasePath = Join-Path $root 'build\windows\x64\runner\Release\target.exe'
        $targetLibPath = Join-Path $targetLibRoot 'build\TargetLib.exe'
        if (-not (Test-Path -LiteralPath $releasePath -PathType Leaf)) {
            throw "Flutter release build not found at $releasePath. Run '.\scripts\build.ps1 -Target windows' first."
        }
        if (-not (Test-Path -LiteralPath $targetLibPath -PathType Leaf)) {
            throw "TargetLib binary not found at $targetLibPath. Build TargetLib first."
        }

        New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

        python -c 'import PIL' 2>$null
        if ($LASTEXITCODE -ne 0) {
            python -m pip install --quiet pillow
            if ($LASTEXITCODE -ne 0) { throw "pip install pillow failed ($LASTEXITCODE)" }
        }
        $pythonCode = @'
from PIL import Image
import sys

source, destination = sys.argv[1:3]
with Image.open(source) as image:
    image.convert("RGBA").save(
        destination,
        format="ICO",
        sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
    )
'@
        & python -c $pythonCode (Join-Path $root 'assets\TargetAppIcon.png') (Join-Path $outputDir 'TargetAppIcon.ico')
        if ($LASTEXITCODE -ne 0) { throw "Icon conversion failed ($LASTEXITCODE)" }

        $iscc = Get-Command ISCC.exe -ErrorAction SilentlyContinue
        $isccPath = if ($iscc) { $iscc.Source } else {
            @('Inno Setup 7', 'Inno Setup 6') | ForEach-Object {
                Join-Path $env:ProgramFiles "$_\ISCC.exe"
                Join-Path ${env:ProgramFiles(x86)} "$_\ISCC.exe"
            } | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
        }
        if (-not $isccPath) { throw 'ISCC.exe was not found. Install Inno Setup 6 or later, or add it to PATH.' }

        & $isccPath "/DAppVersion=$appVersion" "/DTargetLibSource=$targetLibPath" (Join-Path $PSScriptRoot 'installer.iss')
        if ($LASTEXITCODE -ne 0) { throw "Inno Setup compilation failed ($LASTEXITCODE)" }
    }
    'linux' {
        $bundlePath = Join-Path $root 'build/linux/x64/release/bundle'
        $servicePath = Join-Path $targetLibRoot 'build/TargetLib'
        $ruleSetPath = Join-Path $targetLibRoot 'build/cn.srs'
        foreach ($inputPath in @($bundlePath, $servicePath, $ruleSetPath)) {
            if (-not (Test-Path -LiteralPath $inputPath)) {
                throw "Stage input not found: $inputPath. Run '.\scripts\build.ps1 -Target linux' and build TargetLib first."
            }
        }

        $packageDir = Join-Path $root 'build/linux/stage/Target-linux-x64'
        Remove-Item -LiteralPath $packageDir -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Force -Path (Join-Path $packageDir 'bundle') | Out-Null
        Copy-Item -LiteralPath (Join-Path $bundlePath '*') -Destination (Join-Path $packageDir 'bundle') -Recurse -Force
        Copy-Item -LiteralPath @($servicePath, $ruleSetPath) -Destination $packageDir -Force

        $tar = Get-Command tar -ErrorAction Stop
        $tarPath = Join-Path $root "build/linux/stage/Target-$appVersion-linux-x64.tar.gz"
        & $tar.Source -czf $tarPath -C (Split-Path -Parent $packageDir) 'Target-linux-x64'
        if ($LASTEXITCODE -ne 0) { throw "tar failed ($LASTEXITCODE)" }
    }
    'macos' {
        $app = Get-ChildItem -LiteralPath (Join-Path $root 'build/macos/Build/Products/Release') -Filter '*.app' -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $app) { throw "macOS app bundle not found. Run '.\scripts\build.ps1 -Target macos' first." }
        $tar = Get-Command tar -ErrorAction Stop
        $tarPath = Join-Path $root "build/macos/stage/Target-$appVersion-macos-arm64.tar.gz"
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $tarPath) | Out-Null
        & $tar.Source -czf $tarPath -C $app.DirectoryName $app.Name
        if ($LASTEXITCODE -ne 0) { throw "tar failed ($LASTEXITCODE)" }
    }
    'ios' {
        $app = Get-ChildItem -LiteralPath (Join-Path $root 'build/ios/iphoneos') -Filter '*.app' -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $app) { throw "iOS app bundle not found. Run '.\scripts\build.ps1 -Target ios' first." }
        $tar = Get-Command tar -ErrorAction Stop
        $tarPath = Join-Path $root "build/ios/stage/Target-$appVersion-ios.tar.gz"
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $tarPath) | Out-Null
        & $tar.Source -czf $tarPath -C $app.DirectoryName $app.Name
        if ($LASTEXITCODE -ne 0) { throw "tar failed ($LASTEXITCODE)" }
    }
    'apk' {
        $apkPath = Join-Path $root 'build/app/outputs/flutter-apk/app-debug.apk'
        if (-not (Test-Path -LiteralPath $apkPath -PathType Leaf)) {
            throw "APK not found at $apkPath. Run '.\scripts\build.ps1 -Target apk' first."
        }
        $stagePath = Join-Path $root "build/apk/stage/Target-$appVersion-android-debug.apk"
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $stagePath) | Out-Null
        Copy-Item -LiteralPath $apkPath -Destination $stagePath -Force
    }
}

<#
.SYNOPSIS
Packages the Windows release build and TargetLib service into an installer.

.EXAMPLE
.\scripts\stage.ps1
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$outputDir = Join-Path $root 'build\windows\installer'
$releasePath = Join-Path $root 'build\windows\x64\runner\Release\target.exe'
$targetLibPath = [IO.Path]::GetFullPath((Join-Path $root '..\TargetLib\build\TargetLib.exe'))
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

$versionLine = Select-String -LiteralPath (Join-Path $root 'pubspec.yaml') -Pattern '^version:\s*([^+\s]+)' | Select-Object -First 1
if (-not $versionLine) { throw 'Unable to read the application version from pubspec.yaml.' }

$iscc = Get-Command ISCC.exe -ErrorAction SilentlyContinue
$isccPath = if ($iscc) { $iscc.Source } else {
    @('Inno Setup 7', 'Inno Setup 6') | ForEach-Object {
        Join-Path $env:ProgramFiles "$_\ISCC.exe"
        Join-Path ${env:ProgramFiles(x86)} "$_\ISCC.exe"
    } | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
}
if (-not $isccPath) { throw 'ISCC.exe was not found. Install Inno Setup 6 or later, or add it to PATH.' }

& $isccPath "/DAppVersion=$($versionLine.Matches[0].Groups[1].Value)" "/DTargetLibSource=$targetLibPath" (Join-Path $PSScriptRoot 'installer.iss')
if ($LASTEXITCODE -ne 0) { throw "Inno Setup compilation failed ($LASTEXITCODE)" }

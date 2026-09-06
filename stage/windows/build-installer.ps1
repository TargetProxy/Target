$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$outputDir = Join-Path $repoRoot "build\windows\installer"
$pngPath = Join-Path $repoRoot "assets\TargetAppIcon.png"
$icoPath = Join-Path $outputDir "TargetAppIcon.ico"
$issPath = Join-Path $PSScriptRoot "installer.iss"
$releasePath = Join-Path $repoRoot "build\windows\x64\runner\Release\target.exe"
$targetLibPath = Join-Path (Split-Path -Parent $repoRoot) "TargetLib\build\TargetLib.exe"

if (-not (Test-Path -LiteralPath $releasePath -PathType Leaf)) {
  throw "Flutter release build was not found at $releasePath. Run 'flutter build windows --release' first."
}
if (-not (Test-Path -LiteralPath $targetLibPath -PathType Leaf)) {
  throw "TargetLib service binary was not found at $targetLibPath. Build TargetLib before creating the installer."
}

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

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

& python -c $pythonCode $pngPath $icoPath
if ($LASTEXITCODE -ne 0) {
  throw "Failed to convert the application icon. Ensure Python and Pillow are installed."
}

$versionLine = Select-String -LiteralPath (Join-Path $repoRoot "pubspec.yaml") -Pattern '^version:\s*([^+\s]+)' | Select-Object -First 1
if (-not $versionLine) {
  throw "Unable to read the application version from pubspec.yaml."
}
$appVersion = $versionLine.Matches[0].Groups[1].Value

$iscc = Get-Command ISCC.exe -ErrorAction SilentlyContinue
if ($iscc) {
  $isccPath = $iscc.Source
} else {
  $candidatePaths = @(
    (Join-Path $env:ProgramFiles "Inno Setup 7\ISCC.exe"),
    (Join-Path ${env:ProgramFiles(x86)} "Inno Setup 7\ISCC.exe"),
    (Join-Path $env:ProgramFiles "Inno Setup 6\ISCC.exe"),
    (Join-Path ${env:ProgramFiles(x86)} "Inno Setup 6\ISCC.exe")
  )
  $isccPath = $candidatePaths | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
  if (-not $isccPath) {
    throw "ISCC.exe was not found. Install Inno Setup 6 or later, or add it to PATH."
  }
}

& $isccPath "/DAppVersion=$appVersion" "/DTargetLibSource=$targetLibPath" $issPath
if ($LASTEXITCODE -ne 0) {
  throw "Inno Setup compilation failed."
}

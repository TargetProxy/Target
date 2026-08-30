$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$outputDir = Join-Path $repoRoot "build\windows\installer"
$pngPath = Join-Path $repoRoot "assets\TargetAppIcon.png"
$icoPath = Join-Path $outputDir "TargetAppIcon.ico"
$nsiPath = Join-Path $PSScriptRoot "installer.nsi"
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

$makeNsis = Get-Command makensis -ErrorAction SilentlyContinue
if ($makeNsis) {
  $makeNsisPath = $makeNsis.Source
} else {
  $defaultNsisPath = "${env:ProgramFiles(x86)}\NSIS\makensis.exe"
  if (Test-Path -LiteralPath $defaultNsisPath) {
    $makeNsisPath = $defaultNsisPath
  } else {
    throw "makensis was not found. Install NSIS or add it to PATH."
  }
}

& $makeNsisPath "/WX" "/DTARGETLIB_SOURCE=$targetLibPath" $nsiPath
if ($LASTEXITCODE -ne 0) {
  throw "NSIS compilation failed."
}

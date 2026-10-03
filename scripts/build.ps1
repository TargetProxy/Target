<#
.SYNOPSIS
Restores Flutter dependencies and builds the Target app for one platform.

.EXAMPLE
.\scripts\build.ps1 -Target windows
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('windows', 'linux', 'apk', 'macos', 'ios')]
    [string]$Target
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$flutterArgs = (Import-PowerShellDataFile (Join-Path $PSScriptRoot 'ci-config.psd1')).FlutterArgs[$Target] -split ' '
$flutter = Get-Command flutter -ErrorAction Stop
$platforms = @('android', 'ios', 'linux', 'macos', 'windows')
$platformArg = "--platforms=$($platforms -join ',')"

Push-Location ([IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')))
try {
    $missingPlatforms = @($platforms | Where-Object { -not (Test-Path $_ -PathType Container) })
    if ($missingPlatforms.Count -gt 0) {
        & $flutter.Source create $platformArg .
        if ($LASTEXITCODE -ne 0) { throw "flutter create failed ($LASTEXITCODE)" }
    }
    & $flutter.Source pub get
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed ($LASTEXITCODE)" }
    & (Join-Path $PSScriptRoot 'generate-icons.ps1')
    if ($LASTEXITCODE -ne 0) { throw "launcher icon generation failed ($LASTEXITCODE)" }
    & $flutter.Source build $Target @flutterArgs
    if ($LASTEXITCODE -ne 0) { throw "flutter build $Target failed ($LASTEXITCODE)" }
} finally {
    Pop-Location
}

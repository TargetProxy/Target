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

Push-Location ([IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')))
try {
    if ($Target -in @('macos', 'ios')) {
        & $flutter.Source create --platforms=$Target .
        if ($LASTEXITCODE -ne 0) { throw "flutter create failed ($LASTEXITCODE)" }
    }
    & $flutter.Source pub get
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed ($LASTEXITCODE)" }
    & $flutter.Source build $Target @flutterArgs
    if ($LASTEXITCODE -ne 0) { throw "flutter build $Target failed ($LASTEXITCODE)" }
} finally {
    Pop-Location
}

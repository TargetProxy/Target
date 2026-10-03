<#
.SYNOPSIS
Generates launcher icons for every configured Flutter platform.

.EXAMPLE
.\scripts\generate-icons.ps1
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$dart = Get-Command dart -ErrorAction Stop
Push-Location ([IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')))
try {
    & $dart.Source run flutter_launcher_icons
    if ($LASTEXITCODE -ne 0) { throw "flutter_launcher_icons failed ($LASTEXITCODE)" }
} finally {
    Pop-Location
}

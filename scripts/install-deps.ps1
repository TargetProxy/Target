<#
.SYNOPSIS
Installs Linux desktop build dependencies. No-op on other platforms.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $IsLinux) { return }
$packages = (Import-PowerShellDataFile (Join-Path $PSScriptRoot 'ci-config.psd1')).LinuxAptPackages

sudo apt-get update
if ($LASTEXITCODE -ne 0) { throw "apt-get update failed ($LASTEXITCODE)" }
sudo apt-get install -y @packages
if ($LASTEXITCODE -ne 0) { throw "apt-get install failed ($LASTEXITCODE)" }

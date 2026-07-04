[CmdletBinding()]
param(
    [string]$InstallRoot = "$env:LOCALAPPDATA\Programs\MirrorPhone"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$markerPath = Join-Path $InstallRoot ".mirrorphone-install"
$desktopLink = Join-Path ([Environment]::GetFolderPath("Desktop")) "mirrorPhone.lnk"
$startMenuDir = Join-Path ([Environment]::GetFolderPath("Programs")) "mirrorPhone"

if (Test-Path -LiteralPath $desktopLink) {
    Remove-Item -LiteralPath $desktopLink -Force
}

if (Test-Path -LiteralPath $startMenuDir) {
    Remove-Item -LiteralPath $startMenuDir -Recurse -Force
}

if (-not (Test-Path -LiteralPath $InstallRoot)) {
    Write-Host "mirrorPhone is not installed at $InstallRoot."
    exit 0
}

if (-not (Test-Path -LiteralPath $markerPath)) {
    Write-Error "Refusing to remove a folder without .mirrorphone-install marker: $InstallRoot"
    exit 1
}

Remove-Item -LiteralPath $InstallRoot -Recurse -Force
Write-Host "mirrorPhone was uninstalled."

[CmdletBinding()]
param(
    [string]$Version = "0.2.0-exe-bootstrapper"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Root = $PSScriptRoot
$Dist = Join-Path $Root "dist"
$Source = Join-Path $Root "src\MirrorPhoneSetup.cs"
$Exe = Join-Path $Dist "MirrorPhone-Setup-v$Version.exe"
$Zip = Join-Path $Dist "MirrorPhone-Setup-v$Version.zip"

New-Item -ItemType Directory -Force -Path $Dist | Out-Null

$frameworkRoot = Join-Path $env:WINDIR "Microsoft.NET\Framework64\v4.0.30319"
$csc = Join-Path $frameworkRoot "csc.exe"

if (-not (Test-Path -LiteralPath $csc)) {
    throw "csc.exe was not found: $csc"
}

& $csc `
    /nologo `
    /target:exe `
    /platform:x64 `
    /optimize+ `
    /out:$Exe `
    /reference:System.IO.Compression.dll `
    /reference:System.IO.Compression.FileSystem.dll `
    $Source

if ($LASTEXITCODE -ne 0) {
    throw "csc.exe failed with exit code $LASTEXITCODE"
}

if (Test-Path -LiteralPath $Zip) {
    Remove-Item -LiteralPath $Zip -Force
}

Compress-Archive -Force -LiteralPath @(
    $Exe,
    (Join-Path $Root "README.md"),
    (Join-Path $Root "VERSION")
) -DestinationPath $Zip

Write-Host "Built: $Exe"
Write-Host "Built: $Zip"

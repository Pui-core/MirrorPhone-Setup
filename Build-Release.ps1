[CmdletBinding()]
param(
    [string]$Version = "0.2.2-airplay-embedded",
    [string]$SourceZip = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Root = $PSScriptRoot
$Dist = Join-Path $Root "dist"
$Source = Join-Path $Root "src\MirrorPhoneSetup.cs"
$DefaultSourceZip = Join-Path $Root "payload\mirrorPhone-source.zip"
$Exe = Join-Path $Dist "MirrorPhone-Setup-v$Version.exe"
$Zip = Join-Path $Dist "MirrorPhone-Setup-v$Version.zip"
$ReleaseSourceZip = Join-Path $Dist "mirrorPhone-source.zip"

New-Item -ItemType Directory -Force -Path $Dist | Out-Null

if ([string]::IsNullOrWhiteSpace($SourceZip)) {
    $SourceZip = $DefaultSourceZip
}

if (-not (Test-Path -LiteralPath $SourceZip)) {
    throw "mirrorPhone source zip was not found: $SourceZip"
}

Copy-Item -LiteralPath $SourceZip -Destination $ReleaseSourceZip -Force

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
    "/resource:$SourceZip,MirrorPhoneSource.zip" `
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
    $ReleaseSourceZip,
    (Join-Path $Root "Install-MirrorPhone.bat"),
    (Join-Path $Root "Install-MirrorPhone.ps1"),
    (Join-Path $Root "Uninstall-MirrorPhone.ps1"),
    (Join-Path $Root "README.md"),
    (Join-Path $Root "VERSION")
) -DestinationPath $Zip

Write-Host "Built: $Exe"
Write-Host "Built: $Zip"

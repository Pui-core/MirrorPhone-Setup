[CmdletBinding()]
param(
    [string]$SourceRepo = "Pui-core/mirrorPhone",
    [string]$SourceRef = "feature/issue-6-airplay-receiver",
    [string]$InstallRoot = "$env:LOCALAPPDATA\Programs\MirrorPhone",
    [switch]$NoShortcut
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[MirrorPhone-Setup] $Message"
}

function Stop-WithMessage {
    param([string]$Message)
    Write-Error $Message
    exit 1
}

function Require-Command {
    param([string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        Stop-WithMessage "$Name was not found. Install Node.js LTS, then run this installer again."
    }
}

function New-Shortcut {
    param(
        [string]$Path,
        [string]$TargetPath,
        [string]$WorkingDirectory,
        [string]$IconPath
    )

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($Path)
    $shortcut.TargetPath = $TargetPath
    $shortcut.WorkingDirectory = $WorkingDirectory
    if (Test-Path -LiteralPath $IconPath) {
        $shortcut.IconLocation = $IconPath
    }
    $shortcut.Save()
}

if (-not [Environment]::Is64BitOperatingSystem) {
    Stop-WithMessage "mirrorPhone requires 64-bit Windows."
}

Require-Command "node"
Require-Command "npm"

$sourceZipUrl = "https://github.com/$SourceRepo/archive/refs/heads/$SourceRef.zip"
$markerPath = Join-Path $InstallRoot ".mirrorphone-install"
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("MirrorPhone-Setup-" + [Guid]::NewGuid().ToString("N"))
$zipPath = Join-Path $tempRoot "mirrorPhone.zip"

Write-Step "Source: $sourceZipUrl"
Write-Step "Install root: $InstallRoot"

if ((Test-Path -LiteralPath $InstallRoot) -and -not (Test-Path -LiteralPath $markerPath)) {
    Stop-WithMessage "Install root already exists and was not created by MirrorPhone-Setup: $InstallRoot"
}

New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

try {
    Write-Step "Downloading mirrorPhone source..."
    Invoke-WebRequest -UseBasicParsing -Uri $sourceZipUrl -OutFile $zipPath

    Write-Step "Extracting source..."
    Expand-Archive -LiteralPath $zipPath -DestinationPath $tempRoot -Force

    $sourceDir = Get-ChildItem -LiteralPath $tempRoot -Directory |
        Where-Object { $_.Name -like "mirrorPhone-*" -or $_.Name -like "mirrorphone-*" } |
        Select-Object -First 1

    if (-not $sourceDir) {
        Stop-WithMessage "Could not find extracted mirrorPhone source directory."
    }

    if (Test-Path -LiteralPath $InstallRoot) {
        Write-Step "Removing previous MirrorPhone install..."
        Remove-Item -LiteralPath $InstallRoot -Recurse -Force
    }

    Write-Step "Copying files..."
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $InstallRoot) | Out-Null
    Copy-Item -LiteralPath $sourceDir.FullName -Destination $InstallRoot -Recurse -Force

    Set-Content -LiteralPath $markerPath -Value @(
        "repo=$SourceRepo"
        "ref=$SourceRef"
        "installedAt=$(Get-Date -Format o)"
    )

    Write-Step "Installing npm dependencies..."
    Push-Location $InstallRoot
    try {
        & npm install
        if ($LASTEXITCODE -ne 0) {
            Stop-WithMessage "npm install failed with exit code $LASTEXITCODE."
        }
    } finally {
        Pop-Location
    }

    $launcher = Join-Path $InstallRoot "start-mirrorPhone.bat"
    if (-not (Test-Path -LiteralPath $launcher)) {
        Stop-WithMessage "Launcher was not found after install: $launcher"
    }

    if (-not $NoShortcut) {
        Write-Step "Creating shortcuts..."
        $desktopLink = Join-Path ([Environment]::GetFolderPath("Desktop")) "mirrorPhone.lnk"
        $startMenuDir = Join-Path ([Environment]::GetFolderPath("Programs")) "mirrorPhone"
        $startMenuLink = Join-Path $startMenuDir "mirrorPhone.lnk"
        $iconPath = Join-Path $InstallRoot "node_modules\electron\dist\electron.exe"

        New-Item -ItemType Directory -Force -Path $startMenuDir | Out-Null
        New-Shortcut -Path $desktopLink -TargetPath $launcher -WorkingDirectory $InstallRoot -IconPath $iconPath
        New-Shortcut -Path $startMenuLink -TargetPath $launcher -WorkingDirectory $InstallRoot -IconPath $iconPath
    }

    Write-Step "Install complete."
    Write-Host "Run mirrorPhone from the desktop or Start Menu shortcut."
} finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

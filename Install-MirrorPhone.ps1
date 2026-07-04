[CmdletBinding()]
param(
    [string]$SourceRepo = "Pui-core/mirrorPhone",
    [string]$SourceRef = "main",
    [string]$SourceZipPath = "",
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

function Find-Command {
    param([string]$Name)
    return Get-Command $Name -ErrorAction SilentlyContinue
}

function Ensure-Node {
    if ((Find-Command "node") -and (Find-Command "npm")) {
        Write-Step "Node.js/npm found."
        return
    }

    Write-Step "Node.js/npm not found. Installing Node.js LTS with winget..."

    if (-not (Find-Command "winget")) {
        Stop-WithMessage "Node.js LTS is required, and winget was not found. Install Node.js LTS from https://nodejs.org/ and run this installer again."
    }

    winget install --id OpenJS.NodeJS.LTS -e --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        Stop-WithMessage "winget failed to install Node.js LTS. Exit code: $LASTEXITCODE"
    }

    $nodeDirCandidates = @(
        "$env:ProgramFiles\nodejs",
        "$env:LOCALAPPDATA\Programs\nodejs"
    )

    foreach ($nodeDir in $nodeDirCandidates) {
        if (Test-Path -LiteralPath (Join-Path $nodeDir "npm.cmd")) {
            $env:PATH = "$nodeDir;$env:PATH"
            break
        }
    }

    if (-not ((Find-Command "node") -and (Find-Command "npm"))) {
        Stop-WithMessage "Node.js install finished, but node/npm were not found. Restart Windows and run this installer again."
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

function Get-SourceZipUrl {
    param(
        [string]$Repo,
        [string]$Ref
    )

    return "https://github.com/$Repo/archive/refs/heads/$Ref.zip"
}

function Clear-InstallSourceFiles {
    param([string]$Path)

    $sourceDirectories = @("ios", "scripts", "src", "test")
    $refreshDirectories = @("node_modules\electron")
    $sourceFiles = @(
        ".gitignore",
        "README.md",
        "package.json",
        "package-lock.json",
        "start-mirrorPhone.bat",
        "start-mirrorPhone.ps1"
    )
    $refreshFiles = @(
        "node_modules\.bin\electron",
        "node_modules\.bin\electron.cmd",
        "node_modules\.bin\electron.ps1"
    )

    foreach ($directory in $sourceDirectories) {
        $target = Join-Path $Path $directory
        if (Test-Path -LiteralPath $target) {
            Remove-Item -LiteralPath $target -Recurse -Force
        }
    }

    foreach ($directory in $refreshDirectories) {
        $target = Join-Path $Path $directory
        if (Test-Path -LiteralPath $target) {
            Write-Step "Refreshing $directory..."
            Remove-Item -LiteralPath $target -Recurse -Force
        }
    }

    foreach ($file in $sourceFiles) {
        $target = Join-Path $Path $file
        if (Test-Path -LiteralPath $target) {
            Remove-Item -LiteralPath $target -Force
        }
    }

    foreach ($file in $refreshFiles) {
        $target = Join-Path $Path $file
        if (Test-Path -LiteralPath $target) {
            Remove-Item -LiteralPath $target -Force
        }
    }
}

function Ensure-ElectronBinary {
    param([string]$Path)

    $electronDir = Join-Path $Path "node_modules\electron"
    $electronExe = Join-Path $electronDir "dist\electron.exe"
    $installScript = Join-Path $electronDir "install.js"
    $pathFile = Join-Path $electronDir "path.txt"

    if (Test-Path -LiteralPath $electronExe) {
        Write-Step "Windows Electron binary ready."
        return
    }

    if (-not (Test-Path -LiteralPath $installScript)) {
        Stop-WithMessage "Electron install script was not found after npm install: $installScript"
    }

    Write-Step "Preparing Windows Electron binary..."

    $electronDist = Join-Path $electronDir "dist"
    if (Test-Path -LiteralPath $electronDist) {
        Remove-Item -LiteralPath $electronDist -Recurse -Force
    }
    if (Test-Path -LiteralPath $pathFile) {
        Remove-Item -LiteralPath $pathFile -Force
    }

    $previousPlatform = $env:ELECTRON_INSTALL_PLATFORM
    $previousArch = $env:ELECTRON_INSTALL_ARCH
    try {
        $env:ELECTRON_INSTALL_PLATFORM = "win32"
        $env:ELECTRON_INSTALL_ARCH = "x64"
        & node $installScript
        if ($LASTEXITCODE -ne 0) {
            Stop-WithMessage "Electron Windows binary setup failed with exit code $LASTEXITCODE."
        }
    } finally {
        $env:ELECTRON_INSTALL_PLATFORM = $previousPlatform
        $env:ELECTRON_INSTALL_ARCH = $previousArch
    }

    if (-not (Test-Path -LiteralPath $electronExe)) {
        Stop-WithMessage "Windows Electron binary was not found after setup: $electronExe"
    }

    Write-Step "Windows Electron binary ready."
}

if (-not [Environment]::Is64BitOperatingSystem) {
    Stop-WithMessage "mirrorPhone requires 64-bit Windows."
}

Ensure-Node

if ([string]::IsNullOrWhiteSpace($SourceZipPath)) {
    $SourceZipPath = Join-Path $PSScriptRoot "mirrorPhone-source.zip"
}

$markerPath = Join-Path $InstallRoot ".mirrorphone-install"
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("MirrorPhone-Setup-" + [Guid]::NewGuid().ToString("N"))
$zipPath = Join-Path $tempRoot "mirrorPhone.zip"

Write-Step "Source: $SourceRepo@$SourceRef"
Write-Step "Install root: $InstallRoot"

$installMode = "install"
if (Test-Path -LiteralPath $InstallRoot) {
    $installMode = if (Test-Path -LiteralPath $markerPath) { "update" } else { "adopt-update" }
}

New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

try {
    if (Test-Path -LiteralPath $SourceZipPath) {
        Write-Step "Using bundled mirrorPhone source: $SourceZipPath"
        Copy-Item -LiteralPath $SourceZipPath -Destination $zipPath -Force
        $sourceMode = "bundled-zip"
    } else {
        $sourceZipUrl = Get-SourceZipUrl -Repo $SourceRepo -Ref $SourceRef
        Write-Step "Bundled source was not found. Downloading mirrorPhone source..."
        Write-Step "Source URL: $sourceZipUrl"
        try {
            Invoke-WebRequest -UseBasicParsing -Uri $sourceZipUrl -OutFile $zipPath
            $sourceMode = "github-archive"
        } catch {
            Stop-WithMessage "Could not download mirrorPhone source. For the default private repository, keep mirrorPhone-source.zip next to this script or use the EXE installer. Details: $($_.Exception.Message)"
        }
    }

    Write-Step "Extracting source..."
    Expand-Archive -LiteralPath $zipPath -DestinationPath $tempRoot -Force

    $sourceDir = Get-ChildItem -LiteralPath $tempRoot -Directory |
        Where-Object { $_.Name -ne "__MACOSX" } |
        Select-Object -First 1

    if (-not $sourceDir) {
        Stop-WithMessage "Could not find extracted mirrorPhone source directory."
    }

    if (Test-Path -LiteralPath $InstallRoot) {
        if (Test-Path -LiteralPath $markerPath) {
            Write-Step "Updating previous MirrorPhone install..."
        } else {
            Write-Step "Existing MirrorPhone folder found. Adopting it as an update target..."
        }
        Clear-InstallSourceFiles -Path $InstallRoot
    }

    Write-Step "Copying files..."
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $InstallRoot) | Out-Null
    Copy-Item -LiteralPath $sourceDir.FullName -Destination $InstallRoot -Recurse -Force

    Set-Content -LiteralPath $markerPath -Value @(
        "repo=$SourceRepo"
        "ref=$SourceRef"
        "source=$sourceMode"
        "mode=$installMode"
        "installedAt=$(Get-Date -Format o)"
    )

    Write-Step "Installing npm dependencies..."
    Push-Location $InstallRoot
    try {
        & npm install
        if ($LASTEXITCODE -ne 0) {
            Stop-WithMessage "npm install failed with exit code $LASTEXITCODE."
        }

        Ensure-ElectronBinary -Path $InstallRoot

        $packageJsonPath = Join-Path $InstallRoot "package.json"
        if ((Test-Path -LiteralPath $packageJsonPath) -and ((Get-Content -Raw -LiteralPath $packageJsonPath) -match '"setup:airplay"')) {
            Write-Step "Installing AirPlay receiver engine..."
            & npm run setup:airplay
            if ($LASTEXITCODE -ne 0) {
                Stop-WithMessage "npm run setup:airplay failed with exit code $LASTEXITCODE."
            }
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

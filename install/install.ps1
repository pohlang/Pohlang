[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Repo = 'AlhaqGH/PohLang'
$DefaultVersion = 'v0.6.7'
$BinName = 'pohlang.exe'

function Write-Info([string] $Message) { Write-Host $Message -ForegroundColor Cyan }
function Write-Success([string] $Message) { Write-Host $Message -ForegroundColor Green }
function Write-Warn([string] $Message) { Write-Host $Message -ForegroundColor Yellow }

$version = $env:POHLANG_VERSION
if (-not [string]::IsNullOrWhiteSpace($version)) {
    if ($version -notmatch '^v') { $version = "v$version" }
} else {
    try {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -UseBasicParsing
        $version = $release.tag_name
        if (-not $version) { throw 'missing tag_name' }
    } catch {
        Write-Warn "Could not determine the latest release automatically. Falling back to $DefaultVersion."
        $version = $DefaultVersion
    }
}

if ($version -notmatch '^v') { $version = "v$version" }

$arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
switch ($arch) {
    'X64'   { $platform = 'windows-x64' }
    'Arm64' {
        Write-Warn 'Prebuilt Windows ARM64 binaries are not available yet. Build from source instead.'
        return
    }
    default { throw "Unsupported architecture: $arch" }
}

$assetName = "pohlang-$version-$platform.zip"
$downloadUrl = "https://github.com/$Repo/releases/download/$version/$assetName"

$TempDir = Join-Path ([System.IO.Path]::GetTempPath()) "pohlang-install-$(Get-Random)"
New-Item -ItemType Directory -Force -Path $TempDir | Out-Null

try {
    $zipPath = Join-Path $TempDir 'pohlang.zip'
    Write-Info "Downloading $assetName..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing

    Write-Info 'Extracting package...'
    $extractDir = Join-Path $TempDir 'extracted'
    Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force

    $binaryPath = Join-Path $extractDir $BinName
    if (-not (Test-Path $binaryPath)) {
        throw "Downloaded archive did not contain $BinName"
    }

    $customInstall = $env:POHLANG_INSTALL_DIR
    if (-not [string]::IsNullOrWhiteSpace($customInstall)) {
        $installDir = $customInstall
    } else {
        $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            $installDir = 'C:\Program Files\PohLang'
        } else {
            $installDir = Join-Path $env:LOCALAPPDATA 'PohLang'
        }
    }

    if (-not (Test-Path $installDir)) {
        Write-Info "Creating $installDir..."
        New-Item -ItemType Directory -Force -Path $installDir | Out-Null
    }

    $targetPath = Join-Path $installDir $BinName
    Write-Info "Installing to $targetPath..."
    Copy-Item -Path $binaryPath -Destination $targetPath -Force

    $currentPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if (-not $currentPath) { $currentPath = '' }
    if ($currentPath -notlike "*$installDir*") {
        Write-Info "Adding $installDir to the user PATH..."
        $newPath = if ($currentPath) { "$currentPath;$installDir" } else { $installDir }
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    }

    Write-Success 'PohLang installed successfully.'
    Write-Host "Binary location: $targetPath" -ForegroundColor Gray

    try {
        & $targetPath --version | Write-Host
    } catch {
        Write-Warn 'Unable to run pohlang --version automatically. Open a new terminal and try again.'
    }

    Write-Info 'Next steps:'
    Write-Host '  1. Open a new PowerShell window (to refresh PATH).' -ForegroundColor Gray
    Write-Host '  2. Run: pohlang --version' -ForegroundColor Gray
    Write-Host '  3. Visit https://github.com/AlhaqGH/PohLang for documentation.' -ForegroundColor Gray
}
finally {
    if (Test-Path $TempDir) {
        Remove-Item -Path $TempDir -Recurse -Force
    }
}

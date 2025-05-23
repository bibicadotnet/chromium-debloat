<#
.SYNOPSIS
    Automated Chromium Installer for Windows
.DESCRIPTION
    This script performs:
    1. Downloads the latest mini_installer.sync.exe from GitHub
    2. Installs Chromium silently
    3. Downloads the registry tweak file
    4. Applies the registry settings
.NOTES
    Compatible with all PowerShell versions
#>

# Set console encoding to UTF-8 for proper character display
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'

# Require Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Configuration
$downloadFolder = "$env:USERPROFILE\Downloads\ChromiumInstall"
$installerPath = "$downloadFolder\mini_installer.sync.exe"

# Create download directory if not exists
if (-not (Test-Path -Path $downloadFolder)) {
    New-Item -ItemType Directory -Path $downloadFolder -Force | Out-Null
}

Write-Host "Checking for latest Chromium version..."
try {
    # Get latest release info
    $releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/Hibbiki/chromium-win64/releases/latest" -TimeoutSec 30
    $asset = $releaseInfo.assets | Where-Object { $_.name -eq "mini_installer.sync.exe" }
    
    if ($asset) {
        $downloadUrl = $asset.browser_download_url
        $fileSizeMB = [math]::Round($asset.size/1MB, 2)
        Write-Host "Downloading Chromium (Size: ${fileSizeMB}MB)..."
        
        # Download with progress tracking
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing
        $stopwatch.Stop()
        
        Write-Host "Download completed in $($stopwatch.Elapsed.Seconds) seconds"
        
        # Silent installation
        Write-Host "Installing Chromium..."
        Start-Process -FilePath $installerPath -ArgumentList "--system-level --do-not-launch-chrome" -Wait -NoNewWindow
        
        # Download registry tweak
        $regFileUrl = "https://raw.githubusercontent.com/bibicadotnet/chromium-debloat/main/disable_chromium_features.reg"
        $regFilePath = "$downloadFolder\disable_chromium_features.reg"
        
        Write-Host "Downloading configuration file..."
        Invoke-WebRequest -Uri $regFileUrl -OutFile $regFilePath -UseBasicParsing
        
        # Apply registry settings
        Write-Host "Applying registry tweaks..."
        Start-Process "regedit.exe" -ArgumentList "/s `"$regFilePath`"" -Wait -NoNewWindow
        
        Write-Host "Chromium installation completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "Installer file not found in the latest release." -ForegroundColor Red
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    $ProgressPreference = 'Continue'
}

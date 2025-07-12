<#
.SYNOPSIS
    Automated Chromium Installer for Windows
.DESCRIPTION
    This script performs:
    1. Downloads the latest mini_installer.sync.exe from GitHub
    2. Installs Chromium silently
    3. Applies the registry settings
.NOTES
    Compatible with all PowerShell versions
#>

# Set console encoding to UTF-8 for proper character display
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'

# Require Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if ([string]::IsNullOrEmpty($PSCommandPath)) {
        Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://go.bibica.net/chromium | iex`"" -Verb RunAs
    } else {
        Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    }
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
        $latestVersion = $releaseInfo.tag_name
        Write-Host "Downloading Chromium $($latestVersion) (Size: ${fileSizeMB}MB)..."
        
        # Download with progress tracking
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        (New-Object System.Net.WebClient).DownloadFile($downloadUrl, $installerPath)
        $stopwatch.Stop()
        
        Write-Host "Download completed in $($stopwatch.Elapsed.Seconds) seconds"
        
        # Silent installation
        Write-Host "Installing Chromium..."
        Start-Process -FilePath $installerPath -ArgumentList "--system-level --do-not-launch-chrome" -Wait -NoNewWindow
        
        # Restoring default policies
        $removeRegFileUrl = "https://raw.githubusercontent.com/bibicadotnet/chromium-debloat/main/remove-chromium-policy.reg"
        $removeRegFilePath = "$downloadFolder\remove-chromium-policy.reg"

        Write-Host "Restoring default Chromium policies..."
        Invoke-WebRequest -Uri $removeRegFileUrl -OutFile $removeRegFilePath -UseBasicParsing

        Start-Process "regedit.exe" -ArgumentList "/s `"$removeRegFilePath`"" -Wait -NoNewWindow

        # Optimizing Chromium policies
        $regFileUrl = "https://raw.githubusercontent.com/bibicadotnet/chromium-debloat/main/disable_chromium_features.reg"
        $regFilePath = "$downloadFolder\disable_chromium_features.reg"
        
        Write-Host "Optimizing Chromium policies..."
        Invoke-WebRequest -Uri $regFileUrl -OutFile $regFilePath -UseBasicParsing

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

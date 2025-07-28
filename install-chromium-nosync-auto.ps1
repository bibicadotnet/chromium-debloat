# Chromium Auto Installer - Compact Version
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'

# Check admin rights
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $cmd = if ([string]::IsNullOrEmpty($PSCommandPath)) { "irm https://go.bibica.net/chromium | iex" } else { "& '$PSCommandPath'" }
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command $cmd" -Verb RunAs
    exit
}

# Stop only Chromium processes (not other Chrome browsers)
Get-Process -Name "chrome" -ErrorAction SilentlyContinue | Where-Object { 
    $_.MainModule.FileName -like "*\Chromium\Application\chrome.exe" 
} | Stop-Process -Force
$folder = "$env:USERPROFILE\Downloads\ChromiumInstall"
$installer = "$folder\mini_installer.nosync.exe"
New-Item -ItemType Directory -Path $folder -Force | Out-Null

try {
    # Download latest Chromium
    Write-Host "Getting latest Chromium Hibbiki Woolyss..." -ForegroundColor Yellow
    $release = Invoke-RestMethod "https://api.github.com/repos/Hibbiki/chromium-win64/releases/latest" -TimeoutSec 30
    $asset = $release.assets | Where-Object { $_.name -eq "mini_installer.nosync.exe" }
    
    if ($asset) {
        Write-Host "Downloading $($release.tag_name) ($([math]::Round($asset.size/1MB, 2))MB)..."
        (New-Object System.Net.WebClient).DownloadFile($asset.browser_download_url, $installer)
        
        # Install
        Write-Host "Installing..." -ForegroundColor Green
        Start-Process $installer -ArgumentList "--system-level --do-not-launch-chrome" -Wait -NoNewWindow
        
        # Apply registry policies
        Write-Host "Applying policies..." -ForegroundColor Cyan
        @(
            "https://raw.githubusercontent.com/bibicadotnet/chromium-debloat/main/remove-chromium-policy.reg",
            "https://raw.githubusercontent.com/bibicadotnet/chromium-debloat/main/disable_chromium_features.reg"
        ) | ForEach-Object {
            $regFile = "$folder\$(Split-Path $_ -Leaf)"
            Invoke-WebRequest $_ -OutFile $regFile -UseBasicParsing
            Start-Process "regedit.exe" "/s `"$regFile`"" -Wait -NoNewWindow
        }
        
        Write-Host "Installation completed!" -ForegroundColor Green
    } else {
        Write-Host "Installer not found!" -ForegroundColor Red
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

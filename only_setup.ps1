# Chromium Auto Installer - Simple Version

Clear-Host
Write-Host " Chromium Browser version Hibbiki Woolyss - Auto Installer " -BackgroundColor DarkGreen

# Stop Chromium processes
Stop-Process -Name "chrome" -Force -ErrorAction SilentlyContinue

# Get latest release info
Write-Host "Getting latest Chromium..."
$release = Invoke-RestMethod "https://api.github.com/repos/Hibbiki/chromium-win64/releases/latest"
$asset = $release.assets | Where-Object { $_.name -eq "mini_installer.exe" }

# Download installer
Write-Host "Downloading $($release.tag_name)..."
(New-Object System.Net.WebClient).DownloadFile($asset.browser_download_url, "$env:TEMP\chromium_installer.exe")

# Install Chromium
Write-Host "Installing..."
Start-Process "$env:TEMP\chromium_installer.exe" -ArgumentList "--system-level --do-not-launch-chrome" -Wait

Write-Host "Chromium Browser version Hibbiki Woolyss installation completed!" -ForegroundColor Green
Write-Host

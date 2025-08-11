# Chromium Auto Installer - Simple Version

# Check admin rights
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://go.bibica.net/chromium | iex`"" -Verb RunAs
    exit
}

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

# Apply registry policy
Write-Host "Applying optimizations..."
(New-Object System.Net.WebClient).DownloadFile("https://raw.githubusercontent.com/bibicadotnet/chromium-debloat/main/disable_chromium_features.reg", "$env:TEMP\optimize.reg")
Start-Process "regedit.exe" -ArgumentList "/s `"$env:TEMP\optimize.reg`"" -Wait -NoNewWindow

# Clean up
Write-Host "Cleaning up temporary files..."
$version = $release.tag_name -replace "v|-.+"
Remove-Item "$env:TEMP\chromium_installer.exe", "$env:TEMP\optimize.reg" -Force -ErrorAction SilentlyContinue
Remove-Item "${env:ProgramFiles}\Chromium\Application\$version\Installer" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Chromium Browser version Hibbiki Woolyss installation completed!" -ForegroundColor Green
Write-Host

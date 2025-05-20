@echo off
powershell -Command "Invoke-WebRequest 'https://go.bibica.net/chromium' -OutFile 'chromium.ps1'; powershell -ExecutionPolicy Bypass -File 'chromium.ps1'"
pause
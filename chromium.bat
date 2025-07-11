@echo off
REM Check for admin privileges
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    ECHO Requesting administrative privileges...
    powershell -Command "Start-Process -FilePath '%~dpnx0' -Verb RunAs"
    EXIT /B
)

powershell -Command "Invoke-WebRequest 'https://go.bibica.net/chromium' -OutFile 'chromium.ps1'; powershell -ExecutionPolicy Bypass -File 'chromium.ps1'"
pause

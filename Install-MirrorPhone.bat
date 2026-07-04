@echo off
setlocal
set "SCRIPT_DIR=%~dp0"

where powershell >nul 2>nul
if errorlevel 1 (
  echo PowerShell was not found.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Install-MirrorPhone.ps1" %*
set "EXIT_CODE=%ERRORLEVEL%"
if not "%EXIT_CODE%"=="0" (
  echo.
  echo Install failed. Exit code: %EXIT_CODE%
  pause
)
exit /b %EXIT_CODE%

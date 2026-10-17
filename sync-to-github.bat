@echo off
title Push Colab Notes to GitHub
pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0sync-to-github.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo PowerShell 7 not found or encountered an error, falling back to Windows PowerShell...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0sync-to-github.ps1"
)
echo.
pause

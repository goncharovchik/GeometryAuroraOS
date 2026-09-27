@echo off
title Setup Aurora OS Flutter Development Environment
chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_environment.ps1" %*
if errorlevel 1 (
    echo.
    echo [WARNING] Setup script completed with an error code or warnings.
    pause
    exit /b 1
)
echo.
pause

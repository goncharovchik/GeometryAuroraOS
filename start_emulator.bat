@echo off
title Запуск эмулятора ОС Аврора
chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0start_emulator.ps1"

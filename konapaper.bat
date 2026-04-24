@echo off
REM =================================================================
REM KONAPAPER - Windows Launcher
REM =================================================================

setlocal

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"

REM Run the PowerShell script with all passed arguments
powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File "%SCRIPT_DIR%konapaper.ps1" %*

endlocal
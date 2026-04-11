@echo off
REM =================================================================
REM KONAPAPER — Windows Launcher
 =================================================================

setlocal

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"

REM Run the PowerShell script with all passed arguments
powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%konapaper.ps1" %*

endlocal

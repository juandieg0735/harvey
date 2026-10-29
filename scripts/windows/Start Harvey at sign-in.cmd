@echo off
rem Double-click to start Harvey every time you sign in to Windows.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-autostart.ps1" %*
pause

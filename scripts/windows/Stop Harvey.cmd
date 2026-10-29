@echo off
rem Double-click to stop Harvey. Nothing queued is lost.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0stop-harvey.ps1"
pause

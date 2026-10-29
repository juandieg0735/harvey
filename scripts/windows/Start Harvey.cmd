@echo off
rem Double-click to start Harvey (dashboard + heartbeat loop) in the background.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-harvey.ps1" %*
if errorlevel 1 pause

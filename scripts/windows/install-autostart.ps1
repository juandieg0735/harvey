<#
.SYNOPSIS
Start Harvey every time you sign in to Windows (a shortcut in your Startup
folder; no administrator rights needed). Run with -Remove to undo.

.DESCRIPTION
Harvey only works while the computer is on and awake: keep it from sleeping
while you want Harvey to prospect and send.
#>
param([switch]$Remove)

$ErrorActionPreference = 'Stop'
$Startup = [Environment]::GetFolderPath('Startup')
$Link = Join-Path $Startup 'Harvey.lnk'

if ($Remove) {
    Remove-Item $Link -ErrorAction SilentlyContinue
    Write-Host "Harvey will no longer start when you sign in."
    exit 0
}

$Script = Join-Path $PSScriptRoot 'start-harvey.ps1'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($Link)
$shortcut.TargetPath = (Get-Command powershell.exe).Source
$shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$Script`" -NoBrowser"
$shortcut.WorkingDirectory = $Root
$shortcut.WindowStyle = 7  # minimized
$shortcut.Description = 'Start Harvey (dashboard and heartbeat loop)'
$shortcut.Save()
Write-Host "Harvey will start when you sign in to Windows."
Write-Host "To undo: run install-autostart.ps1 -Remove"

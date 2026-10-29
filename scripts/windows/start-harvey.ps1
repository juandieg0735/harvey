<#
.SYNOPSIS
Start Harvey on Windows in the background: the dashboard and the heartbeat
loop, without keeping PowerShell windows open.

.DESCRIPTION
Safe to run again: whatever is already running is left alone. Output goes to
data\harvey.log (the loop, the same file the dashboard's Activity log reads)
and data\dashboard.log. Stop everything with stop-harvey.ps1, or just the loop
from the dashboard.

.PARAMETER NoBrowser
Don't open the dashboard in the browser (used when starting at sign-in).
#>
param([switch]$NoBrowser)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Python = Join-Path $Root '.venv\Scripts\python.exe'
$Data = Join-Path $Root 'data'
$LoopLog = Join-Path $Data 'harvey.log'
$DashLog = Join-Path $Data 'dashboard.log'
$PidFile = Join-Path $Data 'harvey.pid'
$Port = 5555

if (-not (Test-Path $Python)) {
    Write-Host "Harvey isn't installed in $Root yet (no .venv). Install it first:"
    Write-Host "  py -3.13 -m venv .venv; .venv\Scripts\Activate.ps1; pip install -e ."
    exit 1
}
New-Item -ItemType Directory -Force -Path $Data | Out-Null

# The Claude installer puts claude.exe in ~\.local\bin without always adding
# it to PATH. Harvey can't write anything without it.
$LocalBin = Join-Path $HOME '.local\bin'
if (-not (Get-Command claude -ErrorAction SilentlyContinue) -and
    (Test-Path (Join-Path $LocalBin 'claude.exe'))) {
    $env:Path = "$LocalBin;$env:Path"
}
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Warning "Claude CLI not found. Harvey will start but stay paused until it is installed and signed in (claude login)."
}
$env:PYTHONUTF8 = '1'

function Test-DashboardUp {
    $client = New-Object System.Net.Sockets.TcpClient
    try { $client.Connect('127.0.0.1', $Port); return $true }
    catch { return $false }
    finally { $client.Close() }
}

function Test-LoopRunning {
    if (-not (Test-Path $PidFile)) { return $false }
    $id = 0
    if (-not [int]::TryParse((Get-Content $PidFile -Raw).Trim(), [ref]$id)) { return $false }
    return [bool](Get-Process -Id $id -ErrorAction SilentlyContinue)
}

# 1. Dashboard
if (Test-DashboardUp) {
    Write-Host "Dashboard: already running."
} else {
    Start-Process -FilePath $Python -ArgumentList '-m', 'harvey', 'dashboard', '--port', $Port `
        -WorkingDirectory $Root -WindowStyle Hidden `
        -RedirectStandardOutput $DashLog -RedirectStandardError "$DashLog.err"
    $deadline = (Get-Date).AddSeconds(30)
    while (-not (Test-DashboardUp) -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 500 }
    if (Test-DashboardUp) {
        Write-Host "Dashboard: started."
    } else {
        Write-Warning "The dashboard didn't come up. See $DashLog.err"
    }
}

# 2. Heartbeat loop. cmd.exe appends its output to the log as plain bytes
# (PowerShell 5's redirection would write UTF-16).
if (Test-LoopRunning) {
    Write-Host "Harvey: already running."
} else {
    $cmdLine = "`"`"$Python`" -m harvey run >> `"$LoopLog`" 2>&1`""
    Start-Process -FilePath $env:ComSpec -ArgumentList '/d', '/s', '/c', $cmdLine `
        -WorkingDirectory $Root -WindowStyle Hidden
    Write-Host "Harvey: started. Its log is $LoopLog"
}

# 3. Open the dashboard. The link carries the unlock token, so it goes
# straight to the browser and is never printed.
if (-not $NoBrowser -and (Test-DashboardUp)) {
    $url = (& $Python -m harvey dashboard --url --port $Port | Select-Object -Last 1).Trim()
    if ($url -like 'http://*') { Start-Process $url }
}

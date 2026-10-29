<#
.SYNOPSIS
Stop Harvey's heartbeat loop and dashboard started by start-harvey.ps1 (or
by hand). Queued emails, replies and everything Harvey found stay in
data\harvey.db; start-harvey.ps1 picks up where it left off.
#>
$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$PidFile = Join-Path $Root 'data\harvey.pid'

# A venv's python.exe is a launcher that starts the real interpreter as a
# child, so match Harvey's processes by command line, not by path.
$procs = Get-CimInstance Win32_Process -Filter "Name = 'python.exe' OR Name = 'harvey.exe'" |
    Where-Object { $_.CommandLine -match '(-m\s+harvey|harvey(\.exe)?"?)\s+(run|dashboard)\b' }

$loopId = 0
if (Test-Path $PidFile) { [void][int]::TryParse((Get-Content $PidFile -Raw).Trim(), [ref]$loopId) }
if ($loopId -and -not ($procs | Where-Object ProcessId -eq $loopId)) {
    $p = Get-CimInstance Win32_Process -Filter "ProcessId = $loopId"
    if ($p) { $procs = @($procs) + $p }
}

if (-not $procs) {
    Write-Host "Harvey isn't running."
    exit 0
}
foreach ($p in $procs) {
    Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
}
Remove-Item $PidFile -ErrorAction SilentlyContinue
Write-Host "Stopped Harvey ($(@($procs).Count) process(es))."

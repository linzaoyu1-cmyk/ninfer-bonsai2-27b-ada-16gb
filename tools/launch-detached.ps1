param(
    [int]$Port = 8080,
    [int]$MaxContext = 90112,
    [int]$KvCapacity = 90112,
    [string]$Log = 'E:\27BB\logs\srv.log',
    [string]$Exe = 'E:\27BB\runtime-vision\ninfer-serve-vision.exe',
    [string]$Extra = '',
    [switch]$Vision
)

$ErrorActionPreference = 'Stop'
$Root = 'E:\27BB'
$model = 'E:\27BB\models\Ternary-Bonsai-2-27B.ninfer'

& (Join-Path $Root 'stop-server.ps1') -Port $Port | Out-Null
Stop-Process -Name 'ninfer-serve-vision' -Force -ErrorAction SilentlyContinue
Stop-Process -Name 'ninfer-serve' -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

$parts = @(
    $Exe, $model,
    '--host', '127.0.0.1',
    '--port', "$Port",
    '--max-context', "$MaxContext",
    '--kv-capacity', "$KvCapacity",
    '--kv-dtype', 'fp8',
    '--max-concurrency', '1',
    '--default-max-tokens', '16384'
)

if ($Vision) { $parts += @('--vision', '--media-cache-mib', '1024', '--media-live-mib', '1024') }
if ($Extra) { $parts += ($Extra -split '\s+' | Where-Object { $_ }) }

$line = ($parts -join ' ') + ' > ' + $Log + ' 2>&1'

# Write a wrapper .cmd so the redirection lives in the child process, then use
# 'start' to give that child its OWN console. Without this, a Ctrl+C in the
# calling shell propagates to the server and kills it.
$wrapper = Join-Path $Root 'logs\run-ninfer.cmd'
Set-Content -Path $wrapper -Value ("@echo off`r`n" + $line) -Encoding ASCII

$cmdline = 'cmd /c start "ninfer-vision" /min "' + $wrapper + '"'
$r = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $cmdline }
Write-Host "launch ReturnValue=$($r.ReturnValue) PID=$($r.ProcessId)"
Write-Host "wrapper: $wrapper"

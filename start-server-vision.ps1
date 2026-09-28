param(
    [string]$HostName = "127.0.0.1",
    [int]$Port = 8080,
    [int]$MaxContext = 252144,
    [int]$KvCapacity = 252144,
    [ValidateSet("bf16", "int8", "fp8", "rk4v4")]
    [string]$KvDtype = "rk4v4",
    [int]$MaxConcurrency = 1,
    [int]$DefaultMaxTokens = 16384,
    [int]$MediaCacheMib = 512,
    [int]$MediaLiveMib = 512,
    [string]$Spec = "mtp",
    [int]$DraftTokens = 3,
    [string]$RequestLog = "",
    [switch]$NoThinking,
    [switch]$DryRun,
    [switch]$Cors
)

$Root = $PSScriptRoot
$Exe = Join-Path $Root "runtime-vision\ninfer-serve-vision.exe"
$Model = Join-Path $Root "models\Ternary-Bonsai-2-27B.ninfer"

if (-not (Test-Path $Exe)) { throw "Vision server not found: $Exe (build it with tools\build-vision.ps1)" }
if (-not (Test-Path $Model)) { throw "Model not found: $Model" }

$Arguments = @(
    $Model,
    "--host", $HostName,
    "--port", $Port,
    "--max-context", $MaxContext,
    "--kv-capacity", $KvCapacity,
    "--kv-dtype", $KvDtype,
    "--max-concurrency", $MaxConcurrency,
    "--default-max-tokens", $DefaultMaxTokens,
    "--spec", $Spec,
    "--draft-tokens", $DraftTokens,
    "--vision",
    "--media-cache-mib", $MediaCacheMib,
    "--media-live-mib", $MediaLiveMib
)

if ($NoThinking) { $Arguments += "--no-thinking" }
if ($RequestLog) { $Arguments += @("--request-log-jsonl", $RequestLog) }
if ($Cors) { $Arguments += "--cors" }

$mode = if ($NoThinking) { "thinking OFF" } else { "thinking ON" }

if ($DryRun) {
    Write-Host "DRY RUN (nothing started). mode = $mode, context = $MaxContext"
    Write-Host ("`"$Exe`" " + ($Arguments -join ' '))
    exit 0
}

# Robust pre-stop: kill whatever ninfer build currently owns the port.
$conns = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
foreach ($c in $conns) {
    $pr = Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue
    if ($pr -and $pr.ProcessName -like "ninfer*") {
        Stop-Process -Id $pr.Id -Force -ErrorAction SilentlyContinue
        Write-Host "stopped $($pr.ProcessName) PID $($pr.Id) (was on port $Port)"
    }
}
Stop-Process -Name "ninfer-serve-vision" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "ninfer-serve" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

Write-Host "starting VISION server on http://${HostName}:${Port} | context $MaxContext | vision ON | $mode"
& $Exe @Arguments
exit $LASTEXITCODE

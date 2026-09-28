param(
    [string]$Prompt = "The capital of France is",
    [string]$Messages,
    [int]$MaxNew = 256,
    [int]$MaxContext = 124096,
    [ValidateSet("bf16", "int8", "fp8")]
    [string]$KvDtype = "fp8",
    [switch]$NoThinking,
    [switch]$Greedy
)

$Root = $PSScriptRoot
$Exe = Join-Path $Root "runtime\ninfer.exe"
$Model = Join-Path $Root "models\Ternary-Bonsai-2-27B.ninfer"

if (-not (Test-Path $Exe)) { throw "找不到 NInfer CLI: $Exe" }
if (-not (Test-Path $Model)) { throw "找不到模型文件: $Model" }

$Arguments = @(
    $Model,
    "--max-new", $MaxNew,
    "--max-context", $MaxContext,
    "--kv-dtype", $KvDtype,
    "--spec", "mtp",
    "--draft-tokens", 2
)

if ($Messages) {
    if (-not (Test-Path $Messages)) { throw "找不到 messages 文件: $Messages" }
    $Arguments += @("--messages", (Resolve-Path $Messages).Path)
} else {
    $Arguments += @("--prompt", $Prompt)
}

if ($NoThinking) { $Arguments += "--no-thinking" }
if ($Greedy) { $Arguments += "--greedy" }

& $Exe @Arguments
exit $LASTEXITCODE

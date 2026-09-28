<#
  verify-speed.ps1  —  NInfer 本地服务体检

  量 prefill / decode / 正确性，并判断「移植版内核」是否生效。
  特点：不重启服务、不改任何文件，只对已运行的服务发 4 次真实请求。

  用法：
    powershell -NoProfile -ExecutionPolicy Bypass -File E:\27BB\tools\verify-speed.ps1
    （可选） -Port 8080  -PrefillGood 1500  -DecodeGood 78
#>
param(
    [string]$HostName = '127.0.0.1',
    [int]$Port = 8080,
    [string]$Model = 'qwen3.8-27b',
    [int]$PrefillGood = 1500,
    [int]$DecodeGood = 78
)

$ErrorActionPreference = 'Continue'
$base = "http://${HostName}:${Port}/v1/chat/completions"
$tmp = $env:TEMP
$noBom = New-Object System.Text.UTF8Encoding($false)

# 约 370 字符的英文段落，重复 N 次来构造长 prompt
$para = 'Ternary quantization maps each weight to one of negative one, zero, or positive one, storing two bits per weight plus one fp16 scale per group of one hundred twenty eight weights, which yields an effective cost of two point one two five bits per weight. '

function Post-Json([hashtable]$body) {
    $json = $body | ConvertTo-Json -Depth 8 -Compress
    $f = Join-Path $tmp 'verify-speed-body.json'
    [System.IO.File]::WriteAllText($f, $json, $noBom)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $raw = curl.exe -s --max-time 300 -X POST $base -H 'Content-Type: application/json' --data-binary ('@' + $f)
    $sw.Stop()
    $obj = $null
    try { $obj = $raw | ConvertFrom-Json } catch { }
    [pscustomobject]@{ Seconds = $sw.Elapsed.TotalSeconds; Raw = $raw; Obj = $obj }
}

Write-Host ''
Write-Host "=== NInfer 体检 @ ${HostName}:${Port} ===" -ForegroundColor Cyan

# 1) 服务在不在
$probe = Post-Json @{ model = $Model; messages = @(@{ role = 'user'; content = 'hi' }); max_tokens = 1; temperature = 0; reasoning_effort = 'none' }
if (-not $probe.Obj) {
    Write-Host '服务        : [X] 连不上或返回异常' -ForegroundColor Red
    Write-Host ("  原始响应   : " + $probe.Raw)
    exit 1
}
Write-Host ("服务        : [OK] " + $Model)

# 2) 正确性
$en = Post-Json @{ model = $Model; messages = @(@{ role = 'user'; content = 'The capital of France is' }); max_tokens = 64; temperature = 0 }
$zh = Post-Json @{ model = $Model; messages = @(@{ role = 'user'; content = '水的沸点是多少？用一句话回答。' }); max_tokens = 64; temperature = 0 }
$enOk = $false
$zhOk = $false
if ($en.Obj -and ($en.Obj.choices[0].message.content -match 'Paris')) { $enOk = $true }
if ($zh.Obj -and ($zh.Obj.choices[0].message.content -match '100')) { $zhOk = $true }
$enTxt = '[X] 英文异常'
$zhTxt = '[X] 中文异常'
if ($enOk) { $enTxt = '[OK] Paris' }
if ($zhOk) { $zhTxt = '[OK] 100C' }
Write-Host ("正确性      : $enTxt  /  $zhTxt")

# 3) prefill
Write-Host 'prefill     :'
$rates = @()
foreach ($reps in @(30, 90)) {
    $prompt = ($para * $reps) + ' How many sentences are above?'
    $r = Post-Json @{ model = $Model; messages = @(@{ role = 'user'; content = $prompt }); max_tokens = 4; temperature = 0; reasoning_effort = 'none' }
    if ($r.Obj) {
        $pt = $r.Obj.usage.prompt_tokens
        $rate = 0
        if ($r.Seconds -gt 0) { $rate = [math]::Round($pt / $r.Seconds, 0) }
        $rates += $rate
        Write-Host ("              {0,6} tok  {1,7:N2} s  ({2,6:N0} tok/s)" -f $pt, $r.Seconds, $rate)
    }
    else {
        Write-Host '              [X] 请求失败' -ForegroundColor Red
    }
}

# 4) decode
$dec = Post-Json @{ model = $Model; messages = @(@{ role = 'user'; content = '以雨夜为题，写一篇800字的散文，不要停下。' }); max_tokens = 800; temperature = 0 }
$decRate = 0
if ($dec.Obj) {
    $ct = $dec.Obj.usage.completion_tokens
    if ($ct -and $dec.Seconds -gt 0) { $decRate = [math]::Round($ct / $dec.Seconds, 1) }
    Write-Host ("decode      : {0,6} tok  {1,7:N2} s  ({2,6:N1} tok/s, 含TTFT)" -f $ct, $dec.Seconds, $decRate)
}
else {
    Write-Host 'decode      : [X] 请求失败' -ForegroundColor Red
}

# 5) 结论
$maxPrefill = 0
if ($rates.Count -gt 0) { $maxPrefill = ($rates | Measure-Object -Maximum).Maximum }
Write-Host ''
if ($maxPrefill -ge $PrefillGood) {
    Write-Host ("结论        : [OK] 移植版内核生效（prefill {0:N0} tok/s >= {1}）" -f $maxPrefill, $PrefillGood) -ForegroundColor Green
}
elseif ($maxPrefill -gt 0) {
    Write-Host ("结论        : [!] prefill 仅 {0:N0} tok/s —— 可能还在用旧 exe（移植版应 >= {1}）" -f $maxPrefill, $PrefillGood) -ForegroundColor Yellow
    Write-Host '              回退/部署：见 E:\27BB\README-部署说明.md'
}
else {
    Write-Host '结论        : [X] 无法完成测量' -ForegroundColor Red
}
Write-Host ''

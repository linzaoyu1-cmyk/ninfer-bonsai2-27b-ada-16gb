param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot),
    [int]$Jobs = [Environment]::ProcessorCount,
    [string]$CudaRoot = 'C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.2',
    [string]$Vcvars = 'C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat'
)
$ErrorActionPreference = 'Stop'
$BuildRoot = Join-Path $Root 'build\ninfer-vision'
$AppsDir = Join-Path $BuildRoot 'apps'
$VenvScripts = Join-Path $Root '.venv\Scripts'

if (-not (Test-Path $Vcvars)) { throw "vcvars64.bat not found: $Vcvars" }

cmd /c "`"$Vcvars`" && set" | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') { Set-Item -Path "Env:$($matches[1])" -Value $matches[2] }
}
$env:CUDA_PATH = $CudaRoot
$env:VSLANG = '1033'
$env:Path = "$VenvScripts;$CudaRoot\bin;$env:Path"

Write-Host "BUILD_START $(Get-Date -Format o) jobs=$Jobs"
& cmake --build $BuildRoot --config Release --parallel $Jobs
if ($LASTEXITCODE -ne 0) { throw 'NInfer vision build failed' }
Write-Host "BUILD_DONE $(Get-Date -Format o)"

foreach ($name in 'avcodec', 'avformat', 'avutil', 'swscale', 'swresample') {
    Get-ChildItem (Join-Path $Root "src\ninfer\ffmpeg\bin\$name-*.dll") -ErrorAction SilentlyContinue | ForEach-Object {
        Copy-Item $_.FullName $AppsDir -Force
    }
}
$srcExe = Join-Path $AppsDir 'ninfer-serve.exe'
if (Test-Path $srcExe) { Move-Item $srcExe (Join-Path $AppsDir 'ninfer-serve-vision.exe') -Force }

$RuntimeVision = Join-Path $Root 'runtime-vision'
New-Item -ItemType Directory -Force -Path $RuntimeVision | Out-Null
Get-ChildItem $AppsDir -Filter '*.exe' -ErrorAction SilentlyContinue | Copy-Item -Destination $RuntimeVision -Force
Get-ChildItem $AppsDir -Filter '*.dll' -ErrorAction SilentlyContinue | Copy-Item -Destination $RuntimeVision -Force
'NINFER_VISION_BUILD_OK'

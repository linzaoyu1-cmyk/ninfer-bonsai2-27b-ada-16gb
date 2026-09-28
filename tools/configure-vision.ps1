param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot),
    [string]$CudaRoot = 'C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.2',
    [string]$Vcvars = 'C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat'
)
$ErrorActionPreference = 'Stop'
$NinferRoot = Join-Path $Root 'src\ninfer'
$BuildRoot = Join-Path $Root 'build\ninfer-vision'
$VenvScripts = Join-Path $Root '.venv\Scripts'

if (-not (Test-Path $Vcvars)) { throw "vcvars64.bat not found: $Vcvars" }
if (-not (Test-Path (Join-Path $CudaRoot 'bin\nvcc.exe'))) { throw "nvcc.exe not found under: $CudaRoot" }
$FfmpegInc = Join-Path $NinferRoot 'ffmpeg\include'
if (-not (Test-Path $FfmpegInc)) { throw "FFmpeg dev package missing: $FfmpegInc  --  see README step 5 (FFmpeg)" }

$Cmake = Join-Path $VenvScripts 'cmake.exe'
if (-not (Test-Path $Cmake)) { $Cmake = Join-Path $Root '.venv\Lib\site-packages\cmake\data\bin\cmake.exe' }
if (-not (Test-Path $Cmake)) { throw "cmake.exe not found under $Root" }

cmd /c "`"$Vcvars`" && set" | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') { Set-Item -Path "Env:$($matches[1])" -Value $matches[2] }
}
$env:CUDA_PATH = $CudaRoot
$env:VSLANG = '1033'
$env:Path = "$VenvScripts;$CudaRoot\bin;$env:Path"

Write-Host "cmake = $Cmake"
& $Cmake -S $NinferRoot -B $BuildRoot -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_CUDA_ARCHITECTURES=89 -DCMAKE_CUDA_COMPILER="$CudaRoot\bin\nvcc.exe" -DNINFER_BUILD_APPS=ON -DNINFER_BUILD_BENCHMARKS=OFF -DNINFER_DISABLE_MEDIA=OFF
if ($LASTEXITCODE -ne 0) { throw 'CMake configure failed' }
Write-Host 'CONFIGURE_OK'

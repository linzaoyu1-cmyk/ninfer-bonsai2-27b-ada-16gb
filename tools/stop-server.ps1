param(
    [int]$Port = 0
)

$ServerIds = @()

if ($Port -gt 0) {
    $Connections = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    foreach ($Connection in $Connections) {
        $Process = Get-Process -Id $Connection.OwningProcess -ErrorAction SilentlyContinue
        if ($Process -and $Process.ProcessName -eq "ninfer-serve") {
            $ServerIds += $Process.Id
        }
    }
} else {
    $ServerIds = @(
        (Get-Process -Name "ninfer-serve" -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty Id)
    )
}

$ServerIds = @($ServerIds | Sort-Object -Unique)

if ($ServerIds.Count -eq 0) {
    if ($Port -gt 0) {
        Write-Output "No ninfer-serve process found on port $Port."
    } else {
        Write-Output "No ninfer-serve process found."
    }
    exit 0
}

foreach ($ServerId in $ServerIds) {
    Stop-Process -Id $ServerId -Force
    Write-Output "Stopped ninfer-serve PID $ServerId."
}

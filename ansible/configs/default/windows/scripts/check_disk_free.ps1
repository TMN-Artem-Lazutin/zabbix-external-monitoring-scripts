param(
    [string]$Drive = "C"
)

$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$($Drive):'"
if (-not $disk -or $disk.Size -eq 0) {
    Write-Error "Drive $Drive`: was not found or has no size information"
    exit 1
}

$freePercent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)
Write-Output $freePercent

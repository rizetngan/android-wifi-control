param(
    [string]$DeviceId,
    [string]$ScrcpyDir,
    [switch]$PreferFixedPort,
    [switch]$DiagnoseOnly
)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$config = Join-Path $root 'config.local.json'
if (Test-Path -LiteralPath $config) {
    $c = Get-Content -LiteralPath $config -Raw -Encoding UTF8 | ConvertFrom-Json
    if (!$DeviceId) { $DeviceId = $c.deviceId }
    if (!$ScrcpyDir) { $ScrcpyDir = $c.scrcpyDir }
    if (!$PSBoundParameters.ContainsKey('PreferFixedPort')) { $PreferFixedPort = [bool]$c.preferFixedPort }
}
if (!$ScrcpyDir) { $ScrcpyDir = Read-Host '请输入 scrcpy 解压目录' }
$ScrcpyDir = (Resolve-Path -LiteralPath $ScrcpyDir).Path
$adb = Join-Path $ScrcpyDir 'adb.exe'
$scrcpy = Join-Path $ScrcpyDir 'scrcpy.exe'
if (!(Test-Path $adb) -or !(Test-Path $scrcpy)) { throw '目录中找不到 adb.exe 或 scrcpy.exe' }
& $adb start-server | Out-Host
function Get-Services {
    foreach ($line in (& $adb mdns services)) {
        if ($line -match '^\s*(.+?)\s+(_adb(?:-tls-connect)?\._tcp)\s+(\d{1,3}(?:\.\d{1,3}){3}:\d+)\s*$') {
            [pscustomobject]@{Name=$Matches[1]; Type=$Matches[2]; Address=$Matches[3]}
        }
    }
}
if (!$DeviceId) {
    Get-Services | Format-Table -AutoSize | Out-Host
    $DeviceId = Read-Host '请输入自己平板的设备序列号（mDNS 名称 adb- 后的设备编号）'
}
if ($DeviceId -notmatch '^[A-Za-z0-9]+$') { throw '设备编号格式不正确' }
function Test-Target([string]$serial) {
    $state = & $adb -s $serial get-state 2>$null
    if ($LASTEXITCODE -ne 0 -or "$state".Trim() -ne 'device') { return $false }
    $actual = & $adb -s $serial shell getprop ro.serialno 2>$null
    return ($LASTEXITCODE -eq 0 -and "$actual".Trim() -eq $DeviceId)
}
function Find-Target {
    $services = @(Get-Services | Where-Object { $_.Name -match ('^adb-' + [regex]::Escape($DeviceId) + '(?:-|$|\s)') })
    $tls = @($services | Where-Object Type -eq '_adb-tls-connect._tcp')
    $fixed = @($services | Where-Object { $_.Type -eq '_adb._tcp' -and $_.Address -match ':5555$' })
    if ($PreferFixedPort) { $candidates = @($fixed) + @($tls) } else { $candidates = @($tls) }
    foreach ($candidate in $candidates) {
        & $adb connect $candidate.Address | Out-Host
        if (Test-Target $candidate.Address) { return $candidate.Address }
    }
    foreach ($line in (& $adb devices)) {
        if ($line -match '^(.+?)\s+device\s*$') {
            $serial = $Matches[1].Trim()
            if ($serial -notmatch ('^adb-' + [regex]::Escape($DeviceId) + '(?:-|$|\s)')) { continue }
            if (Test-Target $serial) { return $serial }
        }
    }
    return $null
}
$target = $null
for ($i=0; $i -lt 3 -and !$target; $i++) {
    $target = Find-Target
    if (!$target -and $i -lt 2) { Start-Sleep -Seconds 3 }
}
if (!$target) {
    throw '未发现已授权的目标设备。请确认同一可信 Wi-Fi、无线调试开启，并使用 adb pair 完成首次配对。'
}
Write-Host "已连接目标设备: $target" -ForegroundColor Green
if ($DiagnoseOnly) { exit 0 }
& $scrcpy -s $target
exit $LASTEXITCODE

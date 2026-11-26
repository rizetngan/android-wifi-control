$ErrorActionPreference = 'Stop'
$desktop = [Environment]::GetFolderPath('DesktopDirectory')
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut((Join-Path $desktop '荣耀平板无线控制.lnk'))
$shortcut.TargetPath = Join-Path $PSScriptRoot 'Start-HonorPad.bat'
$shortcut.WorkingDirectory = $PSScriptRoot
$config = Join-Path $PSScriptRoot 'config.local.json'
if (Test-Path $config) {
    $c = Get-Content -LiteralPath $config -Raw -Encoding UTF8 | ConvertFrom-Json
    $exe = Join-Path $c.scrcpyDir 'scrcpy.exe'
    if (Test-Path $exe) { $shortcut.IconLocation = "$exe,0" }
}
$shortcut.Description = '连接已授权的荣耀平板'
$shortcut.Save()
Write-Host '桌面快捷方式已创建。'

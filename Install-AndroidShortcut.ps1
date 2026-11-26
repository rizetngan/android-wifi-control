$ErrorActionPreference='Stop'
$desktop=[Environment]::GetFolderPath('DesktopDirectory')
$w=New-Object -ComObject WScript.Shell
$s=$w.CreateShortcut((Join-Path $desktop 'Android WiFi Control.lnk'))
$s.TargetPath=Join-Path $PSScriptRoot 'Start-AndroidControl.bat'
$s.WorkingDirectory=$PSScriptRoot
$s.Description='Android WiFi Control'
$s.Save()
Write-Host 'Desktop shortcut created.'

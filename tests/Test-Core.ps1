param([string]$ScrcpyDir)
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot '..\AndroidControl.psm1') -Force
function Assert($condition,$message){if(!$condition){throw $message}}
$d=@(ConvertFrom-AdbDevices @('List of devices attached','USB123 device product:a','adb-XYZ (2)._adb-tls-connect._tcp device model:Pixel','OTHER unauthorized','lost offline'))
Assert ($d.Count -eq 4) 'Device parsing'
Assert ($d[1].Transport -eq 'adb-XYZ (2)._adb-tls-connect._tcp') 'Spaces in transport'
Assert ($d[2].State -eq 'unauthorized') 'Authorization state'
$s=@(ConvertFrom-AdbMdns @('adb-XYZ (2) _adb-tls-connect._tcp 192.0.2.10:12345','adb-XYZ _adb._tcp 192.0.2.10:5555','adb-XYZ-pair _adb-tls-pairing._tcp [fe80::1]:1234'))
Assert ($s.Count -eq 3) 'mDNS parse'
Assert ($s[0].Name -eq 'adb-XYZ (2)') 'mDNS spaces'
Assert (Test-Endpoint '192.0.2.10:5555') 'IPv4'
Assert (Test-Endpoint '[fe80::1]:1234') 'IPv6'
Assert (!(Test-Endpoint '192.0.2.1:65536')) 'Invalid port'
Assert (!(Test-Endpoint '999.0.0.1:5555')) 'Invalid IP'
if($ScrcpyDir){
 $live=@(Get-AndroidDevices (Join-Path $ScrcpyDir 'adb.exe'))
 Assert (@($live|Where-Object {$_.State -eq 'device' -and $_.Serial -and $_.Model}).Count -gt 0) 'Live authorized device metadata'
 $live|Select-Object Brand,Model,Android,State,Kind|Format-Table
 Write-Host 'Live device metadata PASS'
}
Write-Host 'Core tests PASS'

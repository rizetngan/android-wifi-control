param(
 [switch]$DownloadOnly,
 [string]$InstallDir=(Join-Path $env:LOCALAPPDATA 'Programs\AndroidWiFiControl'),
 [switch]$NoLaunch
)
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
$headers=@{'User-Agent'='AndroidWiFiControlInstaller';'Accept'='application/vnd.github+json'}
$release=Invoke-RestMethod -Uri 'https://api.github.com/repos/rizetngan/android-wifi-control/releases/latest' -Headers $headers
if($release.draft -or $release.prerelease -or $release.tag_name -notmatch '^v\d+\.\d+\.\d+$'){throw 'No stable release found.'}
$name='Android-WiFi-Control-'+$release.tag_name+'-Windows.zip'
$asset=@($release.assets|Where-Object name -eq $name)
$sums=@($release.assets|Where-Object name -eq 'SHA256SUMS.txt')
if($asset.Count -ne 1 -or $sums.Count -ne 1){throw 'Release package or SHA256SUMS.txt missing.'}
$downloadRoot='https://github.com/rizetngan/android-wifi-control/releases/download/'+$release.tag_name+'/'
if($asset[0].browser_download_url -ne ($downloadRoot+$name) -or $sums[0].browser_download_url -ne ($downloadRoot+'SHA256SUMS.txt')){throw 'Unexpected release download URL.'}
$temp=Join-Path $env:TEMP ('android-wifi-control-'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp|Out-Null
$zip=Join-Path $temp $name
$checksum=Join-Path $temp 'SHA256SUMS.txt'
try{
 Invoke-WebRequest -UseBasicParsing -Uri $asset[0].browser_download_url -OutFile $zip
 Invoke-WebRequest -UseBasicParsing -Uri $sums[0].browser_download_url -OutFile $checksum
 $pattern='^([a-fA-F0-9]{64})\s+\*?'+[regex]::Escape($name)+'$'
 $expected=@(Get-Content -LiteralPath $checksum | ForEach-Object {if($_ -match $pattern){$Matches[1].ToLowerInvariant()}})
 if($expected.Count -ne 1 -or (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expected[0]){throw 'SHA-256 verification failed.'}
 Write-Host ('Verified '+$release.tag_name+' SHA-256 '+$expected[0])
 if($DownloadOnly){Write-Host ('Downloaded: '+$zip);return}
 $stage=Join-Path $temp 'stage'
 Expand-Archive -LiteralPath $zip -DestinationPath $stage
 $files=@('Android-WiFi-Control.ps1','AndroidControl.psm1','Install-AndroidShortcut.ps1','Start-AndroidControl.bat','README.md')
 if([version]$release.tag_name.TrimStart('v') -ge [version]'2.1.0'){$files+= 'Scrcpy-Session.ps1'}
 foreach($file in $files){if(!(Test-Path -LiteralPath (Join-Path $stage $file) -PathType Leaf)){throw ('Missing package file: '+$file)}}
 $running=@(Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" | Where-Object {$_.ProcessId -ne $PID -and $_.CommandLine -match 'Android-WiFi-Control\.ps1'})
 if($running.Count){throw 'Close Android WiFi Control before installing or updating. No running application was stopped.'}
 New-Item -ItemType Directory -Force -Path $InstallDir|Out-Null
 foreach($file in $files){Copy-Item -LiteralPath (Join-Path $stage $file) -Destination (Join-Path $InstallDir $file) -Force}
 & (Join-Path $InstallDir 'Install-AndroidShortcut.ps1')
 Write-Host ('Installed: '+$InstallDir)
 Write-Host 'Existing android.local.json was preserved. Select your official scrcpy folder in the app on first use.'
 if(!$NoLaunch){Start-Process -FilePath (Join-Path $InstallDir 'Start-AndroidControl.bat') -WorkingDirectory $InstallDir}
}finally{
 if(!$DownloadOnly){Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue}
}

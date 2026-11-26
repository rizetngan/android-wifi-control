$ErrorActionPreference='Stop'
function ConvertFrom-AdbDevices([string[]]$Lines) {
 foreach($line in $Lines){
  if($line -match '^\s*(.+?)\s+(device|offline|unauthorized|no permissions)(?:\s+.*)?$' -and $line -notmatch '^List of devices'){
   [pscustomobject]@{Transport=$Matches[1];State=$Matches[2]}
  }
 }
}
function ConvertFrom-AdbMdns([string[]]$Lines) {
 foreach($line in $Lines){
  if($line -match '^\s*(.+?)\s+(_adb(?:-tls-(?:connect|pairing))?\._tcp\.?)\s+(\S+:\d+)\s*$'){
   [pscustomobject]@{Name=$Matches[1];Type=$Matches[2].TrimEnd('.');Address=$Matches[3]}
  }
 }
}
function Test-Endpoint([string]$Endpoint) {
 if($Endpoint -notmatch '^(?:\d{1,3}(?:\.\d{1,3}){3}|\[[0-9a-fA-F:%]+\]):(\d{1,5})$'){return $false}
 $port=[int]$Matches[1]; $ip=$null
 return ($port -ge 1 -and $port -le 65535 -and [Net.IPAddress]::TryParse($Endpoint.Substring(0,$Endpoint.LastIndexOf(':')).Trim('[',']'),[ref]$ip))
}
function Invoke-Adb([string]$Adb,[string[]]$Arguments,[int]$TimeoutMs=8000){
 $quoted=($Arguments|ForEach-Object{if($_ -match '["\r\n]'){throw 'Invalid argument'}; '"'+$_+'"'}) -join ' '
 $psi=New-Object Diagnostics.ProcessStartInfo
 $psi.FileName=$Adb;$psi.Arguments=$quoted;$psi.UseShellExecute=$false;$psi.CreateNoWindow=$true
 $psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
 $p=[Diagnostics.Process]::Start($psi)
 try{
  $out=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync()
  if(!$p.WaitForExit($TimeoutMs)){$p.Kill();throw 'ADB timeout'}
  $p.WaitForExit()
  if($p.ExitCode -ne 0){throw ($err.Result+$out.Result).Trim()}
  $out.Result
 }finally{$p.Dispose()}
}
function Get-AndroidDevices([string]$Adb){
 foreach($d in @(ConvertFrom-AdbDevices ((Invoke-Adb $Adb @('devices','-l')) -split '\r?\n'))){
  $map=@{}
  if($d.State -eq 'device'){
   try{foreach($line in ((Invoke-Adb $Adb @('-s',$d.Transport,'shell','getprop') 5000) -split '\r?\n')){
    if($line -match '^\[([^\]]+)\]: \[(.*)\]$'){$map[$Matches[1]]=$Matches[2]}
   }}catch{}
  }
  $serial=[string]$map['ro.serialno'];if(!$serial){$serial=[string]$map['ro.boot.serialno']}
  $kind=if($d.Transport -match '_adb-tls-connect'){'TLS'}elseif($d.Transport -match ':\d+$'){'Wi-Fi'}else{'USB'}
  [pscustomobject]@{Serial=$serial;Brand=[string]$map['ro.product.manufacturer'];Model=[string]$map['ro.product.model'];Android=[string]$map['ro.build.version.release'];Transport=$d.Transport;State=$d.State;Kind=$kind}
 }
}
function Connect-AndroidEndpoint([string]$Adb,[string]$Endpoint){
 if(!(Test-Endpoint $Endpoint)){throw 'Use IP:port (IPv6 in brackets)'}
 $r=Invoke-Adb $Adb @('connect',$Endpoint)
 if($r -notmatch '(?im)^(?:already )?connected to '){throw $r.Trim()}
 $r.Trim()
}
function Pair-AndroidEndpoint([string]$Adb,[string]$Endpoint,[string]$Code){
 if(!(Test-Endpoint $Endpoint) -or $Code -notmatch '^\d{6}$'){throw 'Check pairing IP:port and six-digit code'}
 $r=Invoke-Adb $Adb @('pair',$Endpoint,$Code)
 if($r -notmatch 'Successfully paired'){throw $r.Trim()}
 $r.Trim()
}
function Restore-AndroidDevices([string]$Adb,[object[]]$Saved){
 $current=@(Get-AndroidDevices $Adb)
 $services=@(ConvertFrom-AdbMdns ((Invoke-Adb $Adb @('mdns','services')) -split '\r?\n'))
 foreach($d in $Saved){
  if(!$d.Serial -or @($current|Where-Object {$_.Serial -eq $d.Serial -and $_.State -eq 'device'}).Count){continue}
  $prefix='^adb-'+[regex]::Escape($d.Serial)+'(?:-|$|\s)'
  foreach($s in @($services|Where-Object {$_.Type -eq '_adb-tls-connect._tcp' -and $_.Name -match $prefix})){
   try{$null=Connect-AndroidEndpoint $Adb $s.Address;$current=@(Get-AndroidDevices $Adb);if(@($current|Where-Object {$_.Serial -eq $d.Serial -and $_.State -eq 'device'}).Count){break}}catch{}
  }
 }
 Get-AndroidDevices $Adb
}
Export-ModuleMember -Function *

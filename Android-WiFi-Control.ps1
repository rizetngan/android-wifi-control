param([string]$ScrcpyDir,[switch]$SmokeTest,[switch]$IntegrationTest)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase,System.Windows.Forms
Import-Module (Join-Path $PSScriptRoot 'AndroidControl.psm1') -Force -DisableNameChecking
$root=$PSScriptRoot
$local=Join-Path $root 'android.local.json'
$settings=[ordered]@{scrcpyDir='';devices=@();autoReconnect=$true}
if(Test-Path $local){$c=Get-Content $local -Raw -Encoding UTF8|ConvertFrom-Json;$settings.scrcpyDir=$c.scrcpyDir;$settings.devices=@($c.devices);$settings.autoReconnect=[bool]$c.autoReconnect}
if($ScrcpyDir){$settings.scrcpyDir=$ScrcpyDir}
function Save-Settings{$settings|ConvertTo-Json -Depth 5|Set-Content $local -Encoding UTF8}
[xml]$xml=@'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="Android WiFi Control" Width="860" Height="600" MinWidth="760" MinHeight="530" Background="#F4F5F7" WindowStartupLocation="CenterScreen" FontFamily="Segoe UI, Microsoft YaHei UI" FontSize="14">
<Window.Resources><Style TargetType="Button"><Setter Property="Padding" Value="14,8"/><Setter Property="Margin" Value="0,0,8,0"/><Setter Property="Background" Value="White"/><Setter Property="BorderBrush" Value="#D5D9E1"/><Setter Property="Cursor" Value="Hand"/><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="Bd" CornerRadius="7" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="1" Padding="{TemplateBinding Padding}"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Opacity" Value="0.8"/></Trigger><Trigger Property="IsEnabled" Value="False"><Setter TargetName="Bd" Property="Opacity" Value="0.45"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style></Window.Resources>
<Grid Margin="26"><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
<DockPanel Margin="0,0,0,18"><Button x:Name="Folder" Content="scrcpy 设置" DockPanel.Dock="Right" VerticalAlignment="Center"/><StackPanel><TextBlock Text="Android WiFi Control" FontSize="28" FontWeight="SemiBold" Foreground="#1C2635"/><TextBlock x:Name="Location" FontSize="12" Foreground="#667085" Margin="0,4,0,0"/></StackPanel></DockPanel>
<Border Grid.Row="1" Background="White" CornerRadius="10" Padding="16" Margin="0,0,0,12" BorderBrush="#E0E4EA" BorderThickness="1"><StackPanel><TextBlock Text="添加设备" FontWeight="SemiBold" Margin="0,0,0,10"/><WrapPanel><ComboBox x:Name="Endpoint" IsEditable="True" Width="220" Padding="6,7" Margin="0,0,8,0" ToolTip="IP:端口（下拉显示局域网发现地址）" AutomationProperties.Name="连接或配对地址"/><PasswordBox x:Name="Code" Width="100" Padding="9,7" Margin="0,0,8,0" MaxLength="6" ToolTip="六位配对码" AutomationProperties.Name="配对码"/><Button x:Name="Pair" Content="配对"/><Button x:Name="Connect" Content="连接"/><Button x:Name="Refresh" Content="刷新"/></WrapPanel><TextBlock Text="首次配对填写设备显示的配对地址与六位码；连接时使用无线调试主页的连接地址。" Foreground="#667085" FontSize="12" TextWrapping="Wrap" Margin="0,10,0,0"/></StackPanel></Border>
<Border Grid.Row="2" Background="White" CornerRadius="10" Padding="14" BorderBrush="#E0E4EA" BorderThickness="1"><DockPanel><TextBlock Text="我的设备" FontWeight="SemiBold" FontSize="16" DockPanel.Dock="Top" Margin="0,0,0,12"/><ListView x:Name="Devices" BorderThickness="0" SelectionMode="Single"><ListView.View><GridView><GridViewColumn Header="设备" Width="170" DisplayMemberBinding="{Binding Display}"/><GridViewColumn Header="Android" Width="75" DisplayMemberBinding="{Binding Android}"/><GridViewColumn Header="连接方式" Width="85" DisplayMemberBinding="{Binding Kind}"/><GridViewColumn Header="状态" Width="100" DisplayMemberBinding="{Binding Status}"/><GridViewColumn Header="设备标识" Width="210" DisplayMemberBinding="{Binding Identity}"/></GridView></ListView.View></ListView></DockPanel></Border>
<DockPanel Grid.Row="3" Margin="0,14,0,10"><CheckBox x:Name="Auto" Content="自动恢复已保存设备" DockPanel.Dock="Right" VerticalAlignment="Center"/><StackPanel Orientation="Horizontal"><Button x:Name="Open" Content="打开控制" Background="#275DDD" Foreground="White" BorderBrush="#275DDD"/><Button x:Name="Remember" Content="保存设备"/><Button x:Name="Forget" Content="移除记录"/><Button x:Name="Guide" Content="连接帮助"/></StackPanel></DockPanel>
<TextBlock Grid.Row="4" x:Name="Status" Foreground="#536174" FontSize="12" TextWrapping="Wrap" Text="就绪"/>
</Grid></Window>
'@
$win=[Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xml))
foreach($name in @('Folder','Location','Endpoint','Code','Pair','Connect','Refresh','Devices','Auto','Open','Remember','Forget','Guide','Status')){Set-Variable -Name $name -Value $win.FindName($name)}
$Auto.IsChecked=$settings.autoReconnect
$script:job=$null;$script:busy=$false;$script:nextScan=[DateTime]::UtcNow
function Get-AdbPath{if($settings.scrcpyDir){$p=Join-Path $settings.scrcpyDir 'adb.exe';if((Test-Path $p) -and (Test-Path (Join-Path $settings.scrcpyDir 'scrcpy.exe'))){return $p}}}
function Update-Location{$Location.Text=if(Get-AdbPath){$settings.scrcpyDir}else{'请选择 scrcpy 解压目录'}}
function Set-Busy([bool]$busy){$script:busy=$busy;foreach($b in @($Folder,$Pair,$Connect,$Refresh,$Open,$Remember,$Forget)){$b.IsEnabled=!$busy}}
function Update-List($rows){
 $selected=$Devices.SelectedItem;$items=@();$seen=@{}
 foreach($d in @($rows|Sort-Object @{Expression={if($_.Kind -eq 'TLS'){0}elseif($_.Kind -eq 'USB'){1}else{2}}})){
  if(!$d){continue};$key=if($d.Serial){$d.Serial}else{$d.Transport}
  if($seen.ContainsKey($key)){continue};$seen[$key]=$true
  $display=("$($d.Brand) $($d.Model)").Trim();if(!$display){$display=$d.Transport}
  $items += [pscustomobject]@{Display=$display;Android=$d.Android;Kind=$d.Kind;Status=if($d.State -eq 'device'){'已连接'}else{$d.State};Identity=$key;Serial=$d.Serial;Transport=$d.Transport;State=$d.State}
 }
 foreach($d in @($settings.devices)){if($d.Serial -and !$seen.ContainsKey($d.Serial)){$items += [pscustomobject]@{Display=$d.Display;Android=$d.Android;Kind='—';Status='未连接';Identity=$d.Serial;Serial=$d.Serial;Transport='';State='offline'}}}
 $Devices.ItemsSource=@($items)
 if($selected){$match=@($items|Where-Object Identity -eq $selected.Identity);if($match.Count){$Devices.SelectedItem=$match[0]}}
 if(!$Devices.SelectedItem -and $items.Count){$Devices.SelectedIndex=0}
}
function Start-Action([string]$action,[string]$address='',[string]$code=''){
 if($script:busy){return};$adb=Get-AdbPath;if(!$adb){$Status.Text='请先设置 scrcpy 目录。';return}
 Set-Busy $true;$Status.Text='正在检查设备…'
 $saved=ConvertTo-Json -InputObject @($settings.devices) -Depth 5 -Compress
 $script:job=Start-Job -ArgumentList (Join-Path $root 'AndroidControl.psm1'),$adb,$action,$address,$code,$saved,([bool]$Auto.IsChecked) -ScriptBlock {
  param($module,$adb,$action,$address,$code,$saved,$auto)
  $ErrorActionPreference='Stop';Import-Module $module -Force -DisableNameChecking;$msg=''
  if($action -eq 'pair'){$msg=Pair-AndroidEndpoint $adb $address $code}
  if($action -eq 'connect'){$msg=Connect-AndroidEndpoint $adb $address}
  $list=@(ConvertFrom-Json $saved)
  $rows=if($auto -and $list.Count){@(Restore-AndroidDevices $adb $list)}else{@(Get-AndroidDevices $adb)}
  try{$services=@(ConvertFrom-AdbMdns ((Invoke-Adb $adb @('mdns','services')) -split '\r?\n'))}catch{$services=@()}; [pscustomobject]@{Message=$msg;Rows=@($rows);Services=@($services)}
 }
}
$Folder.Add_Click({
 $dlg=New-Object System.Windows.Forms.FolderBrowserDialog;$dlg.Description='选择包含 adb.exe 和 scrcpy.exe 的目录'
 if($settings.scrcpyDir){$dlg.SelectedPath=$settings.scrcpyDir}
 if($dlg.ShowDialog() -eq 'OK'){
  if((Test-Path (Join-Path $dlg.SelectedPath 'adb.exe')) -and (Test-Path (Join-Path $dlg.SelectedPath 'scrcpy.exe'))){$settings.scrcpyDir=$dlg.SelectedPath;Save-Settings;Update-Location;Start-Action scan}else{$Status.Text='目录缺少 adb.exe 或 scrcpy.exe。'}
 }
})
$Pair.Add_Click({$p=$Code.Password;$Code.Clear();Start-Action pair $Endpoint.Text.Trim() $p})
$Connect.Add_Click({Start-Action connect $Endpoint.Text.Trim()})
$Refresh.Add_Click({Start-Action scan})
$Auto.Add_Click({$settings.autoReconnect=[bool]$Auto.IsChecked;Save-Settings})
$Remember.Add_Click({$d=$Devices.SelectedItem;if(!$d -or $d.State -ne 'device' -or !$d.Serial){$Status.Text='请选择已连接的设备。';return};$settings.devices=@($settings.devices|Where-Object Serial -ne $d.Serial)+@([pscustomobject]@{Serial=$d.Serial;Display=$d.Display;Android=$d.Android});Save-Settings;$Status.Text='已保存设备。'})
$Forget.Add_Click({$d=$Devices.SelectedItem;if($d){$settings.devices=@($settings.devices|Where-Object Serial -ne $d.Serial);Save-Settings;Start-Action scan}})
function Open-Selected{
 $d=$Devices.SelectedItem;if($script:busy){return}
 if(!$d -or $d.State -ne 'device'){$Status.Text='请选择在线设备。';return}
 try{
  $actual=@(Get-AndroidDevices (Get-AdbPath)|Where-Object {$_.Transport -eq $d.Transport -and $_.State -eq 'device'})
  if(!$actual.Count -or ($d.Serial -and $actual[0].Serial -ne $d.Serial)){throw '设备已断开或标识变化，请刷新。'}
  if($d.Transport -match '["\r\n]'){throw 'Invalid transport'}
  Start-Process -FilePath (Join-Path $settings.scrcpyDir 'scrcpy.exe') -WorkingDirectory $settings.scrcpyDir -ArgumentList ('-s "'+$d.Transport+'"')
  $Status.Text='已启动控制窗口。'
 }catch{$Status.Text=$_.Exception.Message}
}
$Open.Add_Click({Open-Selected});$Devices.Add_MouseDoubleClick({Open-Selected})
$Guide.Add_Click({Start-Process (Join-Path $root 'README.md')})
$timer=New-Object Windows.Threading.DispatcherTimer;$timer.Interval=[TimeSpan]::FromMilliseconds(350)
$timer.Add_Tick({
 if($script:job -and $script:job.State -in @('Completed','Failed','Stopped')){
  try{$r=Receive-Job $script:job -ErrorAction Stop;if($script:job.State -ne 'Completed'){throw 'ADB operation failed'};Update-List @($r.Rows);$typed=$Endpoint.Text;$Endpoint.ItemsSource=@($r.Services|Where-Object {$_.Type -in @('_adb-tls-connect._tcp','_adb-tls-pairing._tcp')}|Select-Object -ExpandProperty Address -Unique);$Endpoint.Text=$typed;$Status.Text=if($r.Message){$r.Message}else{'设备状态已更新'}}catch{$Status.Text=$_.Exception.Message}
  finally{Remove-Job $script:job -Force;$script:job=$null;Set-Busy $false;$script:nextScan=[DateTime]::UtcNow.AddSeconds(12)}
 }
 if(!$script:busy -and (Get-AdbPath) -and [DateTime]::UtcNow -ge $script:nextScan){Start-Action scan}
})
$win.Add_Closed({$timer.Stop();if($script:job){Stop-Job $script:job -ErrorAction SilentlyContinue;Remove-Job $script:job -Force -ErrorAction SilentlyContinue}})
Update-Location
if($SmokeTest){Write-Output 'WPF XAML and event binding OK';return}
if($IntegrationTest){
 $script:integrationPassed=$false
 $watch=New-Object Windows.Threading.DispatcherTimer
 $watch.Interval=[TimeSpan]::FromMilliseconds(300)
 $deadline=[DateTime]::UtcNow.AddSeconds(25)
 $watch.Add_Tick({
  if($Devices.Items.Count -gt 0 -and !$script:busy){
   $online=@($Devices.Items|Where-Object {$_.State -eq 'device' -and $_.Serial -and $_.Android})
   if($online.Count -gt 0 -and @($online|Group-Object Serial|Where-Object Count -gt 1).Count -eq 0){
    $script:integrationPassed=$true
    Write-Output ('GUI online unique devices: '+$online.Count)
    $watch.Stop();$win.Close()
   }
  }
  if([DateTime]::UtcNow -gt $deadline){$watch.Stop();$win.Close()}
 })
 $watch.Start()
}
$timer.Start();$null=$win.ShowDialog()
if($IntegrationTest){if(!$script:integrationPassed){throw 'GUI integration failed'};Write-Output 'GUI refresh and dedup PASS'}

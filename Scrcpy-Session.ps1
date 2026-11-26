param(
 [Parameter(Mandatory=$true)][string]$ScrcpyDir,
 [Parameter(Mandatory=$true)][string]$Transport,
 [Parameter(Mandatory=$true)][string]$Serial,
 [ValidateSet('uhid','sdk')][string]$KeyboardMode='uhid',
 [switch]$IntegrationTest
)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase,System.Windows.Forms
Import-Module (Join-Path $PSScriptRoot 'AndroidControl.psm1') -Force -DisableNameChecking
$adb=Join-Path $ScrcpyDir 'adb.exe'; $scrcpy=Join-Path $ScrcpyDir 'scrcpy.exe'
if($Transport -match '["\r\n]' -or $Serial -match '["\r\n]'){throw 'Invalid device identifier'}
$null=Get-VerifiedAndroidTransport $adb $Transport $Serial
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class SessionNative {
 [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left,Top,Right,Bottom; }
 [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X,Y; }
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
 [DllImport("user32.dll")] public static extern bool GetCursorPos(out POINT p);
 [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
 [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after,int x,int y,int w,int hgt,uint flags);
 [DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr h,int n);
 [DllImport("user32.dll")] public static extern int SetWindowLong(IntPtr h,int n,int value);
 [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h,int command);
 [DllImport("user32.dll")] public static extern uint GetDpiForWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool SetProcessDpiAwarenessContext(IntPtr value);
}
'@
try{$null=[SessionNative]::SetProcessDpiAwarenessContext([IntPtr](-4))}catch{}
[xml]$xaml=@'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" WindowStyle="None" ResizeMode="NoResize" AllowsTransparency="True" Background="Transparent" ShowInTaskbar="False" ShowActivated="False" Topmost="True" Width="44" Height="186" WindowStartupLocation="Manual">
 <Window.Resources>
  <Style TargetType="Button"><Setter Property="Width" Value="36"/><Setter Property="Height" Value="36"/><Setter Property="Margin" Value="0,1"/><Setter Property="Background" Value="Transparent"/><Setter Property="Foreground" Value="#E8EDF4"/><Setter Property="BorderThickness" Value="0"/><Setter Property="Cursor" Value="Hand"/><Setter Property="Focusable" Value="False"/><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="B" CornerRadius="8" Background="{TemplateBinding Background}"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="B" Property="Background" Value="#46566E"/></Trigger><Trigger Property="IsPressed" Value="True"><Setter TargetName="B" Property="Background" Value="#3169DD"/></Trigger><Trigger Property="IsEnabled" Value="False"><Setter TargetName="B" Property="Opacity" Value="0.4"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>
 </Window.Resources>
 <Border Background="#263346" CornerRadius="11" BorderBrush="#43526A" BorderThickness="1" Padding="3">
  <Grid>
   <Button x:Name="Tab" Width="18" Height="38" ToolTip="展开控制工具栏" AutomationProperties.Name="展开控制工具栏" Visibility="Collapsed">
    <StackPanel Orientation="Vertical"><Ellipse Width="4" Height="4" Fill="#B7C4D6" Margin="0,2"/><Ellipse Width="4" Height="4" Fill="#B7C4D6" Margin="0,2"/><Ellipse Width="4" Height="4" Fill="#B7C4D6" Margin="0,2"/></StackPanel>
   </Button>
   <StackPanel x:Name="Tools" VerticalAlignment="Center">
    <Button x:Name="Wake" Background="#3169DD" ToolTip="唤醒 / 解锁（系统密码仍需输入）" AutomationProperties.Name="唤醒或解锁">
     <Viewbox Width="19" Height="19"><Canvas Width="24" Height="24"><Path Data="M6,11 L18,11 Q20,11 20,13 L20,20 Q20,22 18,22 L6,22 Q4,22 4,20 L4,13 Q4,11 6,11 M8,11 L8,7 Q8,2 13,2 Q18,2 18,7 M12,15 L12,18" Stroke="#FFFFFF" StrokeThickness="1.8" StrokeStartLineCap="Round" StrokeEndLineCap="Round"/></Canvas></Viewbox>
    </Button>
    <Button x:Name="Keyboard" ToolTip="切换电脑键盘 / 兼容键盘（重开当前投屏）" AutomationProperties.Name="切换键盘模式">
     <Viewbox Width="20" Height="20"><Canvas Width="24" Height="24"><Path Data="M3,5 L21,5 Q22,5 22,7 L22,17 Q22,19 20,19 L4,19 Q2,19 2,17 L2,7 Q2,5 3,5 M6,9 L8,9 M11,9 L13,9 M16,9 L18,9 M6,12 L8,12 M11,12 L13,12 M16,12 L18,12 M7,15 L17,15" Stroke="#E8EDF4" StrokeThickness="1.6" StrokeStartLineCap="Round" StrokeEndLineCap="Round"/></Canvas></Viewbox>
    </Button>
    <Button x:Name="Power" ToolTip="切换亮屏 / 息屏" AutomationProperties.Name="切换屏幕电源">
     <Viewbox Width="19" Height="19"><Canvas Width="24" Height="24"><Path Data="M12,2 L12,11 M7,5 A9,9 0 1 0 17,5" Stroke="#E8EDF4" StrokeThickness="1.8" StrokeStartLineCap="Round" StrokeEndLineCap="Round"/></Canvas></Viewbox>
    </Button>
    <Button x:Name="Back" ToolTip="返回" AutomationProperties.Name="安卓返回">
     <Viewbox Width="19" Height="19"><Canvas Width="24" Height="24"><Path Data="M20,12 L4,12 M4,12 L11,5 M4,12 L11,19" Stroke="#E8EDF4" StrokeThickness="1.8" StrokeStartLineCap="Round" StrokeEndLineCap="Round"/></Canvas></Viewbox>
    </Button>
    <Button x:Name="Collapse" Height="18" ToolTip="收起工具栏" AutomationProperties.Name="收起控制工具栏"><Path Data="M0,0 L5,5 L10,0" Stroke="#A9B8CB" StrokeThickness="1.5" StrokeStartLineCap="Round" StrokeEndLineCap="Round"/></Button>
   </StackPanel>
  </Grid>
 </Border>
</Window>
'@
$win=[Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
foreach($name in @('Tab','Tools','Wake','Keyboard','Power','Back','Collapse')){Set-Variable -Name $name -Value $win.FindName($name)}
$script:mode=$KeyboardMode
$script:session=$null
$script:handle=[IntPtr]::Zero
$script:overlay=[IntPtr]::Zero
$script:expanded=$true
$script:lastHover=[DateTime]::UtcNow
$script:job=$null
$script:lastActionError=$null
$script:restart=$false
$script:startup=[DateTime]::UtcNow
$script:layoutTestStage=0
$script:layoutTestDeadline=[DateTime]::UtcNow.AddSeconds(35)
$script:layoutTestPassed=$false
function Start-Session{
 $null=Get-VerifiedAndroidTransport $adb $Transport $Serial
 $script:session=Start-Process -FilePath $scrcpy -WorkingDirectory $ScrcpyDir -ArgumentList ('-s "'+$Transport+'" --keyboard='+$script:mode) -PassThru
 $script:handle=[IntPtr]::Zero;$script:startup=[DateTime]::UtcNow
 $Keyboard.ToolTip=if($script:mode -eq 'uhid'){'当前：电脑键盘。点击切换兼容键盘（重新打开此投屏）'}else{'当前：兼容键盘。点击切换电脑键盘（重新打开此投屏）'}
}
function Set-Expanded([bool]$value){
 if($script:expanded -eq $value){return}
 $script:expanded=$value; $win.Width=if($value){44}else{26};$win.Height=if($value){184}else{44}
 $Tools.Visibility=if($value){'Visible'}else{'Collapsed'}
 $Tab.Visibility=if($value){'Collapsed'}else{'Visible'}
 $script:lastHover=[DateTime]::UtcNow
}
function Hide-Toolbar{if($win.IsVisible){$win.Hide()}}
function Update-Position{
 if($IntegrationTest -and [DateTime]::UtcNow -gt $script:layoutTestDeadline){throw 'Layout test timeout'}
  if($script:handle -eq [IntPtr]::Zero){return}
 $r=New-Object SessionNative+RECT
 if(![SessionNative]::GetWindowRect($script:handle,[ref]$r)){return}
 $dpi=96;try{$actual=[SessionNative]::GetDpiForWindow($script:handle);if($actual -gt 0){$dpi=$actual}}catch{}
 $scale=$dpi/96.0
 $w=[int][Math]::Round($(if($script:expanded){44}else{26})*$scale)
 $h=[int][Math]::Round($(if($script:expanded){184}else{44})*$scale)
 $gap=[int][Math]::Round(5*$scale)
 $screen=[Windows.Forms.Screen]::FromHandle($script:handle).WorkingArea
 $x=$r.Right+$gap
 if($x+$w -gt $screen.Right){$x=$r.Left-$gap-$w}
 if($x -lt $screen.Left){$x=[Math]::Max($screen.Left,$r.Right-$w-$gap)}
 $x=[Math]::Min([Math]::Max($screen.Left,$x),$screen.Right-$w)
 $y=[Math]::Min([Math]::Max($screen.Top,[int](($r.Top+$r.Bottom-$h)/2)),$screen.Bottom-$h)
 if(!$win.IsVisible){$win.Show()}
 $null=[SessionNative]::SetWindowPos($script:overlay,[IntPtr](-1),$x,$y,$w,$h,0x0010)
}
function Start-DeviceAction([string]$action){
 if($script:job -or $script:restart){return}
 foreach($b in @($Wake,$Power,$Back,$Keyboard)){$b.IsEnabled=$false}
 $script:lastHover=[DateTime]::UtcNow
 $script:job=Start-Job -ArgumentList (Join-Path $PSScriptRoot 'AndroidControl.psm1'),$adb,$Transport,$Serial,$action -ScriptBlock {
  param($module,$adb,$transport,$serial,$action)
  $ErrorActionPreference='Stop';Import-Module $module -Force -DisableNameChecking
  if($action -eq 'wake'){$null=Wake-AndroidDevice $adb $transport $serial}
  else{
   $null=Get-VerifiedAndroidTransport $adb $transport $serial
   $key=if($action -eq 'power'){'KEYCODE_POWER'}else{'KEYCODE_BACK'}
   $null=Invoke-Adb $adb @('-s',$transport,'shell','input','keyevent',$key)
  }
 }
}
$Wake.Add_Click({Start-DeviceAction wake})
$Power.Add_Click({Start-DeviceAction power})
$Back.Add_Click({Start-DeviceAction back})
$Keyboard.Add_Click({
 if($script:job -or $script:restart){return}
 $script:mode=if($script:mode -eq 'uhid'){'sdk'}else{'uhid'}
 $script:restart=$true;$script:startup=[DateTime]::UtcNow
 if(!$script:session.CloseMainWindow()){$script:restart=$false;$script:mode=if($script:mode -eq 'uhid'){'sdk'}else{'uhid'}}
})
$Tab.Add_Click({Set-Expanded $true;Update-Position})
$Collapse.Add_Click({Set-Expanded $false;Update-Position})
$win.Add_MouseEnter({$script:lastHover=[DateTime]::UtcNow;if(!$script:expanded){Set-Expanded $true;Update-Position}})
$win.Add_SourceInitialized({
 $script:overlay=(New-Object Windows.Interop.WindowInteropHelper $win).Handle
 $style=[SessionNative]::GetWindowLong($script:overlay,-20)
 $null=[SessionNative]::SetWindowLong($script:overlay,-20,($style -bor 0x08000000 -bor 0x80))
})
$timer=New-Object Windows.Threading.DispatcherTimer
$timer.Interval=[TimeSpan]::FromMilliseconds(100)
$timer.Add_Tick({
 try{
  if($script:job -and $script:job.State -in @('Completed','Failed','Stopped')){
   try{$null=Receive-Job $script:job -ErrorAction Stop;if($script:job.State -ne 'Completed'){throw 'Device action failed'}}
   catch{$script:lastActionError=$_.Exception.Message;$Wake.ToolTip='操作未完成，请检查设备连接；'+$_.Exception.Message}
   finally{Remove-Job $script:job -Force;$script:job=$null;foreach($b in @($Wake,$Power,$Back,$Keyboard)){$b.IsEnabled=$true}}
  }
  $script:session.Refresh()
  if($script:session.HasExited){
   if($script:restart){$script:restart=$false;Start-Session;return}
   $win.Close();return
  }
  if($script:restart){Hide-Toolbar;if([DateTime]::UtcNow -gt $script:startup.AddSeconds(5)){$script:restart=$false;$script:mode=if($script:mode -eq 'uhid'){'sdk'}else{'uhid'}};return}
  $script:handle=$script:session.MainWindowHandle
  if($IntegrationTest -and [DateTime]::UtcNow -gt $script:layoutTestDeadline){throw 'Layout test timeout'}
  if($script:handle -eq [IntPtr]::Zero){
   if([DateTime]::UtcNow -gt $script:startup.AddSeconds(30)){$win.Close()};return
  }
  if([SessionNative]::IsIconic($script:handle) -or ![SessionNative]::IsWindowVisible($script:handle)){
   Hide-Toolbar
   if($IntegrationTest -and $script:layoutTestStage -eq 4){
    if($win.IsVisible){throw 'Toolbar visible while minimized'}
    Write-Host 'Minimize hide PASS'
    $null=[SessionNative]::ShowWindow($script:handle,9)
    $script:layoutTestStage=5
   }
   return
  }
  $foreground=[SessionNative]::GetForegroundWindow()
  if(!$IntegrationTest -and $foreground -ne $script:handle -and $foreground -ne $script:overlay){Hide-Toolbar;return}
  if($win.IsMouseOver){$script:lastHover=[DateTime]::UtcNow}
  elseif($script:expanded -and !$script:job -and [DateTime]::UtcNow -gt $script:lastHover.AddSeconds(2)){Set-Expanded $false}
  Update-Position
  if($IntegrationTest){
   if([DateTime]::UtcNow -gt $script:layoutTestDeadline){throw 'Layout test timeout'}
   $r=New-Object SessionNative+RECT;$t=New-Object SessionNative+RECT
   $null=[SessionNative]::GetWindowRect($script:handle,[ref]$r);$null=[SessionNative]::GetWindowRect($script:overlay,[ref]$t)
   if($script:layoutTestStage -eq 0){
    if(!$win.IsVisible -or $t.Right -le $t.Left){throw 'Toolbar not visible'}
    $script:initialTop=$t.Top
    $null=[SessionNative]::SetWindowPos($script:handle,[IntPtr]::Zero,100,90,500,600,0x0014)
    $script:layoutTestStage=1
   }elseif($script:layoutTestStage -eq 1){
    if([Math]::Abs($r.Top-90) -gt 5){return}
    if([Math]::Abs((($t.Top+$t.Bottom)/2)-(($r.Top+$r.Bottom)/2)) -gt 3){throw 'Toolbar does not follow window center'}
    Write-Host 'Window move and resize follow PASS'
    Set-Expanded $false;Update-Position;$script:layoutTestStage=2
   }elseif($script:layoutTestStage -eq 2){
    if($script:expanded -or $Tools.Visibility -ne 'Collapsed'){throw 'Collapse failed'}
    Set-Expanded $true;Update-Position;$script:layoutTestStage=3
   }elseif($script:layoutTestStage -eq 3){
    if(!$script:expanded -or $Tools.Visibility -ne 'Visible'){throw 'Expand failed'}
    Write-Host 'Collapse and expand PASS'
    if(([SessionNative]::GetWindowLong($script:overlay,-20) -band 0x08000000) -eq 0){throw 'Toolbar steals focus'}
    Write-Host 'No-activate window style PASS'
    $null=[SessionNative]::ShowWindow($script:handle,6);$script:layoutTestStage=4
   }elseif($script:layoutTestStage -eq 5){
    if(!$win.IsVisible){throw 'Toolbar did not restore'}
    Write-Host 'Restore toolbar PASS'
    $script:oldSessionId=$script:session.Id
    $script:layoutTestStage=6
    $Keyboard.RaiseEvent((New-Object Windows.RoutedEventArgs ([Windows.Controls.Primitives.ButtonBase]::ClickEvent)))
   }elseif($script:layoutTestStage -eq 6){
    if($script:session.Id -eq $script:oldSessionId -or $script:mode -ne 'sdk'){throw 'Keyboard mode did not switch'}
    Write-Host 'Keyboard mode restart PASS'
    $script:layoutTestStage=7
    $Wake.RaiseEvent((New-Object Windows.RoutedEventArgs ([Windows.Controls.Primitives.ButtonBase]::ClickEvent)))
    if(!$script:job){throw 'Wake button did not dispatch'}
   }elseif($script:layoutTestStage -eq 7){
    if($script:job){return}
    if($script:lastActionError){throw $script:lastActionError}
    Write-Host 'Toolbar wake button dispatch PASS'
    $script:layoutTestPassed=$true;$win.Close()
   }
  }
 }catch{Write-Error $_ -ErrorAction Continue;$win.Close()}
})
$win.Add_Closed({
 $timer.Stop()
 if($script:job){Stop-Job $script:job -ErrorAction SilentlyContinue;Remove-Job $script:job -Force -ErrorAction SilentlyContinue}
 if($script:session -and !$script:session.HasExited){$null=$script:session.CloseMainWindow()}
 [Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvokeShutdown([Windows.Threading.DispatcherPriority]::Background)
})
Start-Session
$win.Left=-10000;$win.Top=-10000;$win.Show();$win.Hide()
$timer.Start()
[Windows.Threading.Dispatcher]::Run()
if($IntegrationTest -and !$script:layoutTestPassed){throw 'Toolbar integration test failed'}
if($IntegrationTest){Write-Output 'Toolbar integration PASS'}

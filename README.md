<div align="center">

# Android WiFi Control

**让 Windows 电脑轻松控制安卓手机与平板的无线控制方案**

无线配对 · 自动发现 · 多设备管理 · scrcpy 投屏与键鼠控制

[![Windows](https://img.shields.io/badge/Windows-10%20%2F%2011-blue)](#兼容性) [![Release](https://img.shields.io/github/v/release/rizetngan/android-wifi-control?label=release)](https://github.com/rizetngan/android-wifi-control/releases/latest) ![PowerShell](https://img.shields.io/badge/PowerShell-WPF-5376A5)

简体中文 · [English](README.en.md)

[功能](#功能) · [下载安装](#下载安装) · [PowerShell 安装](#powershell-安装) · [Agent 安装](#使用-agent-安装) · [使用方法](#使用方法) · [兼容性](#兼容性)

</div>

Android WiFi Control 由 [rizetngan](https://github.com/rizetngan) 维护，基于成熟的 ADB 与 [scrcpy](https://github.com/Genymobile/scrcpy) 让 Windows 电脑作为控制端，通过 Wi-Fi 或 USB 连接安卓手机和平板，在电脑上查看设备画面并使用键盘、鼠标直接操作。它不重复实现投屏引擎，而是简化设备发现、首次配对和断线重连的过程。

## 功能

- **一键打开控制**：从电脑端直接使用键盘、鼠标操作已授权的安卓手机和平板。
- **图形化无线配对**：输入设备端显示的配对地址和六位码，无需手动编写 ADB 命令。
- **设备自动发现**：通过 mDNS 读取局域网服务地址，并自动获取在线设备的厂商、型号和 Android 版本。
- **多设备管理**：保存常用设备；同一设备的 USB、TLS 或传统 TCP 连接按设备标识去重。
- **连接恢复**：窗口开启时定期检查已保存设备，尝试恢复匹配的 TLS 无线连接。
- **轻量运行**：原生 WPF 界面，复用官方 scrcpy，不需要额外投屏引擎；配置保存在本地。

## 使用场景

| 场景 | 使用方式 |
| --- | --- |
| 办公时操作平板 | 保存平板后，从设备列表打开控制窗口 |
| 同时管理手机与平板 | 选择对应设备，不必反复输入设备地址 |
| 安卓应用测试 | 使用 USB 或已授权 Wi-Fi 连接，快速切换设备 |
| 无线地址变化 | 刷新发现地址；已保存设备优先尝试 TLS 恢复 |

## 下载安装

**v2.0.0 正式发行版** · Windows · Windows PowerShell 5.1 / WPF

**[下载 Windows ZIP](https://github.com/rizetngan/android-wifi-control/releases/download/v2.0.0/Android-WiFi-Control-v2.0.0-Windows.zip)** · [发布说明](https://github.com/rizetngan/android-wifi-control/releases/tag/v2.0.0) · [SHA-256 校验](https://github.com/rizetngan/android-wifi-control/releases/download/v2.0.0/SHA256SUMS.txt) · [全部版本](https://github.com/rizetngan/android-wifi-control/releases)

发行包包含图形化启动器、ADB 连接模块及桌面快捷方式脚本，不需要编译或安装开发工具。它不是独立 EXE 安装器；需另外下载 [官方 scrcpy Windows 发行包](https://github.com/Genymobile/scrcpy/releases)，并在首次启动时选择包含 adb.exe 和 scrcpy.exe 的目录。

解压后双击 `Start-AndroidControl.bat` 即可运行。

## PowerShell 安装

在 Windows PowerShell 中复制执行：

```powershell
$ErrorActionPreference = 'Stop'
$script = Join-Path $env:TEMP 'install-android-wifi-control.ps1'
Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/rizetngan/android-wifi-control/main/scripts/install-windows.ps1' -OutFile $script
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script
```

脚本从本仓库 GitHub Releases 获取最新正式版 ZIP，核对 SHA-256，安装至 `%LOCALAPPDATA%\Programs\AndroidWiFiControl`，创建桌面快捷方式并启动。已有本地设备配置保留；若应用正在运行，先退出再安装。首次运行仍需选择官方 scrcpy 目录。

[安装脚本源码](scripts/install-windows.ps1) · 仅下载并校验：在最后一行追加 `-DownloadOnly`。

## 使用 Agent 安装

将以下指令复制给能够操作 Windows 电脑的 Agent（例如 ChatGPT Work、Codex 或 Claude Code）：

```text
请帮我在这台 Windows 电脑安装 Android WiFi Control 最新正式版：
https://github.com/rizetngan/android-wifi-control

1. 检查 Windows 版本与架构，从上述仓库 GitHub Releases 下载最新正式版 Windows ZIP 和同版本 SHA256SUMS.txt；校验 SHA-256，不一致则停止。
2. 检查是否已安装，保留 android.local.json 等已有配置；使用仓库提供的 PowerShell 安装脚本或解压至用户程序目录并创建桌面快捷方式。
3. 检查现有 scrcpy 及 adb.exe；如未安装，仅从 https://github.com/Genymobile/scrcpy/releases 下载适配 Windows 架构的官方发行包。
4. 启动 Android WiFi Control 并选择 scrcpy 目录。指导我在安卓设备上开启开发者选项，并自行确认 USB 调试或无线调试首次配对。
5. 验证设备发现、连接与 scrcpy 控制窗口启动。告诉我版本、安装路径、校验结果和需要我确认的设备操作。
6. 不上传配对码、ADB 私钥或本地配置，不启用公网 ADB，不擅自修改系统安全设置。
```

## 使用方法

### 无线连接（Android 11+）

1. 将电脑和安卓设备连接至同一可信局域网。
2. 在设备上开启开发者选项与无线调试，选择「使用配对码配对设备」。
3. 在 Android WiFi Control 填入设备显示的配对 IP:端口、六位配对码，点击「配对」。
4. 等待 ADB 自动发现，或填入无线调试主页显示的**连接地址**并点击「连接」。配对端口与连接端口不同。
5. 选择已连接设备，双击或点击「打开控制」；点击「保存设备」可开启已保存设备的恢复检查。

### USB 连接

使用数据线连接电脑与安卓设备，在设备端确认 USB 调试授权，然后刷新设备列表并打开控制。

## 兼容性

| 系统 | 连接方式 | 说明 |
| --- | --- | --- |
| Android 5–10 | USB / 已授权传统 TCP | 无线连接需按 scrcpy 上游说明通过 USB 初始化 |
| Android 11+ | USB / TLS 无线调试 | 推荐 TLS 无线连接 |
| MagicOS、MIUI、HyperOS、ColorOS、OriginOS、One UI、EMUI、Pixel | 按设备实际 ADB 能力 | 厂商权限与后台限制各有差异 |
| HarmonyOS NEXT 等非 Android 环境 | 不支持 | 不具备 Android ADB 能力 |

Android 5+ 为 scrcpy 上游支持范围；项目目前仅在荣耀 V8 Pro 上完成真机验证，并非上述所有品牌均已实测。部分系统需要单独授予输入控制权限。

## 重连与保活

默认使用已授权的 TLS 连接。应用运行时仅对已保存设备匹配的 TLS mDNS 服务尝试重新连接；关闭窗口后停止检查，不会自动重开用户关闭的投屏窗口。若无线调试被系统关闭、网络隔离或授权被撤销，需要在安卓端重新处理。

荣耀 V8 Pro 的 V1 原始方案使用 Wireless ADB Keeper、Termux、Termux:Boot 和可选 Shizuku 辅助恢复。已完成 120 秒息屏（连接保持期间）及一次重启恢复验证。其他机型的后台保活需要根据系统分别配置。

[查看 V1.0.0 荣耀配置指南](https://github.com/rizetngan/android-wifi-control/tree/v1.0.0) · [Keeper 上游项目](https://github.com/MBanucu/wireless-adb-keeper)

传统 TCP ADB 不具备 TLS 加密，只应在自己管理的可信网络使用；不要向公网转发 ADB 端口。

## 开发与验证

```powershell
git clone https://github.com/rizetngan/android-wifi-control.git
cd android-wifi-control
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-Core.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File .\Android-WiFi-Control.ps1 -SmokeTest
```

- Windows PowerShell 5.1 / WPF，复用外部 ADB 与 scrcpy。
- 真机：荣耀 V8 Pro，Android 14；设备元数据、TLS 与传统无线连接识别、界面刷新及设备去重通过。
- 待扩大验证：其他品牌、首次配对、旧版 USB、网络切换、长时间待机恢复。
- V1 启动脚本及历史 Release 保留，旧用户可继续使用原有入口。

本地配置 `android.local.json` 已排除在 Git 版本管理之外。移除设备记录不会撤销安卓端的 ADB 授权。

## 致谢

感谢 [Genymobile/scrcpy](https://github.com/Genymobile/scrcpy)、[Android ADB](https://developer.android.com/tools/adb)、[Wireless ADB Keeper](https://github.com/MBanucu/wireless-adb-keeper)、[Termux](https://github.com/termux/termux-app)、[Termux:Boot](https://github.com/termux/termux-boot) 与 [Shizuku](https://github.com/RikkaApps/Shizuku)。

本项目独立开发与维护，不是任何手机厂商或上述项目的官方产品；第三方程序由用户从其官方渠道安装，分别遵循对应许可。

[问题反馈](https://github.com/rizetngan/android-wifi-control/issues)

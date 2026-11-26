# Android WiFi Control

轻量 Windows 安卓设备管理器，基于 ADB 与 scrcpy，面向支持 Android ADB 的手机、平板及其他设备。

## 功能

- 自动读取已授权的 USB / Wi-Fi 设备、厂商、型号与 Android 版本。
- 图形化无线配对、连接、刷新，地址下拉提供 mDNS 发现结果；多个设备按设备标识去重。
- 保存设备；窗口开启时定期检查并尝试恢复匹配的 TLS 无线连接。
- 双击在线设备启动 scrcpy；本地保存配置。

## 安装

1. 下载本项目 ZIP 或克隆仓库。
2. 从 [scrcpy 官方 Releases](https://github.com/Genymobile/scrcpy/releases) 下载 Windows 版本并解压。
3. 双击 Start-AndroidControl.bat，选择包含 adb.exe 与 scrcpy.exe 的目录。
4. 安卓开启开发者选项；USB 需确认调试授权，Android 11+ 可在无线调试中使用配对码配对。
5. 填写设备显示的配对 IP:端口及六位码，点击配对。等待 ADB 发现设备，或填写无线调试主页的连接地址并点击连接。两个端口不同。
6. 选中在线设备点击打开控制；保存设备可开启已配对设备的恢复检查。

桌面快捷方式：在项目目录运行 powershell -NoProfile -ExecutionPolicy Bypass -File .\Install-AndroidShortcut.ps1。

## 兼容性

| 系统 | 连接方式 | 说明 |
| --- | --- | --- |
| Android 5–10 | USB / 已授权传统 TCP | 旧版无线须按 scrcpy 上游文档通过 USB 配置 |
| Android 11+ | USB / TLS 无线调试 | 推荐 TLS |
| MagicOS / MIUI / HyperOS / ColorOS / OriginOS / One UI / EMUI / Pixel | 按实际 ADB 能力 | 厂商后台限制、锁屏及重启恢复表现不同 |
| 非 Android 环境，如 HarmonyOS NEXT | 不支持 | 不具备 Android ADB 能力 |

Android 5+ 是 scrcpy 上游支持范围，不是本项目所有设备的实测声明。部分系统需要确认额外输入控制权限。

## 重连与保活

仅对已保存设备匹配的 TLS mDNS 服务尝试恢复连接。关闭窗口停止检查；不会自动重开用户关闭的投屏窗口。关闭无线调试、网络隔离或撤销授权时，需要设备端确认。传统 TCP ADB 没有 TLS 加密，只在自己管理的可信网络使用，不向公网转发端口。

荣耀 V8 Pro 原始部署使用 Wireless ADB Keeper、Termux、Termux:Boot 与可选 Shizuku。详见 [v1.0.0 配置指南](../../tree/v1.0.0) 及 [Keeper 上游项目](https://github.com/MBanucu/wireless-adb-keeper)。第三方组件单独安装，不随本项目分发。

保留 v1 Start-HonorPad.ps1 / Start-HonorPad.bat / Install-Shortcut.ps1，旧用户无需修改原设备配置。

## 验证

v1：荣耀 V8 Pro / Android 14，120 秒息屏、一次重启恢复。v2：设备/mDNS 解析、端口校验、WPF 加载、荣耀真机在线设备读取、实际窗口刷新及设备去重。其他品牌、首次配对、旧版 USB、长时待机和网络切换仍需实际设备验证。

## Agent 安装

克隆本仓库，下载官方 scrcpy 并解压，启动 Start-AndroidControl.bat；指导用户在设备上确认调试授权及首次配对；连接后运行 Install-AndroidShortcut.ps1。不要上传 ADB 私钥、配对码或本地配置，不启用公网 ADB。

## 上游

[Genymobile/scrcpy](https://github.com/Genymobile/scrcpy) · [Android ADB](https://developer.android.com/tools/adb) · [Wireless ADB Keeper](https://github.com/MBanucu/wireless-adb-keeper) · [Termux](https://github.com/termux/termux-app) · [Termux:Boot](https://github.com/termux/termux-boot) · [Shizuku](https://github.com/RikkaApps/Shizuku)

非任何手机厂商官方项目。

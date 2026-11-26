# Honor Pad WiFi Control

荣耀平板无线控制：基于 scrcpy 的 Windows 启动器与 MagicOS 无线调试配置指南。

适合自己的平板与 Windows 电脑在同一可信局域网内使用。无需每次重新输入地址；首次配对仍需在平板上确认。

## 功能

- mDNS 自动发现已授权设备的当前地址。
- 验证设备序列号，避免误连同网其他设备。
- 默认使用 Android TLS 无线调试；可选优先使用已配置的 Keeper 固定端口。
- 双击 BAT 或桌面快捷方式启动 scrcpy。
- 诊断模式仅检查连接，不启动投屏。

## Windows 安装

1. 从 [scrcpy 官方 Releases](https://github.com/Genymobile/scrcpy/releases) 下载 Windows 版本并解压。
2. 在平板开发者选项打开无线调试，选择使用配对码配对；用 scrcpy 自带 adb 执行 `adb pair <配对地址:端口>`，按提示输入平板显示的配对码。配对端口与连接端口不同。
3. 运行 `adb mdns services`，确认自己的平板设备编号（mDNS 服务名中 adb- 后的设备序列号）；也可以在已连接设备上用 `adb -s <连接地址> shell getprop ro.serialno` 确认。
4. 将 config.example.json 复制为 config.local.json，填入设备编号、scrcpy 目录。默认 preferFixedPort 为 false。
5. 双击 Start-HonorPad.bat。需要桌面入口时，在项目目录执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Install-Shortcut.ps1
```

诊断：`powershell -NoProfile -File .\Start-HonorPad.ps1 -DiagnoseOnly`

## 平板端：可选的自动恢复方案

在已授权的个人设备上，依照 [Wireless ADB Keeper 上游文档](https://github.com/MBanucu/wireless-adb-keeper) 的 Install、Fixed port 5555、Watchdog 章节部署 Keeper、Termux 与 Termux:Boot。第三方应用与脚本从各自官方来源安装，本仓库不分发其代码、APK 或凭据。

MagicOS 的「设置 → 应用 → 应用启动管理」中，对 Wireless ADB Keeper、Termux、Termux:Boot 分别选择手动管理，允许自启动、关联启动、后台活动。通过 Keeper 的状态页确认监控服务运行；依照上游说明完成 Termux 本地配对、开机启动与权限配置。Shizuku 是可选组件，不是 scrcpy 的依赖。

只有在自己管理的可信网络中，才可选择 Keeper 固定端口 5555，并将本地配置 preferFixedPort 改为 true。传统 ADB TCP 模式不加密，RSA 授权也不能替代 TLS；不要在公共 Wi-Fi 使用，不要向互联网转发 ADB 端口。无需固定端口时保留默认 TLS。停用时关闭 Keeper 保活并关闭无线调试，撤销不再使用的配对；必要时按上游方法恢复 USB ADB 模式。

## 已有验证

原始部署在荣耀 V8 Pro / Android 14 上完成 120 秒息屏测试、一次真实重启恢复测试，约 105 秒重新获得固定端口连接；随后重新启动 scrcpy。该结果是单设备单次重启的观测值，不代表所有 MagicOS 版本、锁屏状态及长时间待机均已验证。发布版启动器为去除设备专属配置后独立整理的版本。

## Agent 安装

将以下任务交给有本机权限的 Agent：克隆本仓库；从 scrcpy 官方 Releases 下载适配 Windows 的版本并解压；指导我在平板确认首次 ADB 配对；识别我的已授权设备序列号并生成 config.local.json；运行诊断，通过后创建桌面快捷方式。不要上传配对码、ADB 私钥、Wi-Fi 密码或本地配置，不要开启公网 ADB。

## 上游项目

- [Genymobile/scrcpy](https://github.com/Genymobile/scrcpy)
- [MBanucu/wireless-adb-keeper](https://github.com/MBanucu/wireless-adb-keeper)
- [Termux](https://github.com/termux/termux-app) / [Termux:Boot](https://github.com/termux/termux-boot)
- [Shizuku](https://github.com/RikkaApps/Shizuku)

非荣耀官方项目。

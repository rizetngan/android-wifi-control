<div align="center">

# Android WiFi Control

**A lightweight Windows device manager for Android phones and tablets**

Wireless pairing · Device discovery · Multiple devices · scrcpy control

[![Release](https://img.shields.io/github/v/release/rizetngan/android-wifi-control?label=release)](https://github.com/rizetngan/android-wifi-control/releases/latest)

[简体中文](README.md) · English

[Features](#features) · [Download](#download) · [PowerShell](#powershell-installation) · [Agent](#agent-installation) · [Usage](#usage)

</div>

Android WiFi Control is maintained by [rizetngan](https://github.com/rizetngan). It uses ADB and official scrcpy to simplify device discovery, pairing, connection and control on Windows.

## Features

- View authorized USB and Wi-Fi devices and their model and Android version.
- Pair wirelessly using the device's pairing address and six-digit code.
- Discover mDNS services and deduplicate device transports.
- Save multiple devices and attempt matching TLS reconnections while the window is open.
- Launch scrcpy by double-clicking an online device. Settings remain local.

## Download

**v2.0.0 — official Windows release**

[Windows ZIP](https://github.com/rizetngan/android-wifi-control/releases/download/v2.0.0/Android-WiFi-Control-v2.0.0-Windows.zip) · [Release notes](https://github.com/rizetngan/android-wifi-control/releases/tag/v2.0.0) · [SHA256SUMS](https://github.com/rizetngan/android-wifi-control/releases/download/v2.0.0/SHA256SUMS.txt)

This is a PowerShell/WPF launcher package, not a standalone EXE. Download [official scrcpy](https://github.com/Genymobile/scrcpy/releases) separately, extract both packages, launch `Start-AndroidControl.bat`, and select the directory containing adb.exe and scrcpy.exe.

## PowerShell installation

```powershell
$script = Join-Path $env:TEMP 'install-android-wifi-control.ps1'
Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/rizetngan/android-wifi-control/main/scripts/install-windows.ps1' -OutFile $script
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script
```

The installer fetches the latest stable release, checks SHA-256, installs to `%LOCALAPPDATA%\Programs\AndroidWiFiControl`, preserves local settings and creates a desktop shortcut. Close the app before updating. Append `-DownloadOnly` to verify the download without installing. scrcpy is required separately.

## Agent installation

```text
Install Android WiFi Control on my Windows computer:
https://github.com/rizetngan/android-wifi-control
Use only the official stable release ZIP and SHA256SUMS.txt. Verify the hash,
preserve existing local settings, create the desktop shortcut, and install
official scrcpy separately if needed. Guide me through device-side debugging
authorization and pairing. Verify discovery and launch. Do not upload pairing
codes, ADB keys or local settings, or expose ADB to the public internet.
```

## Usage

For Android 11+, enable Wireless debugging on a trusted local network. Enter the pairing endpoint and code, then pair. Wait for discovery or enter the separate connection endpoint. Select the online device and open control. For USB, connect the cable and authorize debugging on the device.

## Compatibility and verification

scrcpy supports Android 5+; Android 11+ supports native TLS wireless debugging. Older Android devices require USB or an explicitly configured legacy TCP connection. OEM-specific permissions and background behavior vary. Honor V8 Pro (Android 14) has been tested for live discovery, metadata, WPF loading, refresh and deduplication. Other brands, first-time pairing, USB on older Android and long-idle recovery require further validation.

TLS recovery runs only while the app is open and cannot replace device authorization or re-enable disabled debugging. Legacy TCP ADB is not TLS encrypted; use it only on trusted networks. The original Honor-specific setup is preserved in [v1.0.0](https://github.com/rizetngan/android-wifi-control/tree/v1.0.0).

## Development

Windows PowerShell 5.1 / WPF. Run `tests/Test-Core.ps1` for parser tests and `Android-WiFi-Control.ps1 -SmokeTest` in an STA PowerShell session.

## Credits

[Genymobile/scrcpy](https://github.com/Genymobile/scrcpy), [Android ADB](https://developer.android.com/tools/adb), [Wireless ADB Keeper](https://github.com/MBanucu/wireless-adb-keeper), Termux, Termux:Boot and Shizuku. Third-party tools are installed separately under their own terms. This is an independent project.

[Report an issue](https://github.com/rizetngan/android-wifi-control/issues)

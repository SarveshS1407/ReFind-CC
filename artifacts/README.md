# ReFind Android APK Deliverables

This directory contains the verified Android installation packages built for **ReFind** (`com.refind.vit`).

## Generated Build Packages

| File Name | Build Type | Target Architecture | Min SDK | Target SDK | Description |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `ReFind-arm64-v8a-release.apk` | Release | ARM64 (`arm64-v8a`) | Android 7.0 (API 24) | Android 16 (API 36) | **Recommended for modern Android phones** (Pixel, Galaxy, OnePlus, Xiaomi, Nothing Phone) |
| `ReFind-release.apk` | Release (Universal) | Fat APK (`arm64`, `arm`, `x86_64`) | Android 7.0 (API 24) | Android 16 (API 36) | Universal release APK for all Android CPU architectures |
| `ReFind-debug.apk` | Debug | Fat APK (`arm64`, `arm`, `x86_64`) | Android 7.0 (API 24) | Android 16 (API 36) | Development debug package with live DevTools and debugging symbols |

---

## Package Specification & Integrity

- **Application Name:** ReFind
- **Package ID / Application ID:** `com.refind.vit`
- **Version Name:** `1.0.0`
- **Version Code:** `1` (`2001` for arm64-v8a)
- **Compile SDK:** Android 36 (Android 16)
- **Target SDK:** Android 36
- **Minimum SDK:** Android 24 (Android 7.0 Nougat+)
- **Required Permissions:**
  - `android.permission.INTERNET`
  - `android.permission.ACCESS_NETWORK_STATE`
- **Signing Configuration:** Signed with Android debug certificate (`CN=Android Debug,O=Android,C=US`) for immediate one-tap sideloading without custom keystore prompts.

---

## How to Install on an Android Phone (Sideloading Guide)

### Method 1: Direct File Transfer (USB / Google Drive / WhatsApp)
1. Transfer `ReFind-arm64-v8a-release.apk` (or `ReFind-release.apk`) to your Android phone via USB cable, Google Drive, Telegram, or WhatsApp.
2. Open your phone's **Files** or **Downloads** app.
3. Tap on the `.apk` file.
4. If prompted with *"For your security, your phone is not allowed to install unknown apps from this source"*, tap **Settings** and toggle **Allow from this source**.
5. Tap **Install**.
6. Tap **Open** to launch **ReFind**.

### Method 2: Command Line via ADB (Android Debug Bridge)
If your phone is connected to your computer with USB Debugging enabled:
```bash
adb install artifacts/android/ReFind-arm64-v8a-release.apk
```
Or for universal release:
```bash
adb install artifacts/android/ReFind-release.apk
```

# Plan: Auto-Update from GitHub Releases

**Date:** 2026-02-14
**Status:** Draft

## Overview

Add in-app update checking and downloading via the GitHub Releases API. The app checks for new versions on startup (or manually), notifies the user, downloads the platform-specific zip, and applies the update.

## Versioning

- Current: `project(BlockSmith VERSION 0.1.0)` in CMakeLists.txt
- Expose `APP_VERSION` as a compile definition so C++ can read it at runtime
- GitHub Releases use tags like `v0.2.0` — the app compares its compiled version against the latest tag
- Semver comparison (major.minor.patch), ignore pre-release/dev builds

## CI Changes (build.yml)

- Add platform matrix for future OS support:
  ```yaml
  strategy:
    matrix:
      include:
        - os: windows-latest
          artifact: win64
          qt_arch: win64_msvc2022_64
        # Future:
        # - os: ubuntu-latest
        #   artifact: linux-x64
        #   qt_arch: gcc_64
        # - os: macos-latest
        #   artifact: macos-x64
        #   qt_arch: clang_64
  ```
- Asset naming convention: `BlockSmith-<version>-<platform>.zip`
  - `win64`, `linux-x64`, `macos-x64`, `macos-arm64`
- The release step already attaches zips to tagged releases — no change needed there

## New C++ Class: `UpdateChecker`

**File:** `src/updatechecker.h` / `src/updatechecker.cpp`

```
class UpdateChecker : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Use via AppController")

    Q_PROPERTY(bool checking READ checking NOTIFY checkingChanged)
    Q_PROPERTY(bool updateAvailable READ updateAvailable NOTIFY updateAvailableChanged)
    Q_PROPERTY(QString latestVersion READ latestVersion NOTIFY updateAvailableChanged)
    Q_PROPERTY(QString releaseNotes READ releaseNotes NOTIFY updateAvailableChanged)
    Q_PROPERTY(QString downloadUrl READ downloadUrl NOTIFY updateAvailableChanged)
    Q_PROPERTY(double downloadProgress READ downloadProgress NOTIFY downloadProgressChanged)

public:
    Q_INVOKABLE void checkForUpdates();
    Q_INVOKABLE void downloadUpdate();
    Q_INVOKABLE void applyUpdate();

signals:
    void checkingChanged();
    void updateAvailableChanged();
    void downloadProgressChanged();
    void updateFailed(const QString &error);
    void updateReady(const QString &filePath);
};
```

### Logic

1. **Check:** GET `https://api.github.com/repos/bcodesnow/BlockSmith/releases/latest`
   - Uses `QNetworkAccessManager` (already available via Qt::Core/Network)
   - Parse JSON: `tag_name` → version, `body` → release notes, `assets[]` → download URLs
   - Match asset by platform suffix (`win64`, `linux-x64`, etc.)
   - Compare against compiled `APP_VERSION` using semver

2. **Download:** GET the matching asset URL
   - Stream to temp file via `QNetworkReply::readyRead`
   - Report progress via `downloadProgress` property
   - Save to `QStandardPaths::TempLocation / BlockSmith-update.zip`

3. **Apply (platform-specific):**

   | Platform | Strategy |
   |----------|----------|
   | **Windows** | Extract zip to temp dir, generate a PowerShell script that waits for app exit, replaces files, relaunches app, then deletes itself. |
   | **Linux** | Extract to temp dir, replace AppImage/binary, relaunch. |
   | **macOS** | Extract .app bundle to temp, replace, relaunch. |

   **Windows apply flow (PowerShell):**
   ```
   1. App extracts zip to %TEMP%/BlockSmith-update/
   2. App writes update.ps1 to %TEMP%:
      - Wait-Process for BlockSmith.exe to exit
      - Copy-Item -Recurse -Force from update dir to install dir
      - Start-Process BlockSmith.exe
      - Remove-Item update.ps1
   3. App launches: Start-Process powershell -ArgumentList "-File update.ps1" -WindowStyle Hidden
   4. App exits (QCoreApplication::quit)
   ```

   - The apply step is the only platform-specific part — isolate behind a simple interface:
     ```cpp
     // Platform-specific, implemented per OS
     bool applyPlatformUpdate(const QString &zipPath, const QString &installDir);
     ```

## Qt Network Dependency

- Add `find_package(Qt6 ... Network)` and `target_link_libraries(... Qt6::Network)` in CMakeLists.txt

## Integration with AppController

- Add `Q_PROPERTY(UpdateChecker* updateChecker READ updateChecker CONSTANT)`
- Create `UpdateChecker` in `AppController` constructor
- Optionally auto-check on startup (respect a config toggle)

## QML UI

### Update notification (non-intrusive)
- Small banner/toast at top of window: "Update v0.2.0 available — [Download] [Dismiss]"
- Or: badge on a settings/about button

### Update dialog (on user action)
- Shows: current version, new version, release notes (markdown rendered)
- Buttons: Download, Skip This Version, Close
- Download progress bar when downloading
- "Restart to apply" button when download complete

### Settings toggle
- "Check for updates on startup" checkbox in SettingsDialog

## Config Changes

- `ConfigManager`: add `checkUpdatesOnStartup` (bool, default true)
- `ConfigManager`: add `skippedVersion` (string, to remember dismissed versions)

## Platform Detection at Runtime

```cpp
QString UpdateChecker::platformSuffix() {
#if defined(Q_OS_WIN)
    return "win64";
#elif defined(Q_OS_LINUX)
    return "linux-x64";
#elif defined(Q_OS_MACOS)
  #if defined(Q_PROCESSOR_ARM)
    return "macos-arm64";
  #else
    return "macos-x64";
  #endif
#else
    return QString();
#endif
}
```

## Code Signing

Both platforms will be signed in CI:

### Windows
- Obtain a code signing certificate (e.g. SSL.com, Certum, or Azure Trusted Signing)
- Store certificate + password as GitHub Secrets (`WIN_SIGN_CERT_BASE64`, `WIN_SIGN_CERT_PASSWORD`)
- CI step after creating the zip: decode cert, use `signtool sign` on `BlockSmith.exe` before zipping
- Eliminates SmartScreen "unknown publisher" warnings

### macOS (when builds are added)
- Apple Developer Program membership required ($99/year)
- Store signing identity and notarization credentials as GitHub Secrets
- CI steps: `codesign --deep --strict` on .app bundle, then `xcrun notarytool submit`
- Required for macOS Gatekeeper to allow the app to run

## Security Considerations

- HTTPS only (GitHub API + asset download)
- Signed binaries on both platforms (see Code Signing above)
- Optionally verify zip checksum if provided in release body or as separate asset
- No arbitrary code execution — only replace known app files

## Implementation Order

1. Add `APP_VERSION` define to CMakeLists.txt
2. Add `Qt6::Network` dependency
3. Implement `UpdateChecker` (check + download)
4. Wire into `AppController`
5. Add QML update notification UI
6. Add config toggles
7. Implement platform-specific apply/restart (Windows first)
8. Extend CI matrix for additional platforms when needed

## Decisions

- **Self-update on Windows:** PowerShell script (no separate updater.exe)
- **Download behavior:** Manual only — user clicks Download after seeing the notification
- **Code signing:** Both platforms (Windows now, macOS when builds are added)

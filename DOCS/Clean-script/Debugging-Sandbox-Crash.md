# Debugging Sandbox Crash Guide

## Important Note

**Scheme Name:** The correct scheme name is  `DownloadFullInstaller`.  
**App Name:** The built application is named **`Download Full Installer.app`**.

## Problem
The app crashes at launch with `ud2` instruction in `libsystem_secinit.dylib` during sandbox initialization.

## Diagnostic Version

This branch includes enhanced logging to help identify exactly where the crash occurs. The logs will show:

1. **FetchInstallerPkgApp init()** - App struct initialization
2. **SUCatalog init()** - Catalog object creation (should NOT perform I/O)
3. **LanguageManager init()** - Language manager creation (should NOT perform I/O)
4. **AppDelegate applicationDidFinishLaunching** - App delegate lifecycle
5. **ContentView onAppear** - When the main view appears (safe to perform I/O)

## How to Test

### Step 1: Clean Build

```bash
# In Xcode:
Product > Clean Build Folder (Shift + Cmd + K)

# Or via command line:
xcodebuild clean -project DownloadFullInstaller.xcodeproj -scheme DownloadFullInstaller
```

### Step 2: Build

```bash
# Build with debug configuration
xcodebuild -project DownloadFullInstaller.xcodeproj -scheme DownloadFullInstaller -configuration Debug build
```

### Step 3: Run and Capture Diagnostic Output

**Recommended Method 1: Run in Xcode (Easiest)**

```bash
# Simply run the app in Xcode and view Console output:
# 1. Open the project in Xcode
# 2. Select the DownloadFullInstaller scheme
# 3. Run the app (Cmd + R)
# 4. View Console (View > Debug Area > Activate Console or Cmd + Shift + Y)
```

**Recommended Method 2: Use Console.app (Most Reliable)**

```bash
# Terminal 1: Start monitoring logs
log stream --predicate 'process == "Download Full Installer"' --level debug

# Terminal 2: Launch the app
open "$(xcodebuild -project DownloadFullInstaller.xcodeproj -scheme DownloadFullInstaller -configuration Debug -showBuildSettings 2>/dev/null | grep " BUILD_DIR " | sed 's/.*= //')/Debug/Download Full Installer.app"
```

**Alternative Method 3: Direct Launch with stdout/stderr**

```bash
# Find the built app path
BUILD_DIR=$(xcodebuild -project DownloadFullInstaller.xcodeproj -scheme DownloadFullInstaller -configuration Debug -showBuildSettings 2>/dev/null | grep " BUILD_DIR " | sed 's/.*= //')
APP_PATH="$BUILD_DIR/Debug/Download Full Installer.app"

# Launch directly (prints to current terminal)
"$APP_PATH/Contents/MacOS/Download Full Installer"
```

**Note about `open -W`**: The `open -W` command can fail with error "Unable to block on application (GetProcessPID() returned ...)" on some systems. The methods above are more reliable for capturing diagnostic output.

### Step 3: Analyze the Output

The console output will show diagnostic messages like:

```
=== FetchInstallerPkgApp init() started ===
App initialization complete - no I/O operations performed
=== FetchInstallerPkgApp init() completed ===
=== SUCatalog init() started ===
SUCatalog initialized without loading data
=== SUCatalog init() completed ===
=== LanguageManager init() started ===
LanguageManager initialized without loading languages
=== LanguageManager init() completed ===
=== AppDelegate applicationDidFinishLaunching started ===
Calling disableSystemSleep()...
DownloadFullInstaller prevents sleep
Calling Prefs.registerDefaults()...
=== AppDelegate applicationDidFinishLaunching completed ===
=== ContentView onAppear started ===
Loading SUCatalog...
=== ContentView onAppear completed ===
```

**If the crash occurs:**

- The last printed message before the crash will indicate where the problem is
- If crash happens before "FetchInstallerPkgApp init() completed", there's an issue during app struct initialization
- If crash happens before "SUCatalog init() completed", there's an issue in SUCatalog initialization
- If crash happens before "LanguageManager init() completed", there's an issue in LanguageManager initialization
- If crash happens after all init messages but before "applicationDidFinishLaunching completed", there's an issue in AppDelegate

## Known Fixes Already Applied

All of the following issues have been fixed in this codebase:

✅ **SUCatalog** - No network operations in init()
✅ **LanguageManager** - No file system operations in init()
✅ **InstallerView** - File system checks deferred to `.onAppear`
✅ **SettingsView** - File system checks deferred to `.onAppear`
✅ **Prefs.registerDefaults()** - No file system access during early initialization
✅ **Build settings** - Network and file access permissions properly configured
✅ **Entitlements** - No duplicate or conflicting entitlements

## What to Check Next

If the crash still occurs with this diagnostic version:

### 1. Troubleshooting "Unable to block on application" Error

If you see an error like:

```
Unable to block on application (GetProcessPID() returned 18446744073709551016)
```

This error occurs when the `open -W` command cannot properly track the application process. This is a known issue and does NOT indicate a problem with the application itself. Instead, use one of these alternatives:

**Solution A: Run in Xcode (Easiest)**

1. Open DownloadFullInstaller.xcodeproj in Xcode
2. Select the FetchInstallerPkg scheme
3. Run with Cmd+R
4. View Console output (Cmd+Shift+Y)

**Solution B: Use Console.app (Most Reliable)**

```bash
# Terminal 1: Start monitoring
log stream --predicate 'process == "Download Full Installer"' --level debug

# Terminal 2: Launch the app
open "/path/to/Download Full Installer.app"
```

**Solution C: Direct Launch**

```bash
# Launch the app binary directly
"/path/to/Download Full Installer.app/Contents/MacOS/Download Full Installer"
```

### 2. Check Xcode Derived Data

Sometimes Xcode caches old build artifacts. Clean derived data:

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/DownloadFullInstaller-*
```

### 3. Check Code Signing

Verify the app is properly signed with the correct entitlements:

```bash
codesign -d --entitlements - "/path/to/Download Full Installer.app"
```

Expected output should include:

```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.files.downloads.read-write</key>
<true/>
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
```

### 4. Check System Logs

View detailed system logs for sandbox violations:

```bash
log stream --predicate 'process == "Download Full Installer"' --level debug
```

Or check Console.app:

1. Open Console.app
2. Filter for "Download Full Installer"
3. Look for "Sandbox: deny" or "libsystem_secinit" messages

### 5. Verify macOS Version

The app requires macOS 13+ (Ventura or later). Check your macOS version:

```bash
sw_vers
```

### 6. Check for Third-Party Security Software

Some antivirus or security software can interfere with app sandbox initialization:

- Temporarily disable antivirus software
- Check if the app runs in a clean user account
- Verify no system extensions are blocking the app

## Reporting the Issue

If the crash persists, please provide:

1. **Console output** showing the last diagnostic message before crash
2. **Crash log** from Console.app or `~/Library/Logs/DiagnosticReports/`
3. **macOS version** (`sw_vers`)
4. **Xcode version** (if building from source)
5. **Codesign output** showing the app's entitlements
6. **System log excerpt** showing any sandbox denials

## Expected Behavior

With all fixes applied, the app should:

1. Launch successfully without any sandbox crash
2. Show all initialization messages in order
3. Load the installer catalog after the main window appears
4. Support all features (downloads, settings, language selection)

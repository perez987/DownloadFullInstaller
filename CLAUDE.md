# CLAUDE.md

Instructions for coding agents working in this repository (Claude Code and GitHub Copilot both read this file).

## Project Overview

**Download Full Installer** is a macOS application written in SwiftUI that downloads:

- macOS Intel installer packages (`.pkg`) from Apple's software update catalogs.
- Firmware files (`.ipsw`) to restore Apple Silicon Macs.
- Multipart Intel installers for older macOS releases when Apple's catalog provides all six components.
- Legacy macOS disk images (Sierra and older) from Apple's direct links.

There is **one application target**: `DownloadFullInstaller` (product name `Download Full Installer.app`), which requires **macOS 13.5** or later.

## Tech Stack

- **Language**: Swift 6
- **UI framework**: SwiftUI (macOS only)
- **Deployment target**: macOS 13.5 (`MACOSX_DEPLOYMENT_TARGET`)
- **Build tool**: Xcode 26+
- **Auto-updater**: [Sparkle](https://sparkle-project.org/) via Swift Package Manager (`Updater/UpdateController.swift`); feed is `appcast.xml` on `main`
- **Dock progress**: local copy of DockProgress 5.1.0 in `DockProgress/` (not a package dependency)
- **Sandbox**: the target is NOT sandboxed (no `.entitlements` file); hardened runtime is on. Preferences live in `~/Library/Preferences/perez987.DownloadFullInstaller.plist`

## Repository Structure

```
appcast.xml                          # Sparkle update feed (updated by Scripts/publish.sh)
NOTES-<major.minor>.x.md             # User-facing release notes (e.g. NOTES-6.1.x.md)
Scripts/                             # release.sh and publish.sh (see Releasing)
DOCS/                                # User and contributor documentation
Images/                              # README screenshots and icons
Xcode-project/
    DownloadFullInstaller.xcodeproj/
    Backgrounds/                     # DMG window background (background.png, background@2x.png)
    Checks/                          # Standalone fixture checks (see Testing)
    DownloadFullInstaller/           # Main target source
        AppDelegate.swift            # Lifecycle events (quit, cleanup)
        DownloadFullInstallerApp.swift   # @main entry point
        Prefs.swift                  # UserDefaults keys & helpers
        Info.plist                   # Includes SUFeedURL and SUPublicEDKey
        Downloads/                   # DownloadManager, MultiDownloadManager (shared queue, multipart)
        Model/                       # Catalog parsing, products, legacy/multipart installer logic
        Views/                       # SwiftUI views, one per file
        Languages/                   # LanguageManager + .lproj string tables
        Sleep/                       # Sleep prevention
        Updater/                     # Sparkle updater controller
        DockProgress/                # Dock tile progress overlay
```

## Building

This project **must be built with Xcode** on macOS.

1. Open `Xcode-project/DownloadFullInstaller.xcodeproj` in Xcode 26 or later.
2. Select the `DownloadFullInstaller` scheme.
3. Build with **⌘B**, run with **⌘R**.

From the command line: `xcodebuild -project Xcode-project/DownloadFullInstaller.xcodeproj -scheme DownloadFullInstaller -configuration Debug build`.

> Agents running in Linux cannot build or run this project. Code reviews and textual analysis are still possible; functionality verification requires a macOS machine with Xcode.

## Testing

There is no XCTest target. Validation is:

- Building without errors or warnings in Xcode.
- Running the relevant user-facing flow on macOS 13.5+.
- For changes to the multipart/legacy installer logic in `Model/`, running the standalone fixture checks in `Xcode-project/Checks/`. They are compiled with `swiftc` together with the model files they test; the exact commands are in `DOCS/Legacy-macos.md`. If you add a model file those checks depend on, update the commands there.

## Localization

Supported languages live in `Languages/*.lproj/Localizable.strings` (and `.stringsdict` where needed).

**Supported locales**: `ar`, `en`, `es`, `fr`, `fr-CA`, `it`, `ko`, `pt-BR`, `ru`, `sl`, `uk`, `zh-Hans`.

Rules:

- All user-visible strings **must** use `NSLocalizedString("Key", comment: "Description")`.
- When adding a new string, add the key/value pair to **every** `.lproj/Localizable.strings` file. Use the English text as the placeholder value for languages you cannot translate.
- Do not hard-code user-visible text in Swift source files.

## Code Conventions

- **SwiftUI views** live in `Views/`. Each view is its own file.
- **ObservableObject** models (`SUCatalog`, `LanguageManager`, etc.) are injected via `.environmentObject()` at the scene level.
- **UserDefaults** access is centralized in `Prefs.swift`. Add new preference keys there.
- **AppDelegate** handles application lifecycle events (quit, cleanup).
- Use `@StateObject` for objects owned by a view, `@EnvironmentObject` for injected objects.
- Follow the existing naming style (PascalCase types, camelCase properties/methods).
- Prefer removing debug `print()` statements; keep commented-out ones only if clearly marked and non-intrusive.

## Incomplete downloads

No app-side cleanup: the non-sandboxed temp directory is shared with other apps, so deleting from it is unsafe.

## Dependencies

| Dependency | Location | Purpose |
|---|---|---|
| Sparkle | Swift Package Manager, wrapped in `Updater/UpdateController.swift` | In-app update checks |
| DockProgress 5.1.0 | `Xcode-project/DownloadFullInstaller/DockProgress/` | Progress ring on the Dock icon during downloads |

## Versioning & Changelog

- `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` are set in the target settings of `DownloadFullInstaller.xcodeproj`.
- The build number is the version without dots, zero-padded to four digits: 6.1.9 → `0619`. Sparkle compares the build number, so it must always increase.
- User-facing release notes go in `NOTES-<major.minor>.x.md`. Update the current file when adding notable features or fixes.

## Releasing

Two zsh scripts in `Scripts/` (macOS only) make a release; signing secrets stay in the keychain, never in the repository.

1. Raise `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`.
2. `./Scripts/release.sh` archives, signs with Developer ID, notarizes, and builds `Distribute/Download.Full.Installer.<version>.dmg` (signed, notarized, stapled). `Distribute/` is git-ignored.
3. `RELEASE_NOTES=$'First change\nSecond change' ./Scripts/publish.sh` creates the GitHub Release, signs the DMG for Sparkle, adds a "What's New in Download Full Installer <version>" list to `appcast.xml`, and commits and pushes it to `main`.

Conventions the scripts follow, keep them if you change the scripts:

- Tags are the plain version (`6.1.9`), without a `v` prefix.
- Every 6.x GitHub Release is titled `App for macOS 13+`, to tell it apart from older releases that support macOS 11+.
- `appcast.xml` has a single `<item>` whose description keeps the full "What's New" history, newest first. Don't edit the enclosure or version fields by hand; `publish.sh` rewrites them.

## Multipart Intel installers

High Sierra, Mojave, and Catalina installers may appear when Apple's selected software update catalog provides all six components. The app downloads them as one grouped item in the shared queue, then can assemble the Intel installer app from `BaseSystem.dmg` and the downloaded components. Availability depends on Apple's catalog; creating the app does not make these installers compatible with Apple Silicon. Details are in `DOCS/Legacy-macos.md`.

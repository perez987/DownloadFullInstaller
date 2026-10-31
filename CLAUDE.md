# CLAUDE.md — Copilot / Claude Agent Instructions

This file is automatically read by GitHub Copilot coding agents (and Claude) when they are assigned a task in this repository. No extra configuration is needed — simply having this file at the repository root is sufficient for the agent to use it.

## Project Overview

**Download Full Installer** is a macOS application written in SwiftUI that downloads:

- macOS Intel installer packages (`.pkg`) from Apple's software update catalogs
- Firmware files (`.ipsw`) to restore Apple Silicon Macs.
- Multipart Intel installers for older macOS releases when Apple's catalog provides all six components.

There is **one application target** in this repository:

- `DownloadFullInstaller` → requires macOS 14 or later.

## Tech Stack

- **Language**: Swift 6
- **UI framework**: SwiftUI (macOS only)
- **Minimum macOS**: 14 Sonoma
- **Build tool**: Xcode 26+
- **Auto-updater**: [Sparkle](https://sparkle-project.org/) via Swift Package Manager (`Updater/UpdateController.swift`)
- **Dock progress**: `DockProgress-5.1.0` (local copy, not a package dependency)
- **Sandbox**: the target is NOT sandboxed (no `.entitlements` file); preferences live in `~/Library/Preferences/perez987.DownloadFullInstaller.plist`

## Project Structure

```
Xcode-project/
│   DownloadFullInstaller.xcodeproj/
│   Checks/                         # Standalone validation checks
│   DownloadFullInstaller/          # Main target source
│   AppDelegate.swift
│   DownloadFullInstallerApp.swift   # @main entry point
│   Prefs.swift                      # UserDefaults keys & helpers
│   Downloads/
│       DownloadManager.swift
│       MultiDownloadManager.swift   # Shared queue and multipart downloads
│   Model/                           # Catalog parsing, product model (installers & firmwares)
│   Views/
│       MultipartInstallerView.swift # Multipart download and assembly card
│   Languages/                       # LanguageManager + .lproj string tables
│   Sleep/                           # Sleep prevention logic
│   Updater/                         # Sparkle updater controller
│   DockProgress/                    # Dock tile progress overlay
DOCS/                                # User and contributor documentation
Images/Multipart-macOS/              # Multipart installer screenshots
```

## Building

This project **must be built with Xcode**.

1. Open `Xcode-project/DownloadFullInstaller.xcodeproj` in Xcode 26 or later.
2. Select the scheme matching the project name.
3. Build with **⌘B** or **Product → Build**.
4. Run with **⌘R**.

> Agents running in a Linux CI environment cannot build or run this project. Code reviews and textual analysis are still possible; functionality verification requires a macOS machine with Xcode.

## Testing

There is currently no automated test target (XCTest or otherwise). Validation is done by building and running the app manually on macOS.

When making changes:

- Ensure the project **compiles without errors or warnings** in Xcode.
- Verify the relevant user-facing flow works at runtime on macOS 14+.

## Localization

The app is localized. Supported languages live in `Languages/*.lproj/Localizable.strings` (and `.stringsdict` where needed).

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
- Follow the existing file and type naming style (PascalCase types, camelCase properties/methods).
- Keep commented-out debug `print()` statements only if they are clearly marked and non-intrusive; prefer removing them entirely.

## Incomplete downloads

No app-side cleanup: the non-sandboxed temp directory is shared with other apps, so deleting from it is unsafe.

## Dependencies

| Dependency | Location | Purpose |
|---|---|---|
| Sparkle | Swift Package Manager via wrapper in `Updater/UpdateController.swift` | In-app update checks |
| DockProgress | `DockProgress-5.1.0/` | Progress ring on Dock icon during downloads |

Sparkle is resolved through Swift Package Manager. DockProgress remains bundled in the repository.

## Versioning & Changelog

- Version and build numbers are set in `Xcode-project/DownloadFullInstaller.xcodeproj` target settings.
- User-facing release notes are maintained in `NOTES-<version>.md`. Update the current version's file when adding notable features or fixes.

## Multipart Intel installers

High Sierra, Mojave, and Catalina installers may appear when Apple's selected software update catalog provides all six components. The app downloads them as one grouped item in the shared queue, then can assemble the Intel installer app from `BaseSystem.dmg` and the downloaded components. Availability depends on Apple's catalog; creating the app does not make these installers compatible with Apple Silicon.

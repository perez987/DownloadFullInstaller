# CLAUDE.md — Copilot / Claude Agent Instructions

This file is automatically read by GitHub Copilot coding agents (and Claude) when they are assigned a task in this repository. No extra configuration is needed — simply having this file at the repository root is sufficient for the agent to use it.

## Project Overview

**Download Full Installer** is a macOS application written in SwiftUI that downloads full macOS installer packages (`.pkg`) from Apple's software update catalogs.

There are **two application targets** in this repository:

| Target | Folder | Minimum macOS | Notes |
|---|---|---|---|
| `DownloadFullInstaller` | `DownloadFullInstaller/` | macOS 13 Ventura | Main target; includes language selector and legacy macOS download |
| `DownloadFullInstaller-11` | `DownloadFullInstaller-11/` | macOS 11 Big Sur | Same features except language selector and legacy macOS download |

Both targets share the same architecture and patterns. Changes that apply to one target almost always need to be mirrored in the other unless the feature is explicitly excluded (see table above).

## Tech Stack

- **Language**: Swift 5+
- **UI framework**: SwiftUI (macOS only)
- **Build tool**: Xcode 15+ (no command-line build system such as SPM, Make, or Tuist)
- **Auto-updater**: [Sparkle](https://sparkle-project.org/) — integrated as a local framework copy inside each target folder (`Updater/UpdateController.swift`)
- **Dock progress**: `DockProgress-4.3.1/` (local copy, not a package dependency)
- **Sandbox**: both targets run in the macOS App Sandbox (see `.entitlements` files)

## Project Structure

```
DownloadFullInstaller/          # Main target source
│   AppDelegate.swift
│   DownloadFullInstallerApp.swift   # @main entry point
│   Prefs.swift                      # UserDefaults keys & helpers
│   Downloads/
│       DownloadManager.swift
│       MultiDownloadManager.swift
│   Model/                           # Catalog parsing, product model
│   Views/                           # All SwiftUI views
│   Languages/                       # LanguageManager + .lproj string tables
│   Sleep/                           # Sleep prevention logic
│   Updater/                         # Sparkle wrapper
│   DockProgress-4.3.1/              # Dock tile progress overlay
│
DownloadFullInstaller-11/       # macOS 11 target — mirrors main target
│   (same structure, suffix "-11" on entry point file)
│
DownloadFullInstaller.xcodeproj/     # Xcode project for main target
DownloadFullInstaller-11.xcodeproj/  # Xcode project for macOS 11 target
```

## Building

This project **must be built with Xcode**. There is no supported command-line build path.

1. Open `DownloadFullInstaller.xcodeproj` (main) or `DownloadFullInstaller-11.xcodeproj` (macOS 11 variant) in Xcode 15 or later.
2. Select the scheme matching the project name.
3. Build with **⌘B** or **Product → Build**.
4. Run with **⌘R**.

> Agents running in a Linux CI environment cannot build or run this project. Code reviews and textual analysis are still possible; functionality verification requires a macOS machine with Xcode.

## Testing

There is currently no automated test target (XCTest or otherwise). Validation is done by building and running the app manually on macOS.

When making changes:
- Ensure the project **compiles without errors or warnings** in Xcode.
- Verify the relevant user-facing flow works at runtime on macOS 13+.
- If the change touches the `DownloadFullInstaller-11` target's scope, verify it also compiles for that target.

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

## Sandbox Considerations

Both targets run inside the macOS App Sandbox. Any file system access outside the sandbox-allowed paths requires an appropriate entitlement. Do not add entitlements without understanding the App Review implications.

The sandboxed temporary directory used for in-progress downloads is:
```
~/Library/Containers/perez987.DownloadFullInstaller/Data/tmp
```
Incomplete downloads are cleaned up on app quit (see `AppDelegate.swift`).

## Dependencies (local copies — not Swift Package Manager)

| Dependency | Location | Purpose |
|---|---|---|
| Sparkle | `Updater/` + Xcode framework reference | In-app update checks |
| DockProgress | `DockProgress-4.3.1/` | Progress ring on Dock icon during downloads |

These dependencies are bundled as source or framework copies inside the repository. Do not attempt to resolve them via SPM or CocoaPods.

## Versioning & Changelog

- Version and build numbers are set in each Xcode project's target settings.
- User-facing release notes are maintained in `CHANGELOG-releases.md`. Update this file when adding notable features or fixes.

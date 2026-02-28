# Updater System

## Overview

Download Full Installer includes a built-in, lightweight update checker that queries the GitHub Releases API to detect newer versions of the application. It has no third-party dependencies (no Sparkle or similar framework required).

## How to Check for Updates

Open the **About This Hack** menu and click **Check for Updates…** (or press `⌘ U`). The app contacts GitHub and, depending on the result, shows one of the alerts described below.

The same check is available programmatically for automatic background checks on launch.

## Alert Types

| Situation | Title | Message |
|-----------|-------|---------|
| A newer version is available | *Update Available* | "Download Full Installer X.X.X is now available. Would you like to download it?" |
| Already on the latest version (user-initiated only) | *You're up to date!* | "Download Full Installer X.X.X is currently the latest version." |
| Network error | *Update Check Failed* | "Unable to connect to the update server. Please check your internet connection." |
| API / parsing error | *Update Check Failed* | "Failed to retrieve update information." |

When an update is available, clicking **Download Update** opens the [releases page](https://github.com/perez987/DownloadFullInstaller/releases) in the default browser. Clicking **Later** dismisses the alert without any action.

## Version Routing Logic

The checker adapts its GitHub API call based on the major version number of the running app.

Running version starts with:

- **2** 
   - API endpoint used `/repos/.../releases` (all releases)
   - Finds the newest `2.x.x` release among all releases, ignoring drafts and pre-releases. 
- **3** (or later)
   - API endpoint used `/repos/.../releases/latest`
   - Uses the standard *latest release* endpoint. 

This routing ensures that users running the `2.x.x` series receive updates for that series only, while users on `3.x.x` (or later) always track the global latest release.

## Version Comparison

Versions are compared component-by-component after stripping a leading `v` from the tag name (e.g., `v3.0.2` → `3.0.2`). Missing components are treated as `0`, so `3.1` is equal to `3.1.0`.

## Technical Details

The updater is implemented as a singleton in `GitHubUpdateChecker.swift`:

```swift
GitHubUpdateChecker.shared.checkForUpdates(userInitiated: true)
```

Pass `userInitiated: true` when the user explicitly triggers the check (shows the *up-to-date* alert). Pass `userInitiated: false` for automatic background checks (the *up-to-date* alert is suppressed to avoid interrupting the user).

### HTTP Request

```
GET https://api.github.com/repos/perez987/DownloadFullInstaller/releases/latest
Accept: application/vnd.github+json
X-GitHub-Api-Version: 2022-11-28
```

For the `2.x` routing path the `/releases` endpoint (array response) is used instead.

### No Persistent State

The checker does not store any state between runs. Every check is a fresh HTTP request and version comparison. No version numbers or timestamps are written to disk.

## Localization

All user-facing strings are fully localized through `Localizable.strings`. The relevant keys are:

| Key | Default (English) |
|-----|-------------------|
| `Check for Updates…` | Check for Updates… |
| `UpdateAvailable` | Update Available |
| `UpdateAvailableInfo` | Download Full Installer %@ is now available. Would you like to download it? |
| `DownloadUpdate` | Download Update |
| `UpdateLater` | Later |
| `UpToDate` | You're up to date! |
| `UpToDateInfo` | Download Full Installer %@ is currently the latest version. |
| `UpdateCheckError` | Update Check Failed |
| `UpdateCheckFailed` | Failed to retrieve update information. |
| `UpdateCheckNetworkError` | Unable to connect to the update server. Please check your internet connection. |

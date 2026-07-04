# Updater System

## Overview

Download Full Installer uses [Sparkle](https://sparkle-project.org/) for in-app update checks and installs. Sparkle is integrated through Swift Package Manager and reads update metadata from the appcast published for this project.

## How to Check for Updates

Open the **About Download Full Installer** menu and click **Check for Updates…** (or press `⌘ U`). Sparkle handles the update flow, including checking the appcast, presenting update UI, and launching the installer when an update is accepted.

## Configuration

The updater is configured in `DownloadFullInstaller/Info.plist` with these Sparkle keys:

- `SUFeedURL`
- `SUPublicEDKey`
- `SUEnableInstallerLauncherService`
- `SUEnableSystemProfiling`
- `SUScheduledCheckInterval`

Sandbox exceptions required by Sparkle are declared in `DownloadFullInstaller/DownloadFullInstaller.entitlements`.

## Technical Details

The menu command is wired in `DownloadFullInstaller/DownloadFullInstallerApp.swift` and delegates to `DownloadFullInstaller/Updater/UpdateController.swift`, which wraps `SPUStandardUpdaterController`.

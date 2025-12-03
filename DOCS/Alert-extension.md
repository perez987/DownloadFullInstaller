# Add Alert extension for centralized alert management

Centralizes all alert definitions into a single extension with an enum-based type system, replacing scattered inline `Alert` configurations across views.

### Changes

- **New `Alert+Extensions.swift`**
  - `AppAlertType` enum with cases: `replaceFile(filename:)`, `maxDownloads`, `installerCreation(title:message:)`, `restartRequired`, `warningSettings`
  - Each case provides `title`, `message`, `primaryButtonText`, `dismissButtonText`, `isPrimaryDestructive`
  - `createAlert(primaryAction:)` factory method
  - View extension `.appAlert(item:onAction:)` modifier

- **Refactored `InstallerView.swift`**
  - Removed local `InstallerAlertType` enum and separate state variables
  - Uses `@State private var activeAlert: AppAlertType?`

- **Refactored `LanguageSelectionView.swift`**
  - Replaced two Boolean flags with single `AppAlertType?` state

### Usage

```swift
@State private var activeAlert: AppAlertType?

// Trigger
activeAlert = .replaceFile(filename: "InstallAssistant-15.0-24A335.pkg")

// Handle
.appAlert(item: $activeAlert) { alertType in
    switch alertType {
    case .replaceFile:
        try multiDownloadManager.startDownload(url: url, filename: filename, replacing: true)
    default:
        break
    }
}
```

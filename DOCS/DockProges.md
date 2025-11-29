# DockProgress Package

This document describes the integration of the [DockProgress](https://github.com/sindresorhus/DockProgress) package by Sindre Sorhus into Download Full Installer. The package adds a progress bar overlay to the application's dock tile icon during PKG downloads.

## Package Details

- **Repository**: https://github.com/sindresorhus/DockProgress
- **Version**: 5.0.2
- **License**: MIT
- **macOS Requirement**: 10.14+

The package is added through Xcode's Swift Package Manager.

### Import

```swift
import DockProgress
```

`import` is added to `FetchInstallerPkg/DownloadManager.swift`.

## Implementation

### Style Configuration

DockProgress supports multiple built-in styles. This project uses the **bar** style which displays a horizontal progress bar at the bottom of the dock icon:

```swift
DockProgress.style = .bar
```

### Progress Updates

The `DockProgress.progress` property accepts a `Double` value from 0.0 to 1.0:

```swift
DockProgress.progress = self.progress
```

### Main Actor Isolation

DockProgress properties (`style` and `progress`) are `@MainActor`-isolated static properties. All calls must be wrapped in `DispatchQueue.main.async` to avoid Swift concurrency errors:

```swift
DispatchQueue.main.async {
    DockProgress.style = .bar
    DockProgress.progress = 0.0
}
```

## DownloadManager.swift

### 1. Download Start

When a download begins, the dock progress style is set and progress is initialized (`startDownload()`):

```swift
// Set dock progress style to bar
DispatchQueue.main.async {
    DockProgress.style = .bar
}

// Initialize progress for new downloads
if resumeData == nil {
    DispatchQueue.main.async {
        DockProgress.progress = 0.0
    }
}
```

### 2. Progress Updates

Progress is updated as data is received (`didWriteData`):

```swift
DispatchQueue.main.async {
    self.progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
    DockProgress.progress = self.progress
}
```

### 3. Resume Updates

When a download is resumed, the progress is updated from the resume offset (`didResumeAtOffset`):

```swift
DispatchQueue.main.async {
    self.progress = Double(fileOffset) / Double(expectedTotalBytes)
    DockProgress.progress = self.progress
}
```

### 4. Download Completion

On successful completion, the dock progress is reset (`didFinishDownloadingTo`):

```swift
DispatchQueue.main.async {
    DockProgress.progress = 0.0
}
```

### 5. Cancellation

When the user cancels a download (`cancel()`):

```swift
DispatchQueue.main.async {
    DockProgress.progress = 0.0
}
```

### 6. Error Handling

On max retry attempts or non-recoverable errors, the dock progress is cleared:

```swift
DispatchQueue.main.async {
    DockProgress.progress = 0.0
}
```

## Available Styles

While this project uses `.bar`, DockProgress supports these built-in styles:

- `.bar` - Horizontal progress bar (used in this project)

![Dock-bar](../Images/Dock-bar.png)

- `.circle` - Circular progress indicator
-  `.squircle` - Fits around macOS app icons
- `.badge` - Badge-style progress
- `.pie` - Circular progress like a slice of pie

![Dock-pie](../Images/Dock-pie.png)

## Troubleshooting

### Swift Concurrency Errors

If you see errors like:
```
Main actor-isolated static property 'progress' can not be mutated from a nonisolated context
```

Ensure all DockProgress calls are wrapped in `DispatchQueue.main.async { }`.

### Progress Bar Not Visible

1. Verify the dock icon is visible in the Dock
2. Check that `DockProgress.style` is set before updating `progress`
3. Ensure progress values are between 0.0 and 1.0

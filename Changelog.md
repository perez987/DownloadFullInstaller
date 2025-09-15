
### 2.1.1-103

- `main` branch.
- App runs on macOS 13+.
- Xcode project requires Sequoia or Tahoe.
- Architecture x86_64.

**New Feature: Liquid Glass UI Support**

- **Enhanced Visual Experience**: Added comprehensive Liquid Glass UI support for macOS Sequoia (15.0+) and Tahoe (26.0+)
- **Translucent Effects**: Implemented translucent backgrounds, enhanced depth, and vibrancy throughout the interface
- **Dynamic Materials**: Utilized NSVisualEffectView materials that adapt to system appearance and lighting
- **Backward Compatibility**: Maintains full compatibility with macOS 13-14 with graceful fallbacks
- **Centralized Styling**: New LiquidGlassUI utility system for consistent visual effects across all components
- **Enhanced Components**: 
  - Main window with translucent background
  - Installer list items with glass effect cards
  - Download progress with enhanced materials
  - Language selection dialog with improved visuals
  - Interactive buttons with glass styling

Changelog:

- Add LiquidGlassUI.swift utility system for centralized liquid glass styling
- Enhance VisualEffectBlur.swift with comprehensive material variants
- Update ContentView.swift with translucent backgrounds and enhanced list styling
- Improve InstallerView.swift with glass effect cards and styled buttons
- Enhance DownloadView.swift with translucent progress indicators
- Update LanguageSelectionView.swift with improved dialog appearance
- Add availability checks for macOS 15+ liquid glass features
- Implement graceful fallbacks for older macOS versions
- Update README.md with liquid glass UI documentation

### 2.1.0-102

- `main` branch.
- App runs on macOS 13+.
- Xcode project requires Sequoia or Tahoe.
- Architecture x86_64.

Changelog:

- Revise language flow
- Update localization strings for all supported languages
- Clean up debug print statements
- Updated project version and bundle identifier in Xcode project settings
- Bump to 2.1.0 version.


### 2.0.7-96

- 2 branches:<br>
	- `main` for the most up-to-date project:
		-  the app runs on Ventura 13+
		-  Xcode project requites Sequoia or Tahoe
		-  complete language system
		-  updated code to set the size of the main window relative to content<br>
	- `old` to maintain compatibility with older macOS<br>
		-  app and Xcode project run on Big Sur 11+.

### 2.0.7-70

- Bump project version to 2.0.7.

### 2.0.6-66

- Add flag icons to language selection view.
- Bump project version to 2.0.6.
- Update screenshots.

### 2.0.5-36

- Bump project version to 2.0.5.

### 2.0.4-33

- Refactor language code.
- Add language selection system.
- Add restart alert to language selection view.
- Add Simplified Chinese.
- Add option to clear app's language settings.
- Update translations.
- Bump project version to 2.0.4.

### 2.0.3-20

- Update English localization string.

### 2.0.3-105

Unfork repository:

- Import project to unfork from original repo. 
- Move all localization files into a new Languages directory.
- Add new localized strings.
- Update comments.

### 2.0.3-95

- Add Ukrainian language, thanks [ClassicUA](https://github.com/ClassicUA).

### 2.0.3-93

- Add Italian language, thanks [Anto65](https://github.com/antuneddu).

### 2.0.3-87

- Add French and Canadian French languages, thanks [Chris1111](https://github.com/chris1111). 

### 2.0.3-80

- Migrate Xcode project from groups to folders (supported before Sequoia).
- Quit the application by closing the window from the red button, thanks [Chris1111](https://github.com/chris1111). 
- Minor UI and documentation updates.
- Update language function.
- Add SeedCatalogs.plist containing actual system seed URLs.

### 2.0.3-71

- Fix ContentView layout and DownloadView UI spacing.
- Rename sleep prevention functions for clarity.
- Update copyright info.
- Remove user-specific Xcode workspace files.
- Update README badge color and formatting.

### 2.0.3-57

Add sleep prevention logic:

- Installation packages are quite large (up to 17 GB on Tahoe); computer may go to sleep before completing the download.
- Add logic to disable sleep while the app window is open.
- Sleep resumes when the app window is closed.

### 2.0.3-52

- Add constants and URL catalog for Tahoe.
- Add Tahoe icons.

### 2.0.3-93 - Add it.lproj

- Add Italian language, thanks [**Anto65**](https://github.com/antuneddu).

### 2.0.3-87 — Add fr.lproj and fr-CA.lproj

- Added French and Canadian French languages, thanks [**Chris1111**](https://github.com/chris1111). 

### 2.0.3-80 — Refactor project structure

- Migrated Xcode project from groups to folders (supported before Sequoia).
- Updated language function.
- Quit the application by closing the window from the red button, thanks [**Chris1111**](https://github.com/chris1111). 
- Minor UI and documentation updates.
- Added SeedCatalogs.plist containing actual system seed URLs.

### 2.0.3-71 — Update UI layout and copyright info

- Fixed ContentView layout and DownloadView UI spacing.
- Renamed sleep prevention functions for clarity.
- Updated copyright info.
- Removed user-specific Xcode workspace files.
- Updated README badge color and formatting.

### 2.0.3-57 — Prevent sleep while running

- Installation packages are quite large (up to 17 GB on Tahoe); computer may go to sleep before completing the download.
- Code added to disable sleep while the app window is open.
- Sleep resumes when the app window is closed.

### 2.0.2-52 — Update to macOS Tahoe

- Added Tahoe constants and URL catalog.
- Added new Tahoe icons.

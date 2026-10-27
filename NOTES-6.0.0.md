# Release notes

## 6.0.0 (0600)

- Replaced the narrow tabbed window with a wide, resizable two-pane macOS library.
- Added a permanently visible release list with existing macOS icons, content and catalog pickers, and legacy releases at the end.
- Collapsed the legacy installer section by default, with a header chevron to expand it, keeping modern releases prominent while catalogs load.
- Added a release detail pane with available versions, build numbers, dates, sizes, download actions, and installer-app creation.
- Unified modern installers, firmware, and legacy disk images in one download queue with up to three simultaneous downloads, individual cancellation, and Show in Finder.
- Added soft gradients and translucent surfaces, including matching Settings and Language sheets with more room.
- Improved readability with larger release names and metadata, catalog badges, download counts, and sidebar headings.
- Updated interface translations in all 12 supported locales.
- Made catalog loading independent of the selected release, ignored stale catalog responses, and exposed loading failures with a refresh action.
- Preserved download replacement prompts, custom destination folders, URL copying, automatic network retries, Dock progress, Sparkle updates, and sleep prevention.
- Prevented cancellation of one download from cleaning up temporary files belonging to other active downloads
- Made modern installer and firmware checkmarks reflect files currently in the destination folder when switching releases or catalogs, without monitoring the folder or changing legacy download history.

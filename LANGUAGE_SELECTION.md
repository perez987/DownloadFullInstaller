# Language Selection Feature

This document describes the language selection functionality added to Download Full Installer.

## Overview

The app now supports runtime language switching through a menubar item. Users can select from 7 language options:
- System Default (follows macOS language settings)
- English
- Spanish
- French
- French (Canada)
- Italian
- Ukrainian

## Implementation Details

### Files Added/Modified

1. **LanguageManager.swift** (new)
   - Manages language switching logic
   - Stores supported languages
   - Handles UserDefaults persistence
   - Publishes language change notifications

2. **Prefs.swift** (modified)
   - Added `appLanguage` preference key
   - Added default language registration
   - Added getter for current language setting

3. **AppDelegate.swift** (modified)
   - Creates language menu in menubar
   - Handles language selection actions
   - Updates menu checkmarks
   - Shows restart alert for full effect

4. **ContentView.swift** (modified)
   - Listens for language change notifications
   - Uses localized strings for navigation title
   - Triggers UI refresh on language change

5. **Localizable.strings** (all languages, modified)
   - Added language menu item translations
   - Added language change alert translations

## Usage

1. Users can access the language menu from the menubar
2. Selecting a language immediately saves the preference
3. An alert informs users to restart for full effect
4. The selected language is persisted across app launches

## Technical Notes

- Language changes are saved to UserDefaults under the "AppLanguage" key
- The app uses standard iOS/macOS localization (NSLocalizedString)
- UI refresh is triggered via NotificationCenter
- System language can be restored by selecting "System Default"
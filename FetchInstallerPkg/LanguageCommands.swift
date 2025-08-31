//
//  LanguageCommands.swift
//  FetchInstallerPkg
//
//  Menu commands for language switching
//

import SwiftUI

struct LanguageCommands: Commands {
    private let languageManager = LanguageManager.shared
    
    var body: some Commands {
        CommandMenu(NSLocalizedString("Language", comment: "Language menu")) {
            ForEach(languageManager.availableLanguages) { language in
                Button(action: {
                    languageManager.switchToLanguage(language.code)
                }) {
                    HStack {
                        Text(language.nativeName)
                        if languageManager.currentLanguage == language.code {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .keyboardShortcut(keyboardShortcutForLanguage(language.code))
            }
        }
    }
    
    private func keyboardShortcutForLanguage(_ code: String) -> KeyboardShortcut? {
        switch code {
        case "en":
            return KeyboardShortcut("1", modifiers: [.command, .option])
        case "es":
            return KeyboardShortcut("2", modifiers: [.command, .option])
        case "fr":
            return KeyboardShortcut("3", modifiers: [.command, .option])
        case "fr-CA":
            return KeyboardShortcut("4", modifiers: [.command, .option])
        case "it":
            return KeyboardShortcut("5", modifiers: [.command, .option])
        case "uk":
            return KeyboardShortcut("6", modifiers: [.command, .option])
        default:
            return nil
        }
    }
}
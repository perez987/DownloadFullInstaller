//
//  LanguageManager.swift
//  FetchInstallerPkg
//
//  Language management for the app
//

import Foundation
import SwiftUI

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: String = Prefs.selectedLanguage
    @Published var availableLanguages: [LanguageInfo] = []
    
    struct LanguageInfo: Identifiable, Hashable {
        let id: String
        let code: String
        let displayName: String
        let nativeName: String
    }
    
    init() {
        loadAvailableLanguages()
        currentLanguage = Prefs.selectedLanguage
    }
    
    func loadAvailableLanguages() {
        // For development/testing, we can use the known languages
        // In production, this would scan the bundle's Languages directory
        let knownLanguages = [
            ("en", "English", "English"),
            ("es", "Spanish", "Español"),
            ("fr", "French", "Français"),
            ("fr-CA", "French (Canada)", "Français (Canada)"),
            ("it", "Italian", "Italiano"),
            ("uk", "Ukrainian", "Українська")
        ]
        
        var languages: [LanguageInfo] = []
        
        for (code, displayName, nativeName) in knownLanguages {
            // Check if the language file actually exists
            if let _ = Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: "Languages/\(code).lproj") {
                languages.append(LanguageInfo(
                    id: code,
                    code: code,
                    displayName: displayName,
                    nativeName: nativeName
                ))
            }
        }
        
        // Sort languages by display name
        availableLanguages = languages.sorted { $0.displayName < $1.displayName }
        
        // Fallback: if no languages found, add English as default
        if availableLanguages.isEmpty {
            availableLanguages = [LanguageInfo(id: "en", code: "en", displayName: "English", nativeName: "English")]
        }
    }
    
    func switchToLanguage(_ languageCode: String) {
        currentLanguage = languageCode
        UserDefaults.standard.set(languageCode, forKey: Prefs.key(.selectedLanguage))
        
        // Update the app's language preference
        UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // Post notification to update UI
        NotificationCenter.default.post(name: .languageChanged, object: nil)
    }
    
    private func displayNameForLanguageCode(_ code: String) -> String {
        let locale = Locale(identifier: "en")
        return locale.localizedString(forLanguageCode: code) ?? code
    }
    
    private func nativeNameForLanguageCode(_ code: String) -> String {
        let locale = Locale(identifier: code)
        return locale.localizedString(forLanguageCode: code) ?? code
    }
}

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}
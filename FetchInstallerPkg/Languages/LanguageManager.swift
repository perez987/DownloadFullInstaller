//
//  LanguageManager.swift
//  Download Full Installer
//  Created for language selection dialog implementation
//
//  Created by Emilio P Egido on 2025/07/09.
//

import Foundation
import SwiftUI

class LanguageManager: ObservableObject {
    @Published var currentLanguage: Language
    
    init() {
        // Get the current system language or default to English
        let currentLocale = Locale.current.language.languageCode?.identifier ?? "en"
        self.currentLanguage = Language.language(for: currentLocale) ?? Language.allLanguages.first!
    }
    
    func changeLanguage(to language: Language) {
        currentLanguage = language
        
        // Store the language preference
        UserDefaults.standard.set(language.code, forKey: "AppLanguage")
        UserDefaults.standard.synchronize()
        
        // Note: For full language switching, the app would need to be restarted
        print("Language changed to: \(language.name) (\(language.code))")
    }
    
    func getLocalizedString(_ key: String) -> String {
        // This would typically load from the appropriate .lproj bundle
        // For now, we'll use the standard NSLocalizedString
        return NSLocalizedString(key, comment: "")
    }
}

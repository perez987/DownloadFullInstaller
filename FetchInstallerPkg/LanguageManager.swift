//
//  LanguageManager.swift
//  FetchInstallerPkg
//
//  Created for language switching functionality
//

import Foundation
import SwiftUI

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: String = "system"
    
    struct Language {
        let code: String
        let displayName: String
        let localizedName: String
    }
    
    let supportedLanguages: [Language] = [
        Language(code: "system", displayName: "System Default", localizedName: "System Default"),
        Language(code: "en", displayName: "English", localizedName: "English"),
        Language(code: "es", displayName: "Spanish", localizedName: "Español"),
        Language(code: "fr", displayName: "French", localizedName: "Français"),
        Language(code: "fr-CA", displayName: "French (Canada)", localizedName: "Français (Canada)"),
        Language(code: "it", displayName: "Italian", localizedName: "Italiano"),
        Language(code: "uk", displayName: "Ukrainian", localizedName: "Українська")
    ]
    
    private init() {
        loadCurrentLanguage()
    }
    
    func loadCurrentLanguage() {
        currentLanguage = Prefs.appLanguage
    }
    
    func setLanguage(_ languageCode: String) {
        currentLanguage = languageCode
        UserDefaults.standard.set(languageCode, forKey: Prefs.key(.appLanguage))
        
        if languageCode == "system" {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        }
        
        UserDefaults.standard.synchronize()
        
        // Trigger UI refresh by posting notification
        NotificationCenter.default.post(name: .languageChanged, object: nil)
    }
    
    func getCurrentLanguageDisplayName() -> String {
        return supportedLanguages.first { $0.code == currentLanguage }?.displayName ?? "System Default"
    }
}

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}
//
//  LanguageManager.swift
//  Download Full Installer
//  Created for language selection dialog implementation
//
//  Created by Emilio P Egido on 2025-08-25.
//

import Foundation
import SwiftUI

struct SupportedLanguage {
    let code: String
    let localizedName: String
    let nativeName: String
}

class LanguageManager: ObservableObject {
    @Published var currentLanguage: String = "en"
    @Published var availableLanguages: [SupportedLanguage] = []
    
    private let userDefaults = UserDefaults.standard
    private let languageKey = "SelectedLanguage"
    
    init() {
        loadAvailableLanguages()
        loadCurrentLanguage()
    }
    
    private func loadAvailableLanguages() {
        // Check main bundle for .lproj directories in Languages subdirectory
        guard let languagesPath = Bundle.main.path(forResource: "Languages", ofType: nil) else {
            // Fallback: check main bundle root for .lproj directories
            let mainBundle = Bundle.main
            let languagePaths = mainBundle.paths(forResourcesOfType: "lproj", inDirectory: nil)
            
            availableLanguages = languagePaths.compactMap { path in
                let languageCode = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
                return createSupportedLanguage(from: languageCode)
            }
            return
        }
        
        // Check Languages directory for .lproj subdirectories
        let fileManager = FileManager.default
        guard let contents = try? fileManager.contentsOfDirectory(atPath: languagesPath) else {
            // Fallback to default language
            availableLanguages = [createSupportedLanguage(from: "en")]
            return
        }
        
        availableLanguages = contents.compactMap { fileName in
            if fileName.hasSuffix(".lproj") {
                let languageCode = String(fileName.dropLast(6)) // Remove ".lproj"
                return createSupportedLanguage(from: languageCode)
            }
            return nil
        }.sorted { $0.nativeName < $1.nativeName }
    }
    
    private func createSupportedLanguage(from code: String) -> SupportedLanguage {
        let locale = Locale(identifier: code)
        let nativeName = locale.localizedString(forIdentifier: code) ?? code
        let localizedName = Locale.current.localizedString(forIdentifier: code) ?? code
        
        return SupportedLanguage(
            code: code,
            localizedName: localizedName.capitalized,
            nativeName: nativeName.capitalized
        )
    }
    
    private func loadCurrentLanguage() {
        if let savedLanguage = userDefaults.string(forKey: languageKey) {
            currentLanguage = savedLanguage
        } else {
            // Use system preferred language if available, otherwise default to English
            let preferredLanguages = Locale.preferredLanguages
            for preferred in preferredLanguages {
                let code = String(preferred.prefix(2))
                if availableLanguages.contains(where: { $0.code == code }) {
                    currentLanguage = code
                    break
                }
            }
        }
    }
    
    func setLanguage(_ languageCode: String) {
        currentLanguage = languageCode
        userDefaults.set(languageCode, forKey: languageKey)
        
        // Set the app's language preference
        UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // Post notification for UI refresh
        NotificationCenter.default.post(name: .languageChanged, object: nil)
    }
    
    func getCurrentLanguageDisplayName() -> String {
        guard let language = availableLanguages.first(where: { $0.code == currentLanguage }) else {
            return "English"
        }
        return language.nativeName
    }
}

extension Notification.Name {
    static let languageChanged = Notification.Name("LanguageChanged")
}

//
//  Language.swift
//  FetchInstallerPkg
//
//  Language selection with flag icons.
//  Created by Emilio P Egido on 2025-08-25.
//

import Foundation

struct Language: Identifiable, Hashable {
    let id: String
    let code: String
    let name: String
    let flagIcon: String
    let systemIcon: String
    
    static let allLanguages: [Language] = [
        Language(id: "en", code: "en", name: "English", flagIcon: "🇺🇸", systemIcon: "flag"),
        Language(id: "es", code: "es", name: "Español", flagIcon: "🇪🇸", systemIcon: "flag.fill"),
        Language(id: "fr", code: "fr", name: "Français", flagIcon: "🇫🇷", systemIcon: "flag"),
        Language(id: "fr-CA", code: "fr-CA", name: "Français (Canada)", flagIcon: "🇨🇦", systemIcon: "flag.fill"),
        Language(id: "it", code: "it", name: "Italiano", flagIcon: "🇮🇹", systemIcon: "flag"),
        Language(id: "uk", code: "uk", name: "Українська", flagIcon: "🇺🇦", systemIcon: "flag.fill"),
        Language(id: "zh-Hans", code: "zh-Hans", name: "简体中文", flagIcon: "🇨🇳", systemIcon: "flag")
    ]
    
    static func language(for code: String) -> Language? {
        return allLanguages.first { $0.code == code }
    }
    
    static var currentLanguage: Language {
        let currentLocale = Locale.current.identifier
        return language(for: currentLocale) ?? allLanguages.first!
    }
}

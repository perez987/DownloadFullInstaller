//
//  LocalizationHelper.swift
//  Download Full Installer
//  Created for language selection dialog implementation
//
//  Created by Emilio P Egido on 2025-08-25.
//

import Foundation
import SwiftUI

extension String {
    func localized() -> String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(comment: String) -> String {
        return NSLocalizedString(self, comment: comment)
    }
}

// Helper function for localized text in SwiftUI
func LocalizedText(_ key: String, comment: String = "") -> Text {
    return Text(NSLocalizedString(key, comment: comment))
}

// Clear all of the UserDefaults data that have been set
extension UserDefaults {
    static func resetDefaults() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }
}

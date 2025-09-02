//
//  LocalizationHelper.swift
//  FetchInstallerPkg
//
//  Created for language selection dialog implementation
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
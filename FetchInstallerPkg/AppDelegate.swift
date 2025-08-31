//
//  AppDelegate.swift
//  FetchInstallerPkg
//
//  Created by Armin Briegel on 2021-06-15.
//

import AppKit
import Foundation
import SwiftUI

enum DefaultsKeys: String {
    case seedProgram = "SeedProgram"
    case osNameID = "OsNameID"
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var languageMenu: NSMenu?
    
    func applicationDidFinishLaunching(_: Notification) {
        Prefs.registerDefaults()
        
        // Initialize LanguageManager
        _ = LanguageManager.shared
        
        setupLanguageMenu()
    }
    
    func setupLanguageMenu() {
        // Get the main menu
        guard let mainMenu = NSApp.mainMenu else { return }
        
        // Create language menu
        languageMenu = NSMenu(title: NSLocalizedString("Language", comment: ""))
        let languageMenuItem = NSMenuItem(title: NSLocalizedString("Language", comment: ""), action: nil, keyEquivalent: "")
        languageMenuItem.submenu = languageMenu
        
        // Add language options
        for language in LanguageManager.shared.supportedLanguages {
            let menuItem = NSMenuItem(
                title: NSLocalizedString(language.displayName, comment: ""),
                action: #selector(languageSelected(_:)),
                keyEquivalent: ""
            )
            menuItem.target = self
            menuItem.representedObject = language.code
            
            // Check current language
            if language.code == LanguageManager.shared.currentLanguage {
                menuItem.state = .on
            }
            
            languageMenu?.addItem(menuItem)
        }
        
        // Add to main menu (insert before Window menu if it exists, otherwise add at the end)
        let insertIndex = mainMenu.indexOfItem(withTitle: "Window")
        if insertIndex != -1 {
            mainMenu.insertItem(languageMenuItem, at: insertIndex)
        } else {
            mainMenu.addItem(languageMenuItem)
        }
    }
    
    @objc func languageSelected(_ sender: NSMenuItem) {
        guard let languageCode = sender.representedObject as? String else { return }
        
        // Update language
        LanguageManager.shared.setLanguage(languageCode)
        
        // Update menu checkmarks
        updateLanguageMenuSelection()
        
        // Show alert asking user to restart the app for full effect
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Language Changed", comment: "")
            alert.informativeText = NSLocalizedString("Please restart the application for the language change to take full effect.", comment: "")
            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
            alert.runModal()
        }
    }
    
    func updateLanguageMenuSelection() {
        guard let languageMenu = languageMenu else { return }
        
        for item in languageMenu.items {
            if let languageCode = item.representedObject as? String {
                item.state = languageCode == LanguageManager.shared.currentLanguage ? .on : .off
            }
        }
    }
        
    func viewDidLoad() {
    }

    // Close app from red button (thanks Chris1111)
    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return true
    }
    
}

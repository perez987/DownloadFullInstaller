//
//  AppDelegate.swift
//  FetchInstallerPkg
//
//  Created by Armin Briegel on 2021-06-15.
//

import AppKit
import Foundation

enum DefaultsKeys: String {
    case seedProgram = "SeedProgram"
    case osNameID = "OsNameID"
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_: Notification) {
        Prefs.registerDefaults()
        
        // Set the initial language preference
        let selectedLanguage = Prefs.selectedLanguage
        UserDefaults.standard.set([selectedLanguage], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }
        
    func viewDidLoad() {
    }

    // Close app from red button (thanks Chris1111)
    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return true
    }
    
}

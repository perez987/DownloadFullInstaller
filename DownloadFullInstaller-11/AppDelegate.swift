//
//  AppDelegate.swift
//
//  Created by Armin Briegel on 2021-06-15
//  Modified by Emilio P Egido on 2025-08-23
//

import AppKit
import Foundation

enum DefaultsKeys: String {
    case seedProgram = "SeedProgram"
    case osNameID = "OsNameID"
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_: Notification) {
        // Disable sleep mode while app is running
        disableSystemSleep()
        Prefs.registerDefaults()
    }

//    func viewDidLoad() {
//    }

    // Close app from red button (thanks Chris1111)
    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return true
    }

    func applicationWillTerminate(_: Notification) {
        // Enable sleep mode when app exits
        enableSystemSleep()
        // Clean up temporary directory to remove incomplete downloads
        DownloadManager.cleanupAppTempDirectory()
    }
}

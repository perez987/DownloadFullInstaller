//
//  AppDelegate.swift
//  FetchInstallerPkg
//
//  Created by Armin Briegel on 2021-06-15.
//

import Foundation
import AppKit

enum DefaultsKeys: String {
    case seedProgram = "SeedProgram"
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        disableSystemSleep() // disable sleep
        Prefs.registerDefaults()
    }
    
    // Close app from red button (thanks Chris1111)
    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return true
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        enableSystemSleep() // enable sleep
    }
    
}

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
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return true
    }
}

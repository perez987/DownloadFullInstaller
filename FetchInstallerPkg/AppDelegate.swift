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
    
//  Code to prevent and allow sleep, better in FetchInstallerPkgApp.swift
    
//    func viewDidLoad() {
//        disableScreenSleep()
//    }
//
//    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
//        enableScreenSleep()
//        return true
//    }
    
}

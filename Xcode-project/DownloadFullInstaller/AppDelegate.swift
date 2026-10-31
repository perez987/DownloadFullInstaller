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

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_: Notification) {
        //        print("=== AppDelegate applicationDidFinishLaunching started ===")
        // Disable sleep mode while app is running
        //        print("Calling disableSystemSleep()...")
        disableSystemSleep()
        print("Calling Prefs.registerDefaults()...")
        Prefs.registerDefaults()
        //        print("=== AppDelegate applicationDidFinishLaunching completed ===")
    }

    //    func viewDidLoad() {
    //    }

    /// Close app from red button (thanks Chris1111)
    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication)
        -> Bool
    {
        true
    }

    func applicationShouldTerminate(_: NSApplication)
        -> NSApplication.TerminateReply
    {
        guard LegacyInstallerBuildManager.shared.isBuilding else {
            return .terminateNow
        }
        let alert = NSAlert()
        alert.messageText = NSLocalizedString(
            "Installer creation in progress",
            comment: "Quit prevented during installer assembly"
        )
        alert.informativeText = NSLocalizedString(
            "Wait for installer creation to finish before quitting. You can cancel in the volume selection dialog before copying begins.",
            comment: "Quit prevented during installer assembly"
        )
        alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
        alert.runModal()
        return .terminateCancel
    }

    func applicationWillTerminate(_: Notification) {
        // Enable sleep mode when app exits
        //        print("Calling enableSystemSleep()...")
        enableSystemSleep()
    }
}

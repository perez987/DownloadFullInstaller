//
//  FetchInstallerPkgApp.swift
//  Now transformed into MP3PlayerApp.swift
//
//  Created by Armin Briegel on 2021-06-09
//  Modified by Emilio P Egido on 2025-08-25
//  Transformed into MP3Player application
//

import SwiftUI

@main

struct MP3PlayerApp: App {
    @NSApplicationDelegateAdaptor(MP3PlayerAppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MP3PlayerContentView()
                .navigationTitle("MP3 Player")
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("About MP3 Player") {
                    // Show about dialog if needed
                }
                .keyboardShortcut("a", modifiers: [.command])
            }
        }
    }
}

class MP3PlayerAppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure single instance
        let runningApps = NSWorkspace.shared.runningApplications
        let currentApp = NSRunningApplication.current
        
        for app in runningApps {
            if app.bundleIdentifier == currentApp.bundleIdentifier && app != currentApp {
                // Another instance is running, bring it to front and quit this one
                app.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
                NSApp.terminate(nil)
                return
            }
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Stop audio playback when app terminates
        AudioPlayer.shared.stop()
    }
}
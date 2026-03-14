//
//  FetchInstallerPkgApp.swift
//
//  Created by Armin Briegel on 2021-06-09
//  Modified by Emilio P Egido on 2025-08-25
//

import SwiftUI
import Sparkle

@main

struct DownloadFullInstallerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var sucatalog = SUCatalog()
    @StateObject private var updaterController = UpdaterController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sucatalog)
                .navigationTitle("")
            
//                .onAppear {
//                }

//                .onDisappear {
//                }
        }

        // set width of 580 pixels to the main window
        // macOS 13 Ventura or newer
//            .defaultSize(width: 580, height: 640)

        // window resizability derived from the window’s content
        // macOS 13 Ventura or newer
//        .windowResizability(.contentSize)
        .commands {
            // Add "Check for Updates…" to the application menu
            CommandGroup(after: .appInfo) {
                Button(
                    NSLocalizedString(
                        "Check for Updates...",
                        comment: "Menu item to check for app updates"
                    ),
                    systemImage: "arrow.triangle.2.circlepath"
                ) {
                    updaterController.checkForUpdates()
                }
                        .keyboardShortcut("u", modifiers: [.command])
                        .disabled(!updaterController.canCheckForUpdates)
                }
        }
    }
}

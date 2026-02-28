//
//  DownloadFullInstallerApp.swift
//
//  Created by Armin Briegel on 2021-06-09
//

import SwiftUI

@main

struct FetchInstallerPkgApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var sucatalog = SUCatalog()
    @StateObject var languageManager = LanguageManager()
    @State private var showLanguageSelection = false
    @State private var showSettings = false

    init() {
        // Diagnostic logging for sandbox initialization
//        print("=== FetchInstallerPkgApp init() started ===")
//        print("App initialization complete - no I/O operations performed")
//        print("=== FetchInstallerPkgApp init() completed ===")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sucatalog)
                .environmentObject(languageManager)
                .navigationTitle("")
                .onAppear {
                    // Show language selection dialog if there is no saved preference
                    // Uncomment to show the dialog, comment to hide it
                    //					if !Prefs.languageSelectionShown {
                    //						showLanguageSelection = true
                    //						print("First run, language selection dialog displayed")
                    //					}
                }

//                .onDisappear {
//                }

                .sheet(isPresented: $showLanguageSelection) {
                    LanguageSelectionView(
                        languageManager: languageManager,
                        isPresented: $showLanguageSelection
                    )
                    .onDisappear {
                        Prefs.setLanguageSelectionShown()
                    }
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                }
        }

        // set width of 580 pixels to the main window in macOS 13 Ventura or newer
//            .defaultSize(width: 580, height: 640)
        // window resizability derived from the window’s content in macOS 13 Ventura or newer
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appSettings) {
                // Settings to select downloads folder
                Button(NSLocalizedString("Settings", comment: "Menu item to show settings window")) {
                    showSettings = true
                }
                .keyboardShortcut(",", modifiers: [.command])

                Divider()
                // Settings to select language selector
                Button(NSLocalizedString("Select Language", comment: "Menu item to show language selection")) {
                    showLanguageSelection = true
                }
                .keyboardShortcut("l", modifiers: [.command])
            }
            CommandGroup(after: .appInfo) {
                // Settings to check for updates
                Button(NSLocalizedString("Check for Updates…", comment: "Menu item to check for app updates"),
                       systemImage: "arrow.triangle.2.circlepath") {
                    GitHubUpdateChecker.shared.checkForUpdates(userInitiated: true)
                }
                    .keyboardShortcut("u", modifiers: [.command])
            }
        }
    }
}

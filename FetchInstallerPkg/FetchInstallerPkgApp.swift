//
//  FetchInstallerPkgApp.swift
//
//  Created by Armin Briegel on 2021-06-09
//  Modified by Emilio P Egido on 2025-08-25
//

import SwiftUI

@main

struct FetchInstallerPkgApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var sucatalog = SUCatalog()
    @StateObject var languageManager = LanguageManager()
    @State private var showLanguageSelection = false

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
        }

        // set width of 580 pixels to the main window
        // macOS 13 Ventura or newer
//            .defaultSize(width: 580, height: 640)

        // window resizability derived from the window’s content
        // macOS 13 Ventura or newer
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button(NSLocalizedString("Select Language", comment: "Menu item to show language selection")) {
                    showLanguageSelection = true
                }
                .keyboardShortcut("l", modifiers: [.command])
            }
        }

//        Settings {
//            PreferencesView().environmentObject(sucatalog).navigationTitle("Program")
//        }
    }
}

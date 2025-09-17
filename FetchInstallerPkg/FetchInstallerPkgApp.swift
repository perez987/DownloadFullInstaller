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
                    // Disable sleep mode when the window appears
//                    disableSystemSleep()
                    
                    // Show language selection dialog if not shown before
                    // Uncomment to show the dialog when there is no settings saved
                    if !Prefs.languageSelectionShown {
                        showLanguageSelection = true
                        print("First run, language selection dialog displayed")
                    }

                }
            
//                .onDisappear {
                    // Enable sleep mode when the window disappears
//                    enableSystemSleep()
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
//        .defaultSize(width: 580, height: 640)

        // window resizability derived from the window’s content
        // macOS 13 Ventura or newer
//            .windowResizability(.contentSize)
        
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

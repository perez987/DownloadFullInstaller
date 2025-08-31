//
//  FetchInstallerPkgApp.swift
//  FetchInstallerPkg
//
//  Created by Armin Briegel on 2021-06-09.
//  Modified by Emilio P Egido on 2025-08-23.
//

import SwiftUI

@main

struct FetchInstallerPkgApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var sucatalog = SUCatalog()
    @StateObject var languageManager = LanguageManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sucatalog)
                .environmentObject(languageManager)
                .navigationTitle("")
            
            // Disable sleep mode when the window appears
            // Enable sleep mode when the window disappears
            
                .onAppear {
                    disableSystemSleep()
                }
            
                .onDisappear {
                    enableSystemSleep()
                }
                        
        }
        .commands {
            LanguageCommands()
        }

//        Settings {
//            PreferencesView().environmentObject(sucatalog).navigationTitle("Program")
//        }
        
    }
    
}

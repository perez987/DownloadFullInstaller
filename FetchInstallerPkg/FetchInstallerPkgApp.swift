//
//  FetchInstallerPkgApp.swift
//  FetchInstallerPkg
//
//  Created by Armin Briegel on 2021-06-09.
//

import SwiftUI

@main
struct FetchInstallerPkgApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var sucatalog = SUCatalog()
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(sucatalog).navigationTitle("")
            
            
              // Disable sleep mode when the window appears
              // Enable sleep mode when the window disappears
            
                .onAppear {
                      disableSystemSleep()
                  }
              
                  .onDisappear {
                      enableSystemSleep()
                  }
            
        }
        Settings {
            PreferencesView().environmentObject(sucatalog).navigationTitle(NSLocalizedString("Preferences", comment: ""))
        }
    }
}

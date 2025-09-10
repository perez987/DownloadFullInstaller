//
//  FetchInstallerPkgApp.swift
//  FetchInstallerPkg
//
//  Created by Armin Briegel on 2021-06-09
//  Modified by Emilio P Egido on 2025-08-23
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

            // set width of 580 pixels to the main window
            .defaultSize(width: 580, height: 640)

            // window resizability derived from the window’s content
            .windowResizability(.contentSize)

        }

//        Settings {
//            PreferencesView().environmentObject(sucatalog).navigationTitle("Program")
//        }
        
    }

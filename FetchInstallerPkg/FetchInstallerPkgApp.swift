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
    @State private var showLanguageSelection = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sucatalog)
                .navigationTitle("")

//                .onAppear {
                    // Disable sleep mode when the window appears
//                    disableSystemSleep()
                }
            
//                .onDisappear {
                    // Enable sleep mode when the window disappears
//                    enableSystemSleep()
//                }
                        
        }

        // set width of 580 pixels to the main window
        // macOS 13 Ventura or newer
//        .defaultSize(width: 580, height: 640)

        // window resizability derived from the window’s content
        // macOS 13 Ventura or newer
//            .windowResizability(.contentSize)
        
    }

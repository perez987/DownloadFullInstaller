//
//  DownloadFullInstallerApp.swift
//
//  Created by Armin Briegel on 2021-06-09
//  Modified by Emilio P Egido on 2026-10-18
//

import AppKit
import Sparkle
import SwiftUI

@main

struct FetchInstallerPkgApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var sucatalog = SUCatalog()
    @StateObject var languageManager = LanguageManager()
    @StateObject private var updaterController = UpdaterController()
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
                .background(WindowSizeObserver())
                .environmentObject(sucatalog)
                .environmentObject(languageManager)
                .navigationTitle("")
                .onAppear {
                    // Show language selection dialog if there is no saved preference
                    // Uncomment to show the dialog, comment to hide it
                    //                    if !Prefs.languageSelectionShown {
                    //                        showLanguageSelection = true
                    //                        print("First run, language selection dialog displayed")
                    //                    }
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
        .defaultSize(
            width: Prefs.windowSize?.width ?? 950,
            height: Prefs.windowSize?.height ?? 650
        )
        //        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appSettings) {
                // Settings to select downloads folder
                Button(
                    NSLocalizedString(
                        "Settings",
                        comment: "Menu item to show settings window"
                    )
                ) {
                    showSettings = true
                }
                .keyboardShortcut(",", modifiers: [.command])

                Divider()
                // Settings to select language selector
                Button(
                    NSLocalizedString(
                        "Select Language",
                        comment: "Menu item to show language selection"
                    )
                ) {
                    showLanguageSelection = true
                }
                .keyboardShortcut("l", modifiers: [.command])
            }

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

private struct WindowSizeObserver: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowSizeObserverView {
        WindowSizeObserverView()
    }

    func updateNSView(_ nsView: WindowSizeObserverView, context: Context) {}
}

private final class WindowSizeObserverView: NSView {
    private var transitioningFullScreen = false

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        NotificationCenter.default.removeObserver(self)
        transitioningFullScreen = false
        super.viewWillMove(toWindow: newWindow)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window else { return }
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(windowDidResize(_:)),
                           name: NSWindow.didResizeNotification, object: window)
        center.addObserver(self, selector: #selector(windowDidEndLiveResize(_:)),
                           name: NSWindow.didEndLiveResizeNotification, object: window)
        center.addObserver(self, selector: #selector(windowWillChangeFullScreen(_:)),
                           name: NSWindow.willEnterFullScreenNotification, object: window)
        center.addObserver(self, selector: #selector(windowWillChangeFullScreen(_:)),
                           name: NSWindow.willExitFullScreenNotification, object: window)
        center.addObserver(self, selector: #selector(windowDidEnterFullScreen(_:)),
                           name: NSWindow.didEnterFullScreenNotification, object: window)
        center.addObserver(self, selector: #selector(windowDidExitFullScreen(_:)),
                           name: NSWindow.didExitFullScreenNotification, object: window)
    }

    @objc private func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, !window.inLiveResize else { return }
        saveSize(of: window)
    }

    @objc private func windowDidEndLiveResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        saveSize(of: window)
    }

    @objc private func windowWillChangeFullScreen(_ notification: Notification) {
        transitioningFullScreen = true
    }

    @objc private func windowDidEnterFullScreen(_ notification: Notification) {
        transitioningFullScreen = false
    }

    @objc private func windowDidExitFullScreen(_ notification: Notification) {
        transitioningFullScreen = false
        guard let window = notification.object as? NSWindow else { return }
        saveSize(of: window)
    }

    private func saveSize(of window: NSWindow) {
        guard window.isVisible, !transitioningFullScreen,
              !window.styleMask.contains(.fullScreen)
        else {
            return
        }
        Prefs.saveWindowSize(window.contentRect(forFrameRect: window.frame).size)
    }
}

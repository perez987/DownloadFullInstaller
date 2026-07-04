//
//  ContentView.swift
//
//  Created by Armin Briegel on 2021-06-09
//  Modified by Emilio P Egido on 2025-08-25
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sucatalog: SUCatalog
    @EnvironmentObject var languageManager: LanguageManager
    @AppStorage(Prefs.key(.seedProgram)) var seedProgram: String = ""
    @AppStorage(Prefs.key(.osNameID)) var osNameID: String = ""
    @StateObject private var firmwareCatalog = FirmwareCatalog()
    @State private var refreshID = UUID()
    @State private var selectedTab = 0
    var countersText: String = ""

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            PreferencesView(selectedTab: $selectedTab)
                .environmentObject(sucatalog)
                .navigationTitle(NSLocalizedString("Download Full Installer", comment: "Main window title"))

            TabView(selection: $selectedTab) {
                installersTab
                    .tag(0)
                    .tabItem {
                        Label(
                            NSLocalizedString("Installers", comment: "Installers tab title"),
                            systemImage: "cpu"
                        )
                    }

                firmwareTab
                    .tag(1)
                    .tabItem {
                        Label(
                            NSLocalizedString("Firmwares", comment: "Firmwares tab title"),
                            systemImage: "memorychip"
                        )
                    }
            }
        }
        .id(refreshID)
        .frame(
            minWidth: 490.0,
            idealWidth: 490.0,
            maxWidth: 490.0,
            minHeight: 562.0,
            alignment: .center
        )
        .padding(.bottom, 12)
        .padding(.horizontal, 28)
        .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
            refreshID = UUID()
        }
        .onReceive(NotificationCenter.default.publisher(for: .downloadPathChanged)) { _ in
            refreshID = UUID()
        }
        .onAppear {
            if !sucatalog.hasLoaded && !sucatalog.isLoading {
                sucatalog.load()
            }
            if !firmwareCatalog.hasLoaded && !firmwareCatalog.isLoading {
                firmwareCatalog.load()
            }
        }
    }

    private var installersTab: some View {
        VStack(alignment: .center, spacing: 4) {
            if #available(macOS 15.0, *) {
                List(sucatalog.installers, id: \.id) { installer in
                    InstallerView(product: installer)
                }
                .cornerRadius(8)
                .padding(4)
                .contentMargins(.leading, 1, for: .scrollContent)
            } else if #available(macOS 14.0, *) {
                List(sucatalog.installers, id: \.id) { installer in
                    InstallerView(product: installer)
                }
                .cornerRadius(8)
                .padding(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.tertiary, lineWidth: 1)
                        .padding(5)
                )
                .contentMargins(.leading, 1, for: .scrollContent)
            } else {
                List(sucatalog.installers, id: \.id) { installer in
                    InstallerView(product: installer)
                }
                .cornerRadius(8)
                .padding(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.tertiary, lineWidth: 1)
                        .padding(5)
                )
            }

            DownloadView()
        }
    }

    private var firmwareTab: some View {
        VStack(alignment: .center, spacing: 4) {
            ZStack {
                if #available(macOS 15.0, *) {
                    List(firmwareCatalog.filteredFirmwares(for: osNameID), id: \.id) { firmware in
                        FirmwareView(firmware: firmware)
                    }
                    .cornerRadius(8)
                    .padding(4)
                    .contentMargins(.leading, 1, for: .scrollContent)
                } else if #available(macOS 14.0, *) {
                    List(firmwareCatalog.filteredFirmwares(for: osNameID), id: \.id) { firmware in
                        FirmwareView(firmware: firmware)
                    }
                    .cornerRadius(8)
                    .padding(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.tertiary, lineWidth: 1)
                            .padding(5)
                    )
                    .contentMargins(.leading, 1, for: .scrollContent)
                } else {
                    List(firmwareCatalog.filteredFirmwares(for: osNameID), id: \.id) { firmware in
                        FirmwareView(firmware: firmware)
                    }
                    .cornerRadius(8)
                    .padding(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.tertiary, lineWidth: 1)
                            .padding(5)
                    )
                }

//                if firmwareCatalog.hasLoaded && firmwareCatalog.filteredFirmwares(for: osNameID).isEmpty && osNameID != "Legacy" {
                if firmwareCatalog.filteredFirmwares(for: osNameID).isEmpty && osNameID != "Legacy" {
                    Text(NSLocalizedString("The firmware list cannot be loaded or there are no firmwares available for this version of macOS.", comment: "Message shown when the firmware list is empty after loading"))
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }

            DownloadView()
        }
    }

    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }
}

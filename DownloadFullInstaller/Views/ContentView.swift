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
    @State private var canShowEmptyListMessage = false
    @State private var emptyListMessageTask: Task<Void, Never>?
    var countersText: String = ""

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            PreferencesView(selectedTab: $selectedTab)
                .environmentObject(sucatalog)
                .navigationTitle(NSLocalizedString("Download Full Installer", comment: "Main window title"))

            Spacer()
//            Divider()
//            Spacer()

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
            minHeight: 590.0,
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
            startEmptyListMessageDelay()
            if !sucatalog.hasLoaded, !sucatalog.isLoading {
                sucatalog.load()
            }
            if !firmwareCatalog.hasLoaded, !firmwareCatalog.isLoading {
                firmwareCatalog.load()
            }
        }
        .onDisappear {
            emptyListMessageTask?.cancel()
            emptyListMessageTask = nil
        }
        .onChange(of: osNameID) {
            startEmptyListMessageDelay()
        }
        .onChange(of: seedProgram) {
            startEmptyListMessageDelay()
        }
        .onChange(of: sucatalog.isLoading) {
            if sucatalog.isLoading {
                startEmptyListMessageDelay()
            }
        }
        .onChange(of: firmwareCatalog.isLoading) {
            if firmwareCatalog.isLoading {
                startEmptyListMessageDelay()
            }
        }
    }

    private var installersTab: some View {
        VStack(alignment: .center, spacing: 4) {
            ZStack {
                ScrollViewReader { proxy in
                    List(filteredInstallers, id: \.id) { installer in
                        InstallerView(product: installer)
                            .listRowSeparator(.hidden)
                    }
                    .cornerRadius(8)
                    .padding(4)
                    .overlay(
                        Group {
                            if #unavailable(macOS 15.0) {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(.tertiary, lineWidth: 1)
                                    .padding(5)
                            }
                        }
                    )
                    .onChange(of: osNameID) {
                        resetInstallersListPosition(with: proxy)
                    }
                    .onChange(of: seedProgram) {
                        resetInstallersListPosition(with: proxy)
                    }
                    .onChange(of: installerIDs) {
                        resetInstallersListPosition(with: proxy)
                    }
                    .onAppear {
                        resetInstallersListPosition(with: proxy)
                    }
                }

                if canShowEmptyListMessage && filteredInstallers.isEmpty {
                    Text(NSLocalizedString("The installers list cannot be loaded or there are no installers available for this version of macOS.", comment: "Message shown when the installers list is empty after loading"))
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                        .multilineTextAlignment(.center)
                        .padding()
                } else if !canShowEmptyListMessage && filteredInstallers.isEmpty {
                    Text(NSLocalizedString("Loading...", comment: "Temporary message shown while waiting to display the empty installers list message"))
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }

            DownloadView()
        }
    }

    private var installerIDs: [String] {
        filteredInstallers.map(\.id)
    }

    private var filteredInstallers: [Product] {
        sucatalog.installers.filter { installer in
            guard installer.hasLoaded else {
                return false
            }

            if Prefs.osNameID.rawValue == OsNameID.osAll.rawValue {
                return true
            }

            return installer.osName == Prefs.osNameID.rawValue
        }
    }

    private func resetInstallersListPosition(with proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            if let firstID = filteredInstallers.first?.id {
                proxy.scrollTo(firstID, anchor: .top)
            }
        }
    }

    private func startEmptyListMessageDelay() {
        emptyListMessageTask?.cancel()
        canShowEmptyListMessage = false
        emptyListMessageTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                canShowEmptyListMessage = true
            }
        }
    }

    private var firmwareTab: some View {
        VStack(alignment: .center, spacing: 4) {
            ZStack {
                ScrollViewReader { proxy in
                    List(firmwareCatalog.filteredFirmwares(for: osNameID), id: \.id) { firmware in
                        FirmwareView(firmware: firmware)
                            .listRowSeparator(.hidden)
                    }
                    .cornerRadius(8)
                    .padding(4)
                    .overlay(
                        Group {
                            if #unavailable(macOS 15.0) {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(.tertiary, lineWidth: 1)
                                    .padding(5)
                            }
                        }
                    )
                    .onChange(of: osNameID) {
                        if let firstFirmware = firmwareCatalog.filteredFirmwares(for: osNameID).first {
                            proxy.scrollTo(firstFirmware.id, anchor: .top)
                        }
                    }
                }

//                if firmwareCatalog.hasLoaded && firmwareCatalog.filteredFirmwares(for: osNameID).isEmpty && osNameID != "Legacy" {
                if canShowEmptyListMessage && firmwareCatalog.filteredFirmwares(for: osNameID).isEmpty && osNameID != "Legacy" {
                    Text(NSLocalizedString("The firmware list cannot be loaded or there are no firmwares available for this version of macOS.", comment: "Message shown when the firmware list is empty after loading"))
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                        .multilineTextAlignment(.center)
                        .padding()
                } else if !canShowEmptyListMessage && firmwareCatalog.filteredFirmwares(for: osNameID).isEmpty && osNameID != "Legacy" {
                    Text(NSLocalizedString("Loading...", comment: "Temporary message shown while waiting to display the empty firmware list message"))
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

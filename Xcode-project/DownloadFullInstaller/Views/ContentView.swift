//
//  ContentView.swift
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sucatalog: SUCatalog
    @AppStorage(Prefs.key(.seedProgram)) private var seedProgram = SeedProgram.noSeed.rawValue
    @StateObject private var firmwareCatalog = FirmwareCatalog()
    @State private var selectedTab = 0
    @State private var selectedRelease: String?
    @State private var isLegacyExpanded = false
    @State private var localizationID = UUID()

    private var isInstaller: Bool { selectedTab == 0 }

    private var releases: [String] {
        let names = isInstaller
            ? sucatalog.installers.filter(\.hasLoaded).compactMap(\.osName)
            : firmwareCatalog.firmwares.map(\.osName)
        return Set(names).sorted {
            (nameOS[$0] ?? $0).compare(nameOS[$1] ?? $1, options: .numeric) == .orderedDescending
        }
    }

    private var selectedLegacy: LegacyMacOSVersion? {
        guard isInstaller else { return nil }
        return LegacyMacOSVersion.allVersions.first { selectedRelease == "legacy:\($0.name)" }
    }

    private var isLoading: Bool {
        isInstaller ? sucatalog.isLoading : firmwareCatalog.isLoading
    }

    private var catalogError: String? {
        isInstaller ? sucatalog.errorMessage : firmwareCatalog.errorMessage
    }

    var body: some View {
        HStack(spacing: 0) {
            navigationPane
                .frame(width: 290)
                .background(.thinMaterial)

            Divider()

            VStack(spacing: 0) {
                detailPane
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Divider()
                DownloadView()
                    .padding(16)
                    .background(.thinMaterial)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .id(localizationID)
        .background { GlassBackground() }
        .frame(minWidth: 990, idealWidth: 990, maxWidth: 990, minHeight: 724, idealHeight: 724, maxHeight: 724)
        .navigationTitle(NSLocalizedString("Download Full Installer", comment: "Main window title"))
        .onAppear {
            if !sucatalog.hasLoaded, !sucatalog.isLoading { sucatalog.load() }
            if !firmwareCatalog.hasLoaded, !firmwareCatalog.isLoading { firmwareCatalog.load() }
        }
        .onChange(of: selectedTab) { selectedRelease = nil }
        .onChange(of: seedProgram) { selectedRelease = nil }
        .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
            localizationID = UUID()
        }
    }

    private var navigationPane: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(NSLocalizedString("macOS Library", comment: "Release browser heading"))
                    .font(.title2.bold())
                Text(NSLocalizedString("Choose a release to explore.", comment: "Release browser subtitle"))
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)

            PreferencesView(selectedTab: $selectedTab)
                .padding(.horizontal, 20)

            List(selection: $selectedRelease) {
                Section {
                    ForEach(releases, id: \.self) { name in
                        releaseLabel(name: name, version: nameOS[name] ?? "", legacy: false)
                            .tag(name)
                    }
                } header: {
                    Text(NSLocalizedString("Available Releases", comment: "Catalog releases section"))
                        .font(.body.weight(.semibold))
                }

                if isInstaller {
                    Section(isExpanded: $isLegacyExpanded) {
                        ForEach(LegacyMacOSVersion.allVersions) { version in
                            releaseLabel(name: version.name, version: version.version, legacy: true)
                                .tag("legacy:\(version.name)")
                        }
                    } header: {
                        Text(NSLocalizedString("Legacy macOS Installers", comment: "Legacy releases section"))
                            .font(.body.weight(.semibold))
                    }
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)

            VStack(alignment: .leading, spacing: 10) {
                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView().controlSize(.small)
                        Text(NSLocalizedString("Loading...", comment: "Catalog loading"))
                    }
                } else if let catalogError {
                    Text(catalogError)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if releases.isEmpty {
                    Text(emptyCatalogMessage)
                        .font(.caption)
                }
                HStack {
                    Button(action: reloadCatalog) {
                        Label(NSLocalizedString("Refresh", comment: "Reload catalog"), systemImage: "arrow.clockwise")
                    }
                    .foregroundStyle(.primary)
                    .disabled(isLoading)
                    Spacer()
                    if !isInstaller {
                        Link(destination: URL(string: "https://support.apple.com/en-us/108900")!) {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 24))
                        }
                        .foregroundStyle(.primary)
                        .help(NSLocalizedString("Restore with Apple Configurator: How to", comment: ""))
                        .accessibilityLabel(NSLocalizedString("Restore with Apple Configurator: How to", comment: ""))
                    }
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
    }

    private func releaseLabel(name: String, version: String, legacy: Bool) -> some View {
        HStack(spacing: 12) {
            Image(nameOS[name] == nil && !legacy ? "macOS" : name)
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)
            Text("macOS \(version) \(name)")
                .font(.system(.body, design: .rounded, weight: .medium))
                .lineLimit(2)
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var detailPane: some View {
        if let selectedRelease {
            VStack(alignment: .leading, spacing: 0) {
                detailHeader
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if let legacy = selectedLegacy {
                            LegacyVersionRow(version: legacy)
                            Text(NSLocalizedString("Legacy installers are disk images. Open the downloaded image in Finder, then run the package inside to create the installer app.", comment: "Legacy installer instructions"))
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                        } else if isInstaller {
                            ForEach(sucatalog.installers.filter { $0.hasLoaded && $0.osName == selectedRelease }) { product in
                                InstallerView(product: product)
                            }
                        } else {
                            ForEach(firmwareCatalog.firmwares.filter { $0.osName == selectedRelease }) { firmware in
                                FirmwareView(firmware: firmware)
                            }
                        }
                    }
                    .padding(24)
                }
                .id(selectedRelease)
            }
        } else {
            VStack(spacing: 16) {
                Image(systemName: isInstaller ? "square.stack.3d.up" : "memorychip")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(.blue.gradient)
                    .padding(24)
                    .glassCard(cornerRadius: 24)
                Text(NSLocalizedString("Select a macOS release", comment: "Empty detail heading"))
                    .font(.title2.bold())
                Text(NSLocalizedString("Available versions and download options will appear here.", comment: "Empty detail explanation"))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(40)
        }
    }

    private var detailHeader: some View {
        let name = selectedLegacy?.name ?? selectedRelease ?? ""
        let version = selectedLegacy?.version ?? nameOS[name] ?? ""
        return HStack(spacing: 16) {
            Image(nameOS[name] == nil ? "macOS" : name)
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text("macOS \(version) \(name)")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text(selectedLegacy != nil
                     ? NSLocalizedString("Legacy macOS Installers", comment: "")
                     : isInstaller
                     ? NSLocalizedString("Installers", comment: "")
                     : NSLocalizedString("Firmwares", comment: ""))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isInstaller, selectedLegacy == nil {
                Text(seedProgram)
                    .font(.body.weight(.medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .glassSubtle()
            }
        }
        .padding(24)
        .background(.ultraThinMaterial)
    }

    private var emptyCatalogMessage: String {
        isInstaller
            ? NSLocalizedString("The installers list cannot be loaded or there are no installers available for this version of macOS.", comment: "")
            : NSLocalizedString("The firmware list cannot be loaded or there are no firmwares available for this version of macOS.", comment: "")
    }

    private func reloadCatalog() {
        selectedRelease = nil
        if isInstaller { sucatalog.load() } else { firmwareCatalog.load() }
    }
}

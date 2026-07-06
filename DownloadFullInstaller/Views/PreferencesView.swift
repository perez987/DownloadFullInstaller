//
//  PreferencesView.swift
//
//  Created by Armin Briegel on 2021-06-15
//  Modified by Emilio P Egido on 2025-08-25

import SwiftUI

struct PreferencesView: View {
    @AppStorage(Prefs.key(.seedProgram)) var seedProgram: String = SeedProgram.noSeed.rawValue
    @AppStorage(Prefs.key(.osNameID)) var osNameID: String = OsNameID.osAll.rawValue
    @EnvironmentObject var sucatalog: SUCatalog
    @Binding var selectedTab: Int
    @State private var showLegacyWindow = false
    @State private var previousOsNameID: String = OsNameID.osAll.rawValue

    let labelWidth = 100.0
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                if selectedTab != 0 { Spacer() }

                // onChange is attached here (outside any tab conditional) so that
                // osNameID changes on the Firmwares tab also reload the installer catalog.
                if #available(macOS 14.0, *) {
                    Picker("osNameID", selection: $osNameID) {
                        ForEach(OsNameID.allCases.filter { $0 != .osLegacy || selectedTab != 1 }) { osName in
                            Text(osName.rawValue).font(.body)
                        }
                    }
                    .fixedSize(horizontal: selectedTab != 0, vertical: false)
                    .onChange(of: osNameID) {
                        handleOsNameIDChange()
                    }
                } else {
                    Picker("osNameID", selection: $osNameID) {
                        ForEach(OsNameID.allCases.filter { $0 != .osLegacy || selectedTab != 1 }) { osName in
                            Text(osName.rawValue).font(.body)
                        }
                    }
                    .fixedSize(horizontal: selectedTab != 0, vertical: false)
                    .onChange(of: osNameID) { _ in
                        handleOsNameIDChange()
                    }
                }

                if selectedTab == 0 {
                    HStack(alignment: .center) {
                        Text(NSLocalizedString(" in catalog", comment: "")).font(.body)
                    }

                    if #available(macOS 14.0, *) {
                        Picker(selection: $seedProgram, label: EmptyView()) {
                            ForEach(SeedProgram.allCases) { program in
                                HStack {
                                    Spacer()
                                    Text(program.rawValue).font(.body)
                                }
                            }
                        }
                        .onChange(of: seedProgram) { sucatalog.load()
                        }
                    } else {
                        Picker(selection: $seedProgram, label: EmptyView()) {
                            ForEach(SeedProgram.allCases) { program in
                                HStack {
                                    Spacer()
                                    Text(program.rawValue).font(.body)
                                }
                            }
                        }
                        .onChange(of: seedProgram) { _ in
                            sucatalog.load()
                        }
                    }
                } else {
                    Spacer()
                }
            }
            .labelsHidden()
            .frame(
                width: 400.0,
                height: 42.0,
                alignment: .center
            )
        }
        .sheet(isPresented: $showLegacyWindow) {
            LegacyDownloadView()
        }
    }

    private func handleOsNameIDChange() {
        if osNameID == OsNameID.osLegacy.rawValue {
            // Open the legacy window
            showLegacyWindow = true
            // Revert the picker to the previous selection
            osNameID = previousOsNameID
        } else {
            // Save the current selection for future reference
            previousOsNameID = osNameID
            // Load the catalog for non-legacy selections
            sucatalog.load()
        }
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView(selectedTab: .constant(0))
    }
}

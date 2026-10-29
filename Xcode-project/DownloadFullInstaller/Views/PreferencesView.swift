//
//  PreferencesView.swift
//

import SwiftUI

struct PreferencesView: View {
    @AppStorage(Prefs.key(.seedProgram)) private var seedProgram = SeedProgram
        .noSeed.rawValue
    @EnvironmentObject var sucatalog: SUCatalog
    @Binding var selectedTab: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker(
                NSLocalizedString("Content", comment: "Download type picker"),
                selection: $selectedTab
            ) {
                Text(NSLocalizedString("Installers", comment: "")).tag(0)
                Text(NSLocalizedString("Firmwares", comment: "")).tag(1)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Picker(
                NSLocalizedString(
                    "Catalog",
                    comment: "Software update catalog picker"
                ),
                selection: $seedProgram
            ) {
                ForEach(SeedProgram.allCases) { program in
                    Text(program.rawValue).tag(program.rawValue)
                }
            }
            .disabled(selectedTab != 0)
            .help(
                selectedTab == 0
                    ? NSLocalizedString("Catalog", comment: "")
                    : NSLocalizedString(
                        "Firmware downloads do not use software update catalogs.",
                        comment: "Firmware catalog explanation"
                    )
            )
        }
        .onChange(of: seedProgram) { sucatalog.load() }
    }
}

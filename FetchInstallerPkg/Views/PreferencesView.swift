//
//  PreferencesView.swift
//
//  Created by Armin Briegel on 2021-06-15
//  Modified by Emilio P Egido on 2025-08-25

import SwiftUI

struct PreferencesView: View {
	@AppStorage(Prefs.key(.seedProgram)) var seedProgram: String = SeedProgram.noSeed.rawValue
	@AppStorage(Prefs.key(.osNameID)) var osNameID: String = OsNameID.osAll.rawValue
	@AppStorage(Prefs.key(.downloadPath)) var downloadPath: String = ""
	@EnvironmentObject var sucatalog: SUCatalog

	let labelWidth = 100.0
	var body: some View {
		Form {
			VStack(alignment: .trailing) {
//				HStack(alignment: .center) { Text("\n\n") }

				HStack(alignment: .center) {

                        // Three ways to hide label text in a Picker:
                        // - empty string as first parameter: Picker("", selection: $osNameID) {
                        // - label: EmptyView() as second parametePicker(selection: $osNameID, label: EmptyView()) {
                        // - .labelsHidden() as View property: Picker("osNameID", selection: $osNameID) {

					Picker("osNameID", selection: $osNameID) {
						ForEach(OsNameID.allCases) { osName in
							Text(osName.rawValue).font(.body)
						}
					}

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
						.onChange(of: osNameID) { sucatalog.load()
						}
					} else {
						Picker(selection: $seedProgram, label: EmptyView()) {
							ForEach(SeedProgram.allCases) { program in
                                HStack {
                                    Spacer()
                                    Text(program.rawValue).font(.body)
                                }							}
						}
						.onChange(of: seedProgram) { _ in
							sucatalog.load()
						}
						.onChange(of: osNameID) { _ in
							sucatalog.load()
						}
					}
				}
			}
		}
        .liquidGlass(intensity: .subtle)
		.frame(
			width: 400.0,
			height: 38.0,
            alignment: .centerFirstTextBaseline
		)

            // Hide label texts in the Pickers
        .labelsHidden()

	}
}

struct PreferencesView_Previews: PreviewProvider {
	static var previews: some View {
		PreferencesView()
	}
}


//
//  PreferencesView.swift
//
//  Created by Armin Briegel on 2021-06-15
//  Modified by Emilio P Egido on 2025-08-25

import SwiftUI

struct PreferencesView: View {
	@AppStorage(Prefs.key(.seedProgram)) var seedProgram: String = ""
	@AppStorage(Prefs.key(.osNameID)) var osNameID: String = ""
	@AppStorage(Prefs.key(.downloadPath)) var downloadPath: String = ""
	@EnvironmentObject var sucatalog: SUCatalog

	let labelWidth = 100.0
	var body: some View {
		Form {
			VStack(alignment: .trailing) {
				HStack(alignment: .center) { Text("\n\n") }

				HStack(alignment: .center) {
					Picker("", selection: $osNameID) {
						ForEach(OsNameID.allCases) { osName in
							Text(osName.rawValue).font(.body)
						}
					}

					HStack(alignment: .center) {
						Text(NSLocalizedString("  in", comment: "OS selection separator")).font(.body)
					}

					if #available(macOS 14.0, *) {
						Picker("", selection: $seedProgram) {
							ForEach(SeedProgram.allCases) { program in
								Text(program.rawValue).font(.body)
							}
						}
						.onChange(of: seedProgram) { sucatalog.load()
						}
						.onChange(of: osNameID) { sucatalog.load()
						}
					} else {
						Picker("", selection: $seedProgram) {
							ForEach(SeedProgram.allCases) { program in
								Text(program.rawValue).font(.body)
							}
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
			width: 370.0,
			height: 30.0,
			alignment: .center
		)
	}
}

struct PreferencesView_Previews: PreviewProvider {
	static var previews: some View {
		PreferencesView()
	}
}


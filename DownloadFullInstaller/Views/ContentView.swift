//
//  ContentView.swift
//
//  Created by Armin Briegel on 2021-06-09
//  Modified by Emilio P Egido on 2025-08-25
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sucatalog: SUCatalog
    @AppStorage(Prefs.key(.seedProgram)) var seedProgram: String = ""
    @AppStorage(Prefs.key(.osNameID)) var osNameID: String = ""
    @State private var refreshID = UUID()
    var countersText: String = ""

    var body: some View {
        PreferencesView().environmentObject(sucatalog).navigationTitle(NSLocalizedString("Download Full Installer", comment: "Main window title"))
        VStack(alignment: .center, spacing: 4) {
            HStack(alignment: .center) {
                Text("")
                Spacer()
            }

            if #available(macOS 14.0, *) {
                List(sucatalog.installers, id: \.id) { installer in
                    InstallerView(product: installer)
                }
                .padding(4)
                // ---> Test, VStack border
//                .border(.mint, width: 1)
                .contentMargins(.leading, 1, for: .scrollContent)
            } else {
                List(sucatalog.installers, id: \.id) { installer in
                    InstallerView(product: installer)
                }
                .padding(4)
            }

            DownloadView()
        }

        .frame(
            minWidth: 490.0,
            idealWidth: 490.0,
            maxWidth: 490.0,
            minHeight: 562.0,
            alignment: .center
        )

        .padding(.bottom, 12)
        .padding(.horizontal, 28)

        HStack(alignment: .center) {}

            // ---> Count of listed installers has issues, always shows all OSes count
//         HStack { Text("(\(sucatalog.installers.count) pkg(s) in \(self.seedProgram) catalog)\n") .font(.headline) }

    }

    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }
}

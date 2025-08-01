//
//  ContentView.swift
//  FetchInstallerPkg
//
//  Created by Armin Briegel on 2021-06-09.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sucatalog: SUCatalog
    @AppStorage(Prefs.key(.seedProgram)) var seedProgram: String = ""
    @AppStorage(Prefs.key(.osNameID)) var osNameID: String = ""
    var countersText: String = ""

    var body: some View {
        PreferencesView().environmentObject(sucatalog).navigationTitle("Download Full Installer")
        VStack(alignment: .center) {
            HStack(alignment: .center) { Text("")
                Spacer()
            }

            if #available(macOS 14.0, *) {
                List(sucatalog.installers, id: \.id) { installer in
                    InstallerView(product: installer)
                }
                .padding(4)

                // ---> Test, list border
                // .border(Color.green, width: 1)

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
            minWidth: 400.0,
            maxWidth: 500.0,
            minHeight: 400.0,
            alignment: .center
        )
        HStack(alignment: .center) { Text("").padding(1)
        }
        // ---> count of listed packages, it has issues
        // HStack { Text("(\(sucatalog.installers.count) pkg(s) in \(self.seedProgram) catalog)\n") .font(.headline) }
    }

    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }
}

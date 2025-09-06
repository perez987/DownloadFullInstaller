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
        PreferencesView().environmentObject(sucatalog).navigationTitle(Text("Download Full Installer"))

        VStack(alignment: .center, spacing: 4) {

                HStack(alignment: .center) { 
                    Text("")
                    Spacer()
                    LanguageSelectorView()
                }

                if #available(macOS 14.0, *) {
                    List(sucatalog.installers, id: \.id) { installer in
                        InstallerView(product: installer)
                    }
                    .padding(4)

                    // ---> Test, VStack border
//                    .border(.mint, width: 1)

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
                            minWidth: 472.0,
                            idealWidth: 472.0,
                            maxWidth: 472.0,
//                            minHeight: 500.0,
//                            idealHeight: 500.0,
//                            maxHeight: 500.0,
                alignment: .center
            )

            .padding(.bottom, 12)
            .padding(.horizontal, 28)


            HStack(alignment: .center) { Text("").padding(1)
            }
            // ---> there are issues with the count of listed installers
            // HStack { Text("(\(sucatalog.installers.count) pkg(s) in \(self.seedProgram) catalog)\n") .font(.headline) }

    }

    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
        
    }
    
}

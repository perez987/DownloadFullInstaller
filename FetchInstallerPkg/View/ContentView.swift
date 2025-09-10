//
//  ContentView.swift
//  FetchInstallerPkg
//
//  Created by Armin Briegel on 2021-06-15
//  Modified by Emilio P Egido on 2025-08-25
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sucatalog: SUCatalog
    @EnvironmentObject var languageManager: LanguageManager
    @AppStorage(Prefs.key(.seedProgram)) var seedProgram: String = ""
    @AppStorage(Prefs.key(.osNameID)) var osNameID: String = ""
    @State private var refreshID = UUID()
    var countersText: String = ""

    var body: some View {
        //        PreferencesView().environmentObject(sucatalog).navigationTitle("Download Full Installer")
        PreferencesView().environmentObject(sucatalog).navigationTitle(NSLocalizedString("Download Full Installer", comment: ""))
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
            minWidth: 472.0,
            idealWidth: 472.0,
            maxWidth: 472.0,
            minHeight: 550.0,
//            idealHeight: 540.0,
//            maxHeight: 540.0,
            alignment: .center
        )
        
        HStack(alignment: .center) { Text("").padding(1)
        }
        //---> there are issues with the count of listed installers
        // HStack { Text("(\(sucatalog.installers.count) pkg(s) in \(self.seedProgram) catalog)\n") .font(.headline) }
        
        .id(refreshID) // Force view refresh when language changes
        .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
            refreshID = UUID()
        }
    }

    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }
}

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
    @State private var refreshID = UUID()
    var countersText: String = ""

    var body: some View {
        PreferencesView().environmentObject(sucatalog).navigationTitle(NSLocalizedString("Download Full Installer", comment: "Main window title"))
        VStack(alignment: .center, spacing: 4) {
            HStack(alignment: .center) {
                Text("")
                Spacer()
            }

            if #available(macOS 15.0, *) {
                // macOS 15 Sequoia and later - no overlay
                List(sucatalog.installers, id: \.id) { installer in
                    InstallerView(product: installer)
                }
                .padding(4)
                .contentMargins(.leading, 1, for: .scrollContent)
            } else if #available(macOS 14.0, *) {
                // macOS 14 Sonoma - with overlay
                List(sucatalog.installers, id: \.id) { installer in
                    InstallerView(product: installer)
                }
                .padding(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.tertiary, lineWidth: 1)
                        .padding(5)
                )
                .contentMargins(.leading, 1, for: .scrollContent)
            } else {
                // macOS 13 Ventura - with overlay
                List(sucatalog.installers, id: \.id) { installer in
                    InstallerView(product: installer)
                }
                .padding(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.tertiary, lineWidth: 1)
                        .padding(5)
                )
            }

            DownloadView()
        }
        .id(refreshID) // Force view refresh when language or download path changes
        .frame(
            minWidth: 490.0,
            idealWidth: 490.0,
            maxWidth: 490.0,
            minHeight: 562.0,
            alignment: .center
        )
        .padding(.bottom, 12)
        .padding(.horizontal, 28)
        .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
            refreshID = UUID()
        }
        .onReceive(NotificationCenter.default.publisher(for: .downloadPathChanged)) { _ in
            print("Download path changed notification, refreshing view")
            refreshID = UUID()
        }

        HStack(alignment: .center) {}
        
    }

    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }
}

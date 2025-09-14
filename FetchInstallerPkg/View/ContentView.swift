//
//  ContentView.swift
//  FetchInstallerPkg
//
//  Created by Armin Briegel on 2021-06-09.
//  Modified by Emilio P Egido on 2025-08-25.
//

import SwiftUI


struct ContentView: View {
    @EnvironmentObject var sucatalog: SUCatalog
    @AppStorage(Prefs.key(.seedProgram)) var seedProgram: String = ""
    
    var body: some View {
        VStack(alignment: .leading){
            Text("Download Full Installer")
                .font(.title)
                .multilineTextAlignment(.leading)
            
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
        .padding()
        .frame(
             minWidth: 482.0,
             idealWidth: 482.0,
             maxWidth: 482.0,
             minHeight: 590.0,
 //            idealHeight: 540.0,
 //            maxHeight: 540.0,
             alignment: .center
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}





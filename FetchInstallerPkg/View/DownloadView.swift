//
//  DownloadView.swift
//  FetchInstallerPkg
//
//  Created by Armin Briegel on 2021-06-15.
//

import SwiftUI

struct DownloadView: View {
    @StateObject var downloadManager = DownloadManager.shared

    var body: some View {
        if downloadManager.isDownloading {
            VStack(alignment: .leading) {
                HStack {
                    Text(" ")
                    Text(String(format: NSLocalizedString("Downloading %@", comment: ""), downloadManager.filename ?? "InstallAssistant.pkg"))
                    Spacer()
                    Text(downloadManager.progressString)
                        .font(.footnote)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text(" ")
                }
                HStack {
                    Text(" ")
                    ProgressView(value: downloadManager.progress)
                    Button(action: { downloadManager.cancel() }) {
                        Image(systemName: "xmark.circle.fill").accentColor(.gray)
                            .help(String(format: NSLocalizedString("Cancel %@ download", comment: ""), downloadManager.filename ?? "InstallAssistant.pkg"))
                    }.buttonStyle(.borderless)
                    Text(" ")
                }
            }
            .multilineTextAlignment(.leading)
        }
        if downloadManager.isComplete {
            HStack {
                Text(String(format: NSLocalizedString("Downloaded %@", comment: ""), downloadManager.filename ?? "InstallAssistant.pkg"))
                    .padding(.vertical, 6)
                Spacer()
                
                if #available(macOS 26.0, *) {
                    Button(action: {
                        downloadManager.revealInFinder()
                    })
                    { Text("Show in Finder")
                            .help(NSLocalizedString("Show the installer in the Downloads folder", comment: ""))
                    }
                }
                else {
                    Button(action: {
                        downloadManager.revealInFinder()
                    }) {
                        Image(systemName: "magnifyingglass")
                        Text("Show in Finder")
                            .help(NSLocalizedString("Show the installer in the Downloads folder", comment: ""))
                    }
                }
            }
        }
    }
}

struct DownloadView_Previews: PreviewProvider {
    static var previews: some View {
        DownloadView()
    }
}

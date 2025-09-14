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
                    Text(String(format: NSLocalizedString("Downloading %@", comment: ""), downloadManager.filename ?? "InstallAssistant.pkg"))
                        .font(.footnote)
                    Spacer()
                    Text(downloadManager.progressString)
                        .font(.footnote)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                HStack {
                    ProgressView(value: downloadManager.progress)
                    Button(action: {downloadManager.cancel()}) {
                        Image(systemName: "xmark.circle.fill").accentColor(.gray)
                            .help(String(format: NSLocalizedString("Cancel %@ download", comment: ""), downloadManager.filename ?? "InstallAssistant.pkg"))
                    }.buttonStyle(.borderless)
                }
                
            }
            .multilineTextAlignment(.leading)
        }
        if downloadManager.isComplete {
            HStack {
                Text(String(format: NSLocalizedString("Downloaded %@", comment: ""), downloadManager.filename ?? "InstallAssistant.pkg"))
                    .font(.footnote)
                Spacer()
                
                    Button(action: {
                        downloadManager.revealInFinder()
                    })
                    { Text(NSLocalizedString("Show in Finder", comment: ""))
                            .help(NSLocalizedString("Show the installer in the Downloads folder", comment: ""))
                    }
                    .font(.body)                
            }
        }
    }
}

struct DownloadView_Previews : PreviewProvider {
    static var previews: some View {
        DownloadView()
    }
}


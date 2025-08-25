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
                    Text("Downloading \(downloadManager.filename ?? "InstallAssistant.pkg")")
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
                            .help("Cancel \(downloadManager.filename ?? "InstallAssistant.pkg") download")
                    }.buttonStyle(.borderless)
                    Text(" ")
                }
            }
            .multilineTextAlignment(.leading)
        }
        if downloadManager.isComplete {
            HStack {
                Text("Downloaded \(downloadManager.filename ?? "InstallAssistant.pkg")")
                    .padding(.vertical, 6)
                Spacer()
                
                if #available(macOS 26.0, *) {
                    Button(action: {
                        downloadManager.revealInFinder()
                    })
                    { Text("Show in Finder")
                            .help("Show the installer in the Downloads folder")
                    }
                }
                else {
                    Button(action: {
                        downloadManager.revealInFinder()
                    }) {
                        Image(systemName: "magnifyingglass")
                        Text("Show in Finder")
                            .help("Show the installer in the Downloads folder")
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

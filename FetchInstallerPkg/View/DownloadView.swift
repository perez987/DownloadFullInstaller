//
//  DownloadView.swift
//
//  Created by Armin Briegel on 2021-06-15
//

import SwiftUI

struct DownloadView: View {
    @StateObject var downloadManager = DownloadManager.shared

    var body: some View {
        ZStack {
            // Liquid glass background for download area on macOS 15+
            if #available(macOS 15.0, *) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .opacity(0.7)
            }
            
            VStack {
                if downloadManager.isDownloading {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(" ")
                            Text(String(format: NSLocalizedString("Downloading %@", comment: "Downloading progress text"), downloadManager.filename ?? "InstallAssistant.pkg"))
                                .foregroundStyle(
                                    Group {
                                        if #available(macOS 15.0, *) {
                                            .primary.opacity(0.9)
                                        } else {
                                            .primary
                                        }
                                    }
                                )
                            Spacer()
                            Text(downloadManager.progressString)
                                .font(.footnote)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .foregroundStyle(.secondary)
                            Text(" ")
                        }
                        HStack {
                            Text(" ")
                            ProgressView(value: downloadManager.progress)
                                .tint(
                                    Group {
                                        if #available(macOS 15.0, *) {
                                            .blue.opacity(0.8)
                                        } else {
                                            .blue
                                        }
                                    }
                                )
                            Button(action: { downloadManager.cancel() }) {
                                ZStack {
                                    if #available(macOS 15.0, *) {
                                        Circle()
                                            .fill(.thinMaterial)
                                            .opacity(0.5)
                                            .frame(width: 24, height: 24)
                                    }
                                    Image(systemName: "xmark.circle.fill")
                                        .accentColor(.gray)
                                        .help(String(format: NSLocalizedString("Cancel %@ download", comment: "Cancel download button help"), downloadManager.filename ?? "InstallAssistant.pkg"))
                                }
                            }.buttonStyle(.borderless)
                            Text(" ")
                        }
                    }
                    .multilineTextAlignment(.leading)
                }
                if downloadManager.isComplete {
                    HStack {
                        Text(String(format: NSLocalizedString("Downloaded %@", comment: "Downloaded complete text"), downloadManager.filename ?? "InstallAssistant.pkg"))
                            .padding(.vertical, 6)
                            .foregroundStyle(
                                Group {
                                    if #available(macOS 15.0, *) {
                                        .primary.opacity(0.9)
                                    } else {
                                        .primary
                                    }
                                }
                            )
                        Spacer()
                        
                        if #available(macOS 26.0, *) {
                            Button(action: {
                                downloadManager.revealInFinder()
                            })
                            { 
                                ZStack {
                                    if #available(macOS 15.0, *) {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.thinMaterial)
                                            .opacity(0.6)
                                    }
                                    Text(NSLocalizedString("Show in Finder", comment: "Show in Finder button"))
                                        .help(NSLocalizedString("Show the installer in the Downloads folder", comment: "Show in Finder button help"))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                }
                            }
                        }
                        else {
                            Button(action: {
                                downloadManager.revealInFinder()
                            }) {
                                ZStack {
                                    if #available(macOS 15.0, *) {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.thinMaterial)
                                            .opacity(0.6)
                                    }
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                        Text(NSLocalizedString("Show in Finder", comment: "Show in Finder button"))
                                            .help(NSLocalizedString("Show the installer in the Downloads folder", comment: "Show in Finder button help"))
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
}

struct DownloadView_Previews: PreviewProvider {
    static var previews: some View {
        DownloadView()
    }
}

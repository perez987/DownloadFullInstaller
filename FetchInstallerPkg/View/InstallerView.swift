//
//  InstallerView.swift
//
//  Created by Armin Briegel on 2021-06-15
//

import SwiftUI

class DisplayedCount {
    var displayedRows = 0
}

struct InstallerView: View {
    @ObservedObject var product: Product
    @StateObject var downloadManager = DownloadManager.shared
    @State var isReplacingFile = false
    @State var failed = false
    @State var filename = "InstallerAssistant.pkg"
    @State var installerURLFiles: [String] = []

    var body: some View {
        if product.hasLoaded {

            // Filter data on osName if needed
            if (Prefs.osNameID.rawValue == OsNameID.osAll.rawValue) || (Prefs.osNameID.rawValue != OsNameID.osAll.rawValue && product.osName == Prefs.osNameID.rawValue) {
                ZStack {
                    // Liquid glass background for individual installer items on macOS 15+
                    if #available(macOS 15.0, *) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.thinMaterial)
                            .opacity(0.4)
                    }
                    
                    HStack {
                    IconView(product: product)

                    VStack(alignment: .leading) {
                        HStack {
                            Text(product.title ?? "<no title>")
                                .font(.headline)
                                .foregroundStyle(
                                    // Enhanced text styling for liquid glass
                                    Group {
                                        if #available(macOS 15.0, *) {
                                            .primary.opacity(0.9)
                                        } else {
                                            .primary
                                        }
                                    }
                                )
                            Spacer()
                            Text(product.productVersion ?? "<no version>")
                                .frame(alignment: .trailing)
                                .foregroundStyle(
                                    Group {
                                        if #available(macOS 15.0, *) {
                                            .secondary.opacity(0.8)
                                        } else {
                                            .secondary
                                        }
                                    }
                                )
                        }
                        HStack {
                            Text(product.postDate, style: .date)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Text(Prefs.byteFormatter.string(fromByteCount: Int64(product.installAssistantSize)))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(product.buildVersion ?? "<no build>")
                                .frame(alignment: .trailing)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button(action: {
                        filename = "InstallAssistant-\(product.productVersion ?? "V")-\(product.buildVersion ?? "B").pkg"
                        downloadManager.filename = filename
                        isReplacingFile = downloadManager.fileExists

                        if !isReplacingFile {
                            do {
                                try downloadManager.download(url: product.installAssistantURL)
                            } catch {
                                failed = true
                            }
                        }

                    }) {
                        ZStack {
                            // Enhanced button styling for liquid glass
                            if #available(macOS 15.0, *) {
                                Circle()
                                    .fill(.thinMaterial)
                                    .opacity(0.6)
                                    .frame(width: 32, height: 32)
                            }
                            
                            Image(systemName: "arrow.down.circle")
                                .font(.title)
                                .foregroundStyle(
                                    Group {
                                        if #available(macOS 15.0, *) {
                                            .tint.opacity(0.9)
                                        } else {
                                            .tint
                                        }
                                    }
                                )
                        }
                    }
                    .help(String(format: NSLocalizedString("Download %@ %@ (%@) Installer", comment: "Download button help text"), product.osName ?? "", product.productVersion ?? "", product.buildVersion ?? ""))
                    .alert(isPresented: $isReplacingFile) {
                        Alert(
                            title: Text("“\(filename)” already exists. Do you want to replace it?"),
                            message: Text(NSLocalizedString("A file with the same name already exists in that location. Replacing it will overwrite its current contents.", comment: "File replacement alert message")),
                            primaryButton: .cancel(Text(NSLocalizedString("Cancel", comment: "Cancel button"))),
                            secondaryButton: .destructive(
                                Text(NSLocalizedString("Replace", comment: "Replace button")),
                                action: {
                                    do {
                                        try downloadManager.download(url: product.installAssistantURL, replacing: true)
                                    } catch {
                                        failed = true
                                    }
                                }
                            )
                        )
                    }
                    .disabled(downloadManager.isDownloading)
                    .buttonStyle(.borderless)
                    .controlSize(.mini)

                // Context menu: copy to clipboard the URL of the specified InstallAssistant.pkg
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }.contextMenu {
                    Button(action: {
                        if let text = product.installAssistantURL?.absoluteString {
//                            print(text)
                            print("InstallAssistant URL copied to clipboard")
                            let pb = NSPasteboard.general
                            pb.clearContents()
                            pb.setString(text, forType: .string)
                        }
                    }) {
                        Image(systemName: "doc.on.clipboard")
                        let package = (product.installAssistantURL?.absoluteString.components(separatedBy: "/").last ?? "")
                        Text(String(format: NSLocalizedString("Copy %@ %@ (%@) %@ URL", comment: "Copy URL context menu item"), product.osName ?? "", product.productVersion ?? "", product.buildVersion ?? "", package))
                    }
                }

            }
        }
    }
}

struct InstallerView_Previews: PreviewProvider {
    static var previews: some View {
        let catalog = SUCatalog()

        if let preview_product = catalog.installers.first {
            InstallerView(product: preview_product)

        }
    }
}

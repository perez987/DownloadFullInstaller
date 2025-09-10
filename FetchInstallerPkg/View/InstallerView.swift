//
//  InstallerView.swift
//  FetchInstallerPkg
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
                HStack {
                    IconView(product: product)

                    VStack(alignment: .leading) {
                        HStack {
                            Text(product.title ?? NSLocalizedString("<no title>", comment: ""))
                                .font(.headline)
                            Spacer()
                            Text(product.productVersion ?? NSLocalizedString("<no version>", comment: ""))
                                .frame(alignment: .trailing)
                        }
                        HStack {
                            Text(product.postDate, style: .date)
                                .font(.footnote)
                            Text(Prefs.byteFormatter.string(fromByteCount: Int64(product.installAssistantSize)))
                                .font(.footnote)
                            Spacer()
                            Text(product.buildVersion ?? NSLocalizedString("<no build>", comment: ""))
                                .frame(alignment: .trailing)
                                .font(.footnote)
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
                        Image(systemName: "arrow.down.circle").font(.title)
                    }
                    .help(String(format: NSLocalizedString("Download %@ %@ (%@) Installer", comment: ""), product.osName ?? "", product.productVersion ?? "", product.buildVersion ?? ""))
                    .alert(isPresented: $isReplacingFile) {
                        Alert(
                            title: Text(String(format: NSLocalizedString("%@ already exists. Do you want to replace it?", comment: ""), filename)),
                             message: Text(NSLocalizedString("A file with the same name already exists in that location. Replacing it will overwrite its current contents.", comment: "")),
                            primaryButton: .cancel(Text("Cancel")),
                            secondaryButton: .destructive(
                                Text("Replace"),
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
                }.contextMenu {
                    Button(action: {
                        if let text = product.installAssistantURL?.absoluteString {
                            print("Copy \(text)")
                            let pb = NSPasteboard.general
                            pb.clearContents()
                            pb.setString(text, forType: .string)
                        }
                    }) {
                        Image(systemName: "doc.on.clipboard")
                        let package = (product.installAssistantURL?.absoluteString.components(separatedBy: "/").last ?? "")
                        Text(String(format: NSLocalizedString("Copy %@ %@ (%@) %@ URL", comment: ""), product.osName ?? "", product.productVersion ?? "", product.buildVersion ?? "", package))
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
        } else {
            Text(NSLocalizedString("Could not load catalog", comment: ""))
        }
    }
}

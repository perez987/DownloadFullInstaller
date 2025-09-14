//
//  InstallerView.swift
//  FetchInstallerPkg
//
//  Created by Armin Briegel on 2021-06-15.
//

import SwiftUI

struct InstallerView: View {
    @ObservedObject var product: Product
    @StateObject var downloadManager = DownloadManager.shared
    @State var isReplacingFile = false
    @State var failed = false
    @State var filename = "InstallerAssistant.pkg"
    
    var body: some View {
        if product.isLoading {
            Text(NSLocalizedString("Loading...", comment: ""))
        } else {
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
                .help(String(format: NSLocalizedString("Download macOS %@ (%@) Installer", comment: ""), product.productVersion ?? "", product.buildVersion ?? ""))
                .alert(isPresented: $isReplacingFile) {
                    Alert(
                        title: Text(String(format: NSLocalizedString("%@ already exists. Do you want to replace it?", comment: ""), filename)),
                        message: Text(NSLocalizedString("A file with the same name already exists in that location. Replacing it will overwrite its current contents.", comment: "")),
                        primaryButton: .cancel(Text(NSLocalizedString("Cancel", comment: ""))),
                        secondaryButton: .destructive(
                            Text(NSLocalizedString("Replace", comment: "")),
                            action: {
                        do {
                            try downloadManager.download(url:  product.installAssistantURL, replacing: true)
                        } catch {
                            failed = true
                        }
                    }
                        )
                    )
                }
                
                .disabled(downloadManager.isDownloading)
                .buttonStyle(.borderless)
                .controlSize(/*@START_MENU_TOKEN@*/.large/*@END_MENU_TOKEN@*/)
                
            }.contextMenu() {
                Button(action: {
                    if let text = product.installAssistantURL?.absoluteString {
                        let pb = NSPasteboard.general
                        pb.clearContents()
                        pb.setString(text, forType: .string)
                    }
                }) {
                    Image(systemName: "doc.on.clipboard")
                    Text(String(format: NSLocalizedString("Copy macOS %@ (%@) URL", comment: ""), product.productVersion ?? "", product.buildVersion ?? "InstallAssistant.pkg"))
                }
            }
        }
    }
}

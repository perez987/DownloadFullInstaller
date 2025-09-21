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
    @State var isCreatingInstaller = false
    @State var installerCreationFailed = false

    var body: some View {
        if product.hasLoaded {

            // Filter data on osName if needed
            if (Prefs.osNameID.rawValue == OsNameID.osAll.rawValue) || (Prefs.osNameID.rawValue != OsNameID.osAll.rawValue && product.osName == Prefs.osNameID.rawValue) {
                HStack {
                    IconView(product: product)

                    VStack(alignment: .leading) {
                        HStack {
                            Text(product.title ?? "<no title>")
                                .font(.headline)
                            Spacer()
                            Text(product.productVersion ?? "<no version>")
                                .frame(alignment: .trailing)
                        }
                        HStack {
                            Text(product.postDate, style: .date)
                                .font(.footnote)
                            Text(Prefs.byteFormatter.string(fromByteCount: Int64(product.installAssistantSize)))
                                .font(.footnote)
                            Spacer()
                            Text(product.buildVersion ?? "<no build>")
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

                    // Button to create macOS Install app from downloaded PKG
                    Button(action: {
                        createInstallerApp()
                    }) {
                        Image(systemName: "externaldrive.badge.plus").font(.title)
                    }
                    .help(String(format: NSLocalizedString("Create %@ %@ (%@) Install App", comment: "Create installer app button help text"), product.osName ?? "", product.productVersion ?? "", product.buildVersion ?? ""))
                    .disabled(downloadManager.isDownloading || isCreatingInstaller || !downloadManager.isComplete)
                    .buttonStyle(.borderless)
                    .controlSize(.mini)

                // Context menu: copy to clipboard the URL of the specified InstallAssistant.pkg
                }
                .liquidGlass(intensity: .subtle)
                .contextMenu {
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
    
    // Function to create macOS Install app from downloaded PKG installer
    private func createInstallerApp() {
        guard downloadManager.isComplete,
              let localURL = downloadManager.localURL else {
            print("No downloaded installer PKG found")
            installerCreationFailed = true
            return
        }
        
        isCreatingInstaller = true
        installerCreationFailed = false
        
        Task {
            do {
                try await createInstallApp(from: localURL)
                await MainActor.run {
                    isCreatingInstaller = false
                    print("macOS Install app created successfully")
                }
            } catch {
                await MainActor.run {
                    isCreatingInstaller = false
                    installerCreationFailed = true
                    print("Failed to create macOS Install app: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Async function to handle the installer creation process
    private func createInstallApp(from pkgURL: URL) async throws {
        let applicationsURL = URL(fileURLWithPath: "/Applications")
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("installer_extract_\(UUID().uuidString)")
        
        // Create temporary directory
        try FileManager.default.createDirectory(at: tempDir, 
                                              withIntermediateDirectories: true, 
                                              attributes: nil)
        
        defer {
            // Clean up temp directory
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Use pkgutil to extract the PKG contents
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/pkgutil")
        process.arguments = ["--expand", pkgURL.path, tempDir.path]
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "InstallerCreationError", 
                         code: Int(process.terminationStatus), 
                         userInfo: [NSLocalizedDescriptionKey: "Failed to extract installer PKG"])
        }
        
        // Look for the payload and extract it
        let payloadURL = tempDir.appendingPathComponent("InstallAssistant.pkg/Payload")
        
        guard FileManager.default.fileExists(atPath: payloadURL.path) else {
            throw NSError(domain: "InstallerCreationError", 
                         code: 1, 
                         userInfo: [NSLocalizedDescriptionKey: "Payload not found in PKG"])
        }
        
        // Create another temp directory for payload extraction
        let payloadTempDir = FileManager.default.temporaryDirectory.appendingPathComponent("payload_extract_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: payloadTempDir, withIntermediateDirectories: true, attributes: nil)
        
        defer {
            try? FileManager.default.removeItem(at: payloadTempDir)
        }
        
        // Extract payload using cpio
        let extractProcess = Process()
        extractProcess.executableURL = URL(fileURLWithPath: "/bin/bash")
        extractProcess.arguments = ["-c", "cd '\(payloadTempDir.path)' && cat '\(payloadURL.path)' | gunzip -dc | cpio -i"]
        
        try extractProcess.run()
        extractProcess.waitUntilExit()
        
        guard extractProcess.terminationStatus == 0 else {
            throw NSError(domain: "InstallerCreationError", 
                         code: Int(extractProcess.terminationStatus), 
                         userInfo: [NSLocalizedDescriptionKey: "Failed to extract payload"])
        }
        
        // Look for Install *.app in the extracted payload
        let enumerator = FileManager.default.enumerator(at: payloadTempDir,
                                                       includingPropertiesForKeys: [.isDirectoryKey],
                                                       options: [.skipsHiddenFiles])
        
        var installAppURL: URL?
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.pathExtension == "app" && fileURL.lastPathComponent.hasPrefix("Install ") {
                installAppURL = fileURL
                break
            }
        }
        
        guard let sourceAppURL = installAppURL else {
            throw NSError(domain: "InstallerCreationError", 
                         code: 1, 
                         userInfo: [NSLocalizedDescriptionKey: "Install app not found in extracted payload"])
        }
        
        // Copy the Install app to /Applications
        let destinationURL = applicationsURL.appendingPathComponent(sourceAppURL.lastPathComponent)
        
        // Check if we have write permission to /Applications
        guard FileManager.default.isWritableFile(atPath: applicationsURL.path) else {
            throw NSError(domain: "InstallerCreationError", 
                         code: 1, 
                         userInfo: [NSLocalizedDescriptionKey: "No write permission to /Applications folder"])
        }
        
        // Remove existing app if it exists
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        
        try FileManager.default.copyItem(at: sourceAppURL, to: destinationURL)
        
        print("Install app copied to: \(destinationURL.path)")
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

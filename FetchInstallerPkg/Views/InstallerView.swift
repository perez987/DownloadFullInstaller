//
//  InstallerView.swift
//
//  Created by Armin Briegel on 2021-06-15
//  Modified by Emilio P Egido on 2025-12-03
//

import SwiftUI

class DisplayedCount {
    var displayedRows = 0
}

struct InstallerView: View {
    @ObservedObject var product: Product
    @StateObject var multiDownloadManager = MultiDownloadManager.shared
    @State var failed = false
    @State var filename = "InstallerAssistant.pkg"
    @State var installerURLFiles: [String] = []
    @State var isCreatingInstaller = false
    @State private var activeAlert: AppAlertType?
    
    // Computed property for the installer filename
    var installerFilename: String {
        return "InstallAssistant-\(product.productVersion ?? "V")-\(product.buildVersion ?? "B").pkg"
    }
    
    // Computed property to check if the installer has been downloaded
    // This checks the file system and is re-evaluated when the view updates
    var isDownloaded: Bool {
        let destination = Prefs.downloadURL
        let file = destination.appendingPathComponent(installerFilename)
        
        // Start accessing security-scoped resource for file check
        let accessStarted = destination.startAccessingSecurityScopedResource()
        defer {
            if accessStarted {
                destination.stopAccessingSecurityScopedResource()
            }
        }
        
        // Check if file exists on disk (primary check)
        if FileManager.default.fileExists(atPath: file.path) {
            return true
        }
        
        // Also check if this file is in the completed downloads list
        // This ensures the view updates immediately when a download completes
        // (before the user dismisses the completion notification)
        return multiDownloadManager.completedDownloads.contains { $0.filename == installerFilename }
    }

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
                    
                    // Visual indicator for downloaded installers
                    if isDownloaded {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                            .help(NSLocalizedString("This installer has been downloaded", comment: ""))
                    }

                    Button(action: {
                        filename = installerFilename

                        // Check if max downloads reached
                        if !multiDownloadManager.canStartNewDownload {
                            activeAlert = .maxDownloads
                            print("Maximum concurrent downloads reached (3). Please wait for a download to complete")
                            return
                        }

                        // Check if this file is already being downloaded
                        if multiDownloadManager.isDownloading(filename: filename) {
                            return
                        }

                        // Check if file exists on disk
                        let destination = Prefs.downloadURL
                        let file = destination.appendingPathComponent(filename)
                        
                        // Start accessing security-scoped resource for file check
                        let accessStarted = destination.startAccessingSecurityScopedResource()
                        defer {
                            if accessStarted {
                                destination.stopAccessingSecurityScopedResource()
                            }
                        }
                        let fileExists = FileManager.default.fileExists(atPath: file.path)

                        if fileExists {
                            activeAlert = .replaceFile(filename: filename)
                        } else {
                            do {
                                _ = try multiDownloadManager.startDownload(url: product.installAssistantURL, filename: filename)
                            } catch {
                                failed = true
                            }
                        }

                    }) {
                        Image(systemName: "arrow.down.circle").font(.title)
                    }
                    .help(String(format: NSLocalizedString("Download %@ %@ (%@) Installer", comment: ""), product.osName ?? "", product.productVersion ?? "", product.buildVersion ?? ""))
                    .disabled(multiDownloadManager.isDownloading(filename: installerFilename))
                    .buttonStyle(.borderless)
                    .controlSize(.mini)

                    Button(action: {
                        createInstallerApp()
                    }) {
                        if isCreatingInstaller {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: "square.and.arrow.down.on.square").font(.title)
                        }
                    }
                    .help(String(format: NSLocalizedString("Create Installer App from %@ %@ (%@)", comment: ""), product.osName ?? "", product.productVersion ?? "", product.buildVersion ?? ""))
                    .disabled(multiDownloadManager.isDownloading(filename: installerFilename) || isCreatingInstaller)
                    .buttonStyle(.borderless)
                    .controlSize(.mini)

                    // Context menu: copy to clipboard the URL of the specified InstallAssistant.pkg
                }
                .liquidGlass(intensity: .subtle)
                .contextMenu {
                    Button(action: {
                        if let text = product.installAssistantURL?.absoluteString {
//                            print("\(text)")
                            print("InstallAssistant URL copied to clipboard")
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
                // Handle multiple different alerts in a single view using appAlert extension
                .appAlert(item: $activeAlert) { alertType in
                    switch alertType {
                    case .replaceFile:
                        do {
                            _ = try multiDownloadManager.startDownload(url: product.installAssistantURL, filename: filename, replacing: true)
                        } catch {
                            failed = true
                        }
                    default:
                        break
                    }
                }
            }
        }
    }

    func createInstallerApp() {
        // Build the filename
        filename = installerFilename
        let destination = Prefs.downloadURL
        let pkgPath = destination.appendingPathComponent(filename).path
        
        // Start accessing security-scoped resource for file operations
        let accessStarted = destination.startAccessingSecurityScopedResource()

        // Check if the PKG file exists
        guard FileManager.default.fileExists(atPath: pkgPath) else {
            // Stop accessing if we're returning early
            if accessStarted {
                destination.stopAccessingSecurityScopedResource()
            }
            let folderName = destination.lastPathComponent
            activeAlert = .installerCreation(
                title: NSLocalizedString("Error Creating Installer", comment: ""),
                message: String(format: NSLocalizedString("The installer package %@ does not exist in the %@ folder. Please download it first.", comment: ""), filename, folderName)
            )
            return
        }

        isCreatingInstaller = true

        // Open the PKG file with the default installer application
        // This works within sandbox constraints and shows the standard macOS installer UI
        let pkgURL = URL(fileURLWithPath: pkgPath)
        NSWorkspace.shared.open(pkgURL, configuration: NSWorkspace.OpenConfiguration()) { _, error in
            // Stop accessing security-scoped resource after the operation completes
            if accessStarted {
                destination.stopAccessingSecurityScopedResource()
            }
            
            DispatchQueue.main.async {
                self.isCreatingInstaller = false

                if error == nil {
                    print("Installer package opened successfully")
                    // Show success alert
//                    self.activeAlert = .installerCreation(
//                        title: NSLocalizedString("Success", comment: ""),
//                        message: NSLocalizedString("The installer package has been opened. Follow the on-screen instructions to complete the installation", comment: "")
//                    )
                } else {
                    print("Failed to open installer package: \(error?.localizedDescription ?? "Unknown error")")
                    let folderName = destination.lastPathComponent
                    self.activeAlert = .installerCreation(
                        title: NSLocalizedString("Error Creating Installer", comment: ""),
                        message: String(format: NSLocalizedString("Failed to open the installer package. Please try opening it manually from the %@ folder.", comment: ""), folderName)
                    )
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

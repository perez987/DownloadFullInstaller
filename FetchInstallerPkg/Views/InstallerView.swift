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
    @StateObject var multiDownloadManager = MultiDownloadManager.shared
    @State var isReplacingFile = false
    @State var failed = false
    @State var filename = "InstallerAssistant.pkg"
    @State var installerURLFiles: [String] = []
    @State var isCreatingInstaller = false
    @State var showInstallerCreationAlert = false
    @State var installerCreationAlertTitle = ""
    @State var installerCreationAlertMessage = ""
    @State var showMaxDownloadsAlert = false

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
                        
                        // Check if max downloads reached
                        if !multiDownloadManager.canStartNewDownload {
                            showMaxDownloadsAlert = true
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
                        isReplacingFile = FileManager.default.fileExists(atPath: file.path)

                        if !isReplacingFile {
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
                    .alert(isPresented: $isReplacingFile) {
                        Alert(
                            title: Text("\(filename) already exists. Do you want to replace it?"),
                            message: Text(NSLocalizedString("A file with the same name already exists in that location. Replacing it will overwrite its current contents.", comment: "")),
                            primaryButton: .cancel(Text(NSLocalizedString("Cancel", comment: ""))),
                            secondaryButton: .destructive(
                                Text(NSLocalizedString("Replace", comment: "")),
                                action: {
                                    do {
                                        _ = try multiDownloadManager.startDownload(url: product.installAssistantURL, filename: filename, replacing: true)
                                    } catch {
                                        failed = true
                                    }
                                }
                            )
                        )
                    }
                    .disabled(multiDownloadManager.isDownloading(filename: "InstallAssistant-\(product.productVersion ?? "V")-\(product.buildVersion ?? "B").pkg"))
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

                    .alert(isPresented: $showInstallerCreationAlert) {
                        Alert(
                            title: Text(installerCreationAlertTitle),
                            message: Text(installerCreationAlertMessage),
                            dismissButton: .default(Text(NSLocalizedString("OK", comment: "")))
                        )
                    }
                    .disabled(multiDownloadManager.isDownloading(filename: "InstallAssistant-\(product.productVersion ?? "V")-\(product.buildVersion ?? "B").pkg") || isCreatingInstaller)
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
                .alert(isPresented: $showMaxDownloadsAlert) {
                    Alert(
                        title: Text(NSLocalizedString("Maximum Downloads Reached", comment: "")),
                        message: Text(NSLocalizedString("You can only download up to 3 installers at the same time. Please wait for a download to complete before starting a new one.", comment: "")),
                        dismissButton: .default(Text(NSLocalizedString("OK", comment: "")))
                    )
                }

            }
        }
    }
    
    func createInstallerApp() {
            // Build the filename
        filename = "InstallAssistant-\(product.productVersion ?? "V")-\(product.buildVersion ?? "B").pkg"
        let pkgPath = Prefs.downloadURL.appendingPathComponent(filename).path
        
            // Check if the PKG file exists
        guard FileManager.default.fileExists(atPath: pkgPath) else {
            installerCreationAlertTitle = NSLocalizedString("Error Creating Installer", comment: "")
            installerCreationAlertMessage = String(format: NSLocalizedString("The installer package %@ does not exist in the Downloads folder. Please download it first.", comment: ""), filename)
            showInstallerCreationAlert = true
            return
        }
        
        isCreatingInstaller = true
        
            // Open the PKG file with the default installer application
            // This works within sandbox constraints and shows the standard macOS installer UI
        let pkgURL = URL(fileURLWithPath: pkgPath)
        NSWorkspace.shared.open(pkgURL, configuration: NSWorkspace.OpenConfiguration()) { app, error in
            DispatchQueue.main.async {
                self.isCreatingInstaller = false
                
                if error == nil {
                    print("Installer package opened successfully")
                        // Show success alert
//                    self.installerCreationAlertTitle = NSLocalizedString("Success", comment: "")
//                    self.installerCreationAlertMessage = NSLocalizedString("The installer package has been opened. Follow the on-screen instructions to complete the installation", comment: "")
//                    self.showInstallerCreationAlert = true
                } else {
                    print("Failed to open installer package: \(error?.localizedDescription ?? "Unknown error")")
                    self.installerCreationAlertTitle = NSLocalizedString("Error Creating Installer", comment: "")
                    self.installerCreationAlertMessage = NSLocalizedString("Failed to open the installer package. Please try opening it manually from the Downloads folder.", comment: "")
                    self.showInstallerCreationAlert = true
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

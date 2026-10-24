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
    @ObservedObject var multiDownloadManager = MultiDownloadManager.shared
    @State var filename = "InstallerAssistant.pkg"
    @State var installerURLFiles: [String] = []
    @State var isCreatingInstaller = false
    @State private var activeAlert: AppAlertType?
    @State private var isDownloaded = false

    /// Computed property for the installer filename
    var installerFilename: String {
        "InstallAssistant-\(product.productVersion ?? "V")-\(product.buildVersion ?? "B").pkg"
    }

    /// Check if the installer has been downloaded
    /// This checks the file system and should only be called after sandbox is initialized
    private func checkIfDownloaded() {
        let destination = Prefs.downloadURL
        let file = destination.appendingPathComponent(installerFilename)

        // Start accessing security-scoped resource for file check (only if needed)
        let accessStarted = Prefs.startAccessingDownloadURL()
        defer {
            Prefs.stopAccessingDownloadURL(accessStarted)
        }

        // Check if file exists on disk (primary check)
        if FileManager.default.fileExists(atPath: file.path) {
            isDownloaded = true
            return
        }

        // Also check if this file is in the completed downloads list
        // This ensures the view updates immediately when a download completes
        // (before the user dismisses the completion notification)
        isDownloaded = multiDownloadManager.completedDownloads.contains { $0.localURL == file }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                IconView(product: product)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(product.title ?? "<no title>")
                            .font(.title3.weight(.semibold))
                            .lineLimit(1)
                        Text(product.productVersion ?? "<no version>")
                            .font(.title3)
                            .fixedSize()
                        Text(product.buildVersion ?? "<no build>")
                            .font(.body)
                            .fixedSize()
                        Spacer(minLength: 4)

                        Button(action: {
                            filename = installerFilename

                            if !multiDownloadManager.canStartNewDownload {
                                activeAlert = .maxDownloads
                                print("Maximum concurrent downloads reached (3). Please wait for a download to complete")
                                return
                            }

                            if multiDownloadManager.isDownloading(filename: filename) {
                                return
                            }

                            let destination = Prefs.downloadURL
                            let file = destination.appendingPathComponent(filename)
                            let accessStarted = Prefs.startAccessingDownloadURL()
                            defer {
                                Prefs.stopAccessingDownloadURL(accessStarted)
                            }
                            let fileExists = FileManager.default.fileExists(atPath: file.path)

                            if fileExists {
                                activeAlert = .replaceFile(filename: filename)
                            } else {
                                do {
                                    _ = try multiDownloadManager.startDownload(url: product.installAssistantURL, filename: filename)
                                } catch {
                                    activeAlert = .downloadError(message: error.localizedDescription)
                                }
                            }
                        }) {
                            Label(NSLocalizedString("Download", comment: "Download button"), systemImage: "arrow.down.circle")
                        }
                        .help(String(format: NSLocalizedString("Download %@ %@ (%@) Installer", comment: ""), product.osName ?? "", product.productVersion ?? "", product.buildVersion ?? ""))
                        .disabled(multiDownloadManager.isDownloading(filename: installerFilename))
                        .buttonStyle(.borderedProminent)
                        .opacity(multiDownloadManager.isDownloading(filename: installerFilename) ? 0.4 : 1.0)
                    }

                    HStack(spacing: 8) {
                        if isDownloaded {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                                .help(NSLocalizedString("This installer has been downloaded", comment: ""))
                        }
                        Text(product.postDate, style: .date)
                        Text(Prefs.byteFormatter.string(fromByteCount: Int64(product.installAssistantSize)))
                        Spacer()

                        Button(action: {
                            createInstallerApp()
                        }) {
                            if isCreatingInstaller {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .frame(width: 20, height: 20)
                            } else {
                                Label(NSLocalizedString("Create Installer App", comment: "Create installer action"), systemImage: "square.and.arrow.down.on.square")
                            }
                        }
                        .help(String(format: NSLocalizedString("Create Installer App from %@ %@ (%@)", comment: ""), product.osName ?? "<no os>", product.productVersion ?? "<no version>", product.buildVersion ?? "<no build>"))
                        .disabled(multiDownloadManager.isDownloading(filename: installerFilename) || isCreatingInstaller)
                        .buttonStyle(.bordered)
                        .opacity(multiDownloadManager.isDownloading(filename: installerFilename) || isCreatingInstaller ? 0.4 : 1.0)
                    }
                    .font(.body)
                }
            }
        }
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
        .padding(16)
        .glassCard(cornerRadius: 16)
        // Handle multiple different alerts in a single view using appAlert extension
        .appAlert(item: $activeAlert) { alertType in
            switch alertType {
            case .replaceFile:
                do {
                    _ = try multiDownloadManager.startDownload(url: product.installAssistantURL, filename: filename, replacing: true)
                } catch {
                    activeAlert = .downloadError(message: error.localizedDescription)
                }
            default:
                break
            }
        }
        .onAppear {
            // Check if downloaded after view appears, ensuring sandbox is fully initialized
            checkIfDownloaded()
        }
        .onChange(of: multiDownloadManager.completedDownloads) {
            // Update download status when downloads complete
            checkIfDownloaded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .downloadPathChanged)) { _ in
            checkIfDownloaded()
        }
    }

    func createInstallerApp() {
        filename = installerFilename
        let destination = Prefs.downloadURL
        let pkgPath = destination.appendingPathComponent(filename).path

        let accessStarted = Prefs.startAccessingDownloadURL()

        guard FileManager.default.fileExists(atPath: pkgPath) else {
            Prefs.stopAccessingDownloadURL(accessStarted)
            let folderName = destination.lastPathComponent
            activeAlert = .installerCreation(
                title: NSLocalizedString("Error Creating Installer", comment: ""),
                message: String(format: NSLocalizedString("The installer package %@ does not exist in the %@ folder. Please download it first.", comment: ""), filename, folderName)
            )
            return
        }

        isCreatingInstaller = true

        let pkgURL = URL(fileURLWithPath: pkgPath)
        NSWorkspace.shared.open(pkgURL, configuration: NSWorkspace.OpenConfiguration()) { _, error in
            Prefs.stopAccessingDownloadURL(accessStarted)

            Task { @MainActor in
                isCreatingInstaller = false

                if let error {
                    activeAlert = .installerCreation(
                        title: NSLocalizedString("Error Creating Installer", comment: ""),
                        message: String(format: NSLocalizedString("Failed to create installer app. Error: %@", comment: ""), error.localizedDescription)
                    )
                }
            }
        }
    }
}

struct FirmwareView: View {
    let firmware: FirmwareProduct
    @ObservedObject var multiDownloadManager = MultiDownloadManager.shared
    @State private var activeAlert: AppAlertType?
    @State private var isDownloaded = false
    
    private func checkIfDownloaded() {
        let destination = Prefs.downloadURL
        let file = destination.appendingPathComponent(firmware.filename)
        
        let accessStarted = Prefs.startAccessingDownloadURL()
        defer {
            Prefs.stopAccessingDownloadURL(accessStarted)
        }
        
        if FileManager.default.fileExists(atPath: file.path) {
            isDownloaded = true
            return
        }
        
        isDownloaded = multiDownloadManager.completedDownloads.contains { $0.localURL == file }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                FirmwareIconView(firmware: firmware)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text("macOS \(firmware.osName)")
                            .font(.title3.weight(.semibold))
                            .lineLimit(1)
                        Text(firmware.productVersion)
                            .font(.title3)
                            .fixedSize()
                        Text(firmware.buildVersion)
                            .font(.body)
                            .fixedSize()
                        Spacer(minLength: 4)
                        
                        Button(action: {
                            if !multiDownloadManager.canStartNewDownload {
                                activeAlert = .maxDownloads
                                return
                            }
                            
                            if multiDownloadManager.isDownloading(filename: firmware.filename) {
                                return
                            }
                            
                            let destination = Prefs.downloadURL
                            let file = destination.appendingPathComponent(firmware.filename)
                            let accessStarted = Prefs.startAccessingDownloadURL()
                            defer { Prefs.stopAccessingDownloadURL(accessStarted) }
                            let fileExists = FileManager.default.fileExists(atPath: file.path)
                            
                            if fileExists {
                                activeAlert = .replaceFile(filename: firmware.filename)
                            } else {
                                do {
                                    _ = try multiDownloadManager.startDownload(url: firmware.url, filename: firmware.filename)
                                } catch {
                                    activeAlert = .downloadError(message: error.localizedDescription)
                                }
                            }
                        }) {
                            Label(NSLocalizedString("Download", comment: "Download button"), systemImage: "arrow.down.circle")
                        }
                        .help(String(format: NSLocalizedString("Download %@ %@ (%@) Firmware", comment: ""), firmware.osName, firmware.productVersion, firmware.buildVersion))
                        .disabled(multiDownloadManager.isDownloading(filename: firmware.filename))
                        .buttonStyle(.borderedProminent)
                        .opacity(multiDownloadManager.isDownloading(filename: firmware.filename) ? 0.4 : 1.0)
                    }
                    
                    HStack(spacing: 8) {
                        if isDownloaded {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                                .help(NSLocalizedString("This firmware has been downloaded", comment: ""))
                        }
                        Text(firmware.postDate, style: .date)
                        Text(Prefs.byteFormatter.string(fromByteCount: Int64(firmware.size)))
                        Spacer()
                    }
                    .font(.body)
                }
            }
            .contextMenu {
                Button(action: {
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.setString(firmware.url.absoluteString, forType: .string)
                }) {
                    Image(systemName: "doc.on.clipboard")
                    Text(String(format: NSLocalizedString("Copy %@ %@ (%@) %@ URL", comment: ""), firmware.osName, firmware.productVersion, firmware.buildVersion, firmware.filename))
                }
            }
            .padding(16)
            .glassCard(cornerRadius: 16)
            .appAlert(item: $activeAlert) { alertType in
                switch alertType {
                case .replaceFile:
                    do {
                        _ = try multiDownloadManager.startDownload(url: firmware.url, filename: firmware.filename, replacing: true)
                    } catch {
                        activeAlert = .downloadError(message: error.localizedDescription)
                    }
                default:
                    break
                }
            }
            .onAppear {
                checkIfDownloaded()
            }
            .onChange(of: multiDownloadManager.completedDownloads) {
                checkIfDownloaded()
            }
            .onReceive(NotificationCenter.default.publisher(for: .downloadPathChanged)) { _ in
                checkIfDownloaded()
            }
        }
    }
    
    struct FirmwareIconView: View {
        let firmware: FirmwareProduct
        
        private var iconName: String {
            let majorVersion = Int(firmware.productVersion.components(separatedBy: ".").first ?? "") ?? 0
            switch majorVersion {
            case 27:
                return "Golden Gate"
            case 26:
                return "Tahoe"
            case 15:
                return "Sequoia"
            case 14:
                return "Sonoma"
            case 13:
                return "Ventura"
            case 12:
                return "Monterey"
            case 11:
                return "Big Sur"
            default:
                return "macOS"
            }
        }
        
        private var isBetaBuild: Bool {
            firmware.buildVersion.range(of: "[a-z]$", options: .regularExpression) != nil
        }
        
        var body: some View {
            ZStack(alignment: .center) {
                Image(iconName)
                    .resizable(resizingMode: .stretch)
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(Color.blue)
                
                if isBetaBuild {
                    Text(" beta ")
                        .font(.headline)
                        .foregroundColor(.white)
                        .background(Color.blue.opacity(0.8))
                        .rotationEffect(.degrees(-45))
                }
            }
            .frame(width: 50.0, height: 50.0, alignment: .center)
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
}

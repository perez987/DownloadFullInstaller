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
    @State private var isDownloaded = false

    // Computed property for the installer filename
    var installerFilename: String {
        return "InstallAssistant-\(product.productVersion ?? "V")-\(product.buildVersion ?? "B").pkg"
    }

    // Check if the installer has been downloaded
    // This checks the file system and should only be called after sandbox is initialized
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
        isDownloaded = multiDownloadManager.completedDownloads.contains { $0.filename == installerFilename }
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

                        // Start accessing security-scoped resource for file check (only if needed)
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
                    .help(String(format: NSLocalizedString("Create Installer App from %@ %@ (%@)", comment: ""), product.osName ?? "<no os>", product.productVersion ?? "<no version>", product.buildVersion ?? "<no build>"))
                    .disabled(multiDownloadManager.isDownloading(filename: installerFilename) || isCreatingInstaller)
                    .buttonStyle(.borderless)
                    .controlSize(.mini)

                    // Context menu: copy to clipboard the URL of the specified InstallAssistant.pkg
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
                .onAppear {
                    // Check if downloaded after view appears, ensuring sandbox is fully initialized
                    checkIfDownloaded()
                }
                .onChange(of: multiDownloadManager.completedDownloads) { _ in
                    // Update download status when downloads complete
                    checkIfDownloaded()
                }
            }
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

            DispatchQueue.main.async {
                self.isCreatingInstaller = false

                if let error {
                    self.activeAlert = .installerCreation(
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
    @StateObject var multiDownloadManager = MultiDownloadManager.shared
    @State private var activeAlert: AppAlertType?
    @State private var failed = false

    private var isDownloaded: Bool {
        let destination = Prefs.downloadURL
        let file = destination.appendingPathComponent(firmware.filename)

        if FileManager.default.fileExists(atPath: file.path) {
            return true
        }

        return multiDownloadManager.completedDownloads.contains { $0.filename == firmware.filename }
    }

    var body: some View {
        HStack {
            FirmwareIconView(firmware: firmware)

            VStack(alignment: .leading) {
                HStack {
                    Text("macOS \(firmware.osName)")
                        .font(.headline)
                    Spacer()
                    Text(firmware.productVersion)
                        .frame(alignment: .trailing)
                }
                HStack {
                    Text(firmware.postDate, style: .date)
                        .font(.footnote)
                    Text(Prefs.byteFormatter.string(fromByteCount: Int64(firmware.size)))
                        .font(.footnote)
                    Spacer()
                    Text(firmware.buildVersion)
                        .frame(alignment: .trailing)
                        .font(.footnote)
                }
            }

            if isDownloaded {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                    .help(NSLocalizedString("This firmware has been downloaded", comment: ""))
            }

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
                let fileExists = FileManager.default.fileExists(atPath: file.path)

                if fileExists {
                    activeAlert = .replaceFile(filename: firmware.filename)
                } else {
                    do {
                        _ = try multiDownloadManager.startDownload(url: firmware.url, filename: firmware.filename)
                    } catch {
                        failed = true
                    }
                }
            }) {
                Image(systemName: "arrow.down.circle").font(.title)
            }
            .help(String(format: NSLocalizedString("Download %@ %@ (%@) Firmware", comment: ""), firmware.osName, firmware.productVersion, firmware.buildVersion))
            .disabled(multiDownloadManager.isDownloading(filename: firmware.filename))
            .buttonStyle(.borderless)
            .controlSize(.mini)

            Button(action: {
                if let url = URL(string: "https://support.apple.com/en-us/108900") {
                    NSWorkspace.shared.open(url)
                }
            }) {
                Image(systemName: "questionmark.circle").font(.title)
            }
            .help(NSLocalizedString("Restore with Apple Configurator: How to", comment: ""))
            .buttonStyle(.borderless)
            .controlSize(.mini)
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
        .appAlert(item: $activeAlert) { alertType in
            switch alertType {
            case .replaceFile:
                do {
                    _ = try multiDownloadManager.startDownload(url: firmware.url, filename: firmware.filename, replacing: true)
                } catch {
                    failed = true
                }
            default:
                break
            }
        }
    }
}

struct FirmwareIconView: View {
    let firmware: FirmwareProduct

    private var iconName: String {
        let majorVersion = Int(firmware.productVersion.components(separatedBy: ".").first ?? "") ?? 0
        switch majorVersion {
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

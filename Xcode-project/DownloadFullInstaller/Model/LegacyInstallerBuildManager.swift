import AppKit
import Combine

@MainActor
final class LegacyInstallerBuildManager: ObservableObject {
    static let shared = LegacyInstallerBuildManager()

    @Published private(set) var componentFolder: URL?
    @Published private(set) var status = ""
    @Published var activeAlert: AppAlertType?

    var isBuilding: Bool { componentFolder != nil }

    func isUsing(_ file: URL) -> Bool {
        file.deletingLastPathComponent().standardizedFileURL.path
            == componentFolder?.standardizedFileURL.path
    }

    func createInstaller(for product: Product) async {
        guard !isBuilding else { return }
        let downloads = Prefs.downloadURL
        let access =
            Prefs.downloadURLRequiresSecurityScope
            && downloads.startAccessingSecurityScopedResource()
        defer { if access { downloads.stopAccessingSecurityScopedResource() } }
        let folder = downloads.appendingPathComponent(
            product.componentFolder,
            isDirectory: true
        )
        let sizes = Dictionary(
            uniqueKeysWithValues: product.installerComponents.compactMap {
                package in
                URL(string: package.url).map {
                    ($0.lastPathComponent, package.size)
                }
            }
        )
        componentFolder = folder
        defer {
            componentFolder = nil
            status = ""
        }

        var volumeToEject: URL?
        var result: URL?
        var failure: String?
        var imageOpened = false
        do {
            guard
                !product.installerComponents.contains(where: {
                    MultiDownloadManager.shared.isDownloading(
                        filename:
                            "\(product.componentFolder)/\(URL(string: $0.url)?.lastPathComponent ?? "")"
                    )
                })
            else {
                throw LegacyInstallerBuilder.BuildError.incompleteComponents
            }
            try LegacyInstallerBuilder.validateComponents(
                in: folder,
                expectedSizes: sizes
            )
            guard
                let mountedVolumes = FileManager.default.mountedVolumeURLs(
                    includingResourceValuesForKeys: nil
                )
            else {
                throw CocoaError(.fileReadUnknown)
            }
            let existingVolumes = Set(
                mountedVolumes.map { $0.standardizedFileURL.path }
            )
            status = NSLocalizedString(
                "Opening BaseSystem.dmg...",
                comment: "Installer assembly status"
            )
            let mountedVolume = try await openBaseSystem(
                folder.appendingPathComponent("BaseSystem.dmg")
            )
            imageOpened = true

            if let volume = mountedVolume {
                let values = try volume.resourceValues(forKeys: [
                    .volumeURLKey, .volumeIsReadOnlyKey,
                ])
                guard
                    values.volume?.standardizedFileURL.path
                        == volume.standardizedFileURL.path,
                    values.volumeIsReadOnly == true,
                    volume.deletingLastPathComponent().standardizedFileURL.path
                        == "/Volumes"
                else {
                    throw LegacyInstallerBuilder.BuildError.invalidInstaller
                }
                let sourceApp = try LegacyInstallerBuilder.installerApp(
                    in: volume
                )
                if let release = product.osName,
                    sourceApp.lastPathComponent
                        != "Install macOS \(release).app"
                {
                    throw LegacyInstallerBuilder.BuildError.invalidInstaller
                }
                // Never eject an image that was already mounted before this operation.
                if !existingVolumes.contains(volume.standardizedFileURL.path) {
                    volumeToEject = volume
                }
                status = NSLocalizedString(
                    "Assembling installer app. Copying large files may take several minutes...",
                    comment: "Installer assembly status"
                )
                result = try await Task.detached(priority: .userInitiated) {
                    try LegacyInstallerBuilder.build(
                        from: sourceApp,
                        components: folder,
                        expectedSizes: sizes
                    )
                }.value
            } else {
                throw LegacyInstallerBuilder.BuildError.invalidInstaller
            }
        } catch {
            failure = error.localizedDescription
            print("Legacy installer creation: \(error)")
        }

        var ejectWarning: String?
        if let volumeToEject {
            do {
                try NSWorkspace.shared.unmountAndEjectDevice(at: volumeToEject)
            } catch {
                ejectWarning = String(
                    format: NSLocalizedString(
                        "The installer image could not be ejected. Eject it in Finder. Error: %@",
                        comment: "Disk image cleanup failed"
                    ),
                    error.localizedDescription
                )
                print("Legacy installer image eject: \(error)")
            }
        } else if imageOpened {
            ejectWarning = NSLocalizedString(
                "BaseSystem.dmg may still be mounted. Eject the Base System image in Finder when finished.",
                comment: "Image remains mounted after selection or cancellation"
            )
        }
        if let result {
            NSWorkspace.shared.activateFileViewerSelecting([result])
            let appName = result.lastPathComponent
            let osName = result.deletingPathExtension().lastPathComponent
                .replacingOccurrences(of: "Install ", with: "")
            var message = String(
                format: NSLocalizedString(
                    "The installer app has been created alongside the downloaded %@ components, under the name \"%@\".",
                    comment: "Installer output location: OS name, app file name"
                ),
                osName,
                appName
            )
            message +=
                "\n\n"
                + NSLocalizedString(
                    "This is an Intel installer. Creating the app does not make it compatible with Apple Silicon or unsupported Macs.",
                    comment: "Installer compatibility warning"
                )
            if let ejectWarning { message += "\n\n" + ejectWarning }
            activeAlert = .installerCreation(
                title: NSLocalizedString("Success", comment: ""),
                message: message
            )
        } else if let failure {
            var message = failure
            if let ejectWarning { message += "\n\n" + ejectWarning }
            activeAlert = .installerCreation(
                title: NSLocalizedString(
                    "Error Creating Installer",
                    comment: ""
                ),
                message: message
            )
        }
    }

    // Mounts with -nobrowse so Finder does not open a window, and returns the volume's mount point.
    private func openBaseSystem(_ image: URL) async throws -> URL? {
        try await Task.detached(priority: .userInitiated) {
            let process = Process()
            let output = Pipe()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
            process.arguments = [
                "attach", "-nobrowse", "-readonly", "-noautoopen", "-plist",
                image.path,
            ]
            process.standardOutput = output
            process.standardError = FileHandle.nullDevice
            try process.run()
            let data = output.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else {
                throw CocoaError(.fileReadUnknown)
            }
            let plist =
                try PropertyListSerialization.propertyList(
                    from: data,
                    format: nil
                ) as? [String: Any]
            let entities = plist?["system-entities"] as? [[String: Any]] ?? []
            return entities.compactMap { $0["mount-point"] as? String }
                .first { $0.hasPrefix("/Volumes/") }
                .map { URL(fileURLWithPath: $0, isDirectory: true) }
        }.value
    }
}

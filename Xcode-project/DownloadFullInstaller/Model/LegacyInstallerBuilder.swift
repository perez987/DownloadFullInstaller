import Foundation

enum LegacyInstallerBuilder {
    enum BuildError: LocalizedError {
        case incompleteComponents
        case invalidComponent(String)
        case invalidInstaller
        case invalidInstallInfo
        case destinationExists(String)
        case cleanupFailed(String, String, String)

        var errorDescription: String? {
            switch self {
            case .incompleteComponents:
                NSLocalizedString(
                    "Download all six installer components before creating the app.",
                    comment: "Missing installer inputs"
                )
            case .invalidComponent(let name):
                String(
                    format: NSLocalizedString(
                        "The component %@ is missing, incomplete, or not a regular file. Download it again.",
                        comment: "Invalid installer input"
                    ),
                    name
                )
            case .invalidInstaller:
                NSLocalizedString(
                    "Select the mounted Base System volume containing the Apple installer app for this download.",
                    comment: "Invalid installer source"
                )
            case .invalidInstallInfo:
                NSLocalizedString(
                    "InstallInfo.plist has an unsupported payload format. The installer app was not created.",
                    comment: "Invalid installer metadata"
                )
            case .destinationExists(let path):
                String(
                    format: NSLocalizedString(
                        "An item already exists at %@. Move it or rename it before creating another installer app.",
                        comment: "Do not overwrite an installer"
                    ),
                    path
                )
            case .cleanupFailed(let original, let path, let cleanup):
                String(
                    format: NSLocalizedString(
                        "%@\n\nCould not remove the incomplete build at %@. Remove it in Finder. Error: %@",
                        comment: "Installer cleanup failed"
                    ),
                    original,
                    path,
                    cleanup
                )
            }
        }
    }

    static func validateComponents(in folder: URL, expectedSizes: [String: Int])
        throws
    {
        guard Set(expectedSizes.keys) == Set(LegacyInstallerComponents.names)
        else {
            throw BuildError.incompleteComponents
        }
        try requireDirectory(folder)
        for name in LegacyInstallerComponents.names {
            let file = folder.appendingPathComponent(name)
            guard FileManager.default.fileExists(atPath: file.path) else {
                throw BuildError.invalidComponent(name)
            }
            let values = try file.resourceValues(forKeys: [
                .isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey,
            ])
            guard values.isRegularFile == true, values.isSymbolicLink != true,
                let size = expectedSizes[name], size > 0,
                values.fileSize == size
            else {
                throw BuildError.invalidComponent(name)
            }
        }
    }

    static func installerApp(in volume: URL) throws -> URL {
        let candidates = try FileManager.default.contentsOfDirectory(
            at: volume,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
            options: [.skipsHiddenFiles]
        ).filter { $0.pathExtension.lowercased() == "app" }
        guard candidates.count == 1, let app = candidates.first else {
            throw BuildError.invalidInstaller
        }
        try validateInstaller(app)
        return app
    }

    static func patchedInstallInfo(_ data: Data) throws -> Data {
        guard
            var info = try PropertyListSerialization.propertyList(
                from: data,
                format: nil
            ) as? [String: Any],
            var payload = info["Payload Image Info"] as? [String: Any],
            let url = payload["URL"] as? String,
            let identifier = payload["id"] as? String,
            ["InstallESDDmg.pkg", "InstallESD.dmg"].contains(url),
            ["com.apple.pkg.InstallESDDmg", "com.apple.dmg.InstallESD"]
                .contains(identifier)
        else {
            throw BuildError.invalidInstallInfo
        }
        payload["URL"] = "InstallESD.dmg"
        payload["id"] = "com.apple.dmg.InstallESD"
        payload.removeValue(forKey: "chunklistURL")
        payload.removeValue(forKey: "chunklistid")
        info["Payload Image Info"] = payload
        return try PropertyListSerialization.data(
            fromPropertyList: info,
            format: .xml,
            options: 0
        )
    }

    static func build(
        from sourceApp: URL,
        components folder: URL,
        expectedSizes: [String: Int]
    ) throws -> URL {
        let files = FileManager.default
        try validateComponents(in: folder, expectedSizes: expectedSizes)
        try validateInstaller(sourceApp)
        let patchedInfo = try patchedInstallInfo(
            Data(contentsOf: folder.appendingPathComponent("InstallInfo.plist"))
        )
        let destination = folder.appendingPathComponent(
            sourceApp.lastPathComponent,
            isDirectory: true
        )
        guard try !itemExists(destination) else {
            throw BuildError.destinationExists(destination.path)
        }

        // Publish only a complete bundle, on the same volume; never modify the downloads or an existing app.
        let staging = folder.appendingPathComponent(
            ".installer-build-\(UUID().uuidString)",
            isDirectory: true
        )
        try files.createDirectory(
            at: staging,
            withIntermediateDirectories: false
        )
        do {
            let app = staging.appendingPathComponent(
                sourceApp.lastPathComponent,
                isDirectory: true
            )
            try files.copyItem(at: sourceApp, to: app)
            try validateInstaller(app)
            let support = app.appendingPathComponent(
                "Contents/SharedSupport",
                isDirectory: true
            )
            if try itemExists(support),
                try support.resourceValues(forKeys: [.isSymbolicLinkKey])
                    .isSymbolicLink == true
            {
                try files.removeItem(at: support)
            }
            if try !itemExists(support) {
                try files.createDirectory(
                    at: support,
                    withIntermediateDirectories: false
                )
            }
            try requireDirectory(support)

            for name in LegacyInstallerComponents.names {
                let target = support.appendingPathComponent(
                    supportName(for: name)
                )
                if try itemExists(target) { try files.removeItem(at: target) }
                if name == "InstallInfo.plist" {
                    try patchedInfo.write(to: target, options: .atomic)
                } else {
                    try files.copyItem(
                        at: folder.appendingPathComponent(name),
                        to: target
                    )
                }
            }
            try validateOutput(app, expectedSizes: expectedSizes)
            removeQuarantine(from: app)
            try files.moveItem(at: app, to: destination)
        } catch {
            do {
                try files.removeItem(at: staging)
            } catch let cleanupError {
                throw BuildError.cleanupFailed(
                    error.localizedDescription,
                    staging.path,
                    cleanupError.localizedDescription
                )
            }
            throw error
        }
        do {
            try files.removeItem(at: staging)
        } catch {
            throw BuildError.cleanupFailed(
                String(
                    format: NSLocalizedString(
                        "The installer app was created at %@.",
                        comment: "Installer output location"
                    ),
                    destination.path
                ),
                staging.path,
                error.localizedDescription
            )
        }
        return destination
    }

    // Downloaded/copied files may carry quarantine; the assembled installer is a local build, so clear the flag.
    // Symlinks are skipped on purpose: the attribute of the link itself is cleared with XATTR_NOFOLLOW only.
    private static func removeQuarantine(from root: URL) {
        clearQuarantine(at: root)
        guard let enumerator = FileManager.default.enumerator(atPath: root.path)
        else { return }
        for case let relative as String in enumerator {
            clearQuarantine(at: root.appendingPathComponent(relative))
        }
    }

    private static func clearQuarantine(at url: URL) {
        let name = "com.apple.quarantine"
        if getxattr(url.path, name, nil, 0, 0, XATTR_NOFOLLOW) < 0 { return }
        if removexattr(url.path, name, XATTR_NOFOLLOW) == 0 { return }
        // Fallback: the Foundation API also clears the whole quarantine record.
        var target = url
        var values = URLResourceValues()
        values.quarantineProperties = nil
        try? target.setResourceValues(values)
        if getxattr(url.path, name, nil, 0, 0, XATTR_NOFOLLOW) >= 0 {
            // Still tagged (e.g. removal denied); build must not fail because of it.
            NSLog("Could not remove quarantine from %@", url.path)
        }
    }

    static func validateOutput(_ app: URL, expectedSizes: [String: Int]) throws
    {
        try validateInstaller(app)
        let support = app.appendingPathComponent(
            "Contents/SharedSupport",
            isDirectory: true
        )
        try requireDirectory(support)
        for name in LegacyInstallerComponents.names {
            let target = support.appendingPathComponent(supportName(for: name))
            let values = try target.resourceValues(forKeys: [
                .isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey,
            ])
            guard values.isRegularFile == true, values.isSymbolicLink != true,
                name == "InstallInfo.plist"
                    || values.fileSize == expectedSizes[name]
            else {
                throw BuildError.invalidComponent(name)
            }
        }
        let data = try Data(
            contentsOf: support.appendingPathComponent("InstallInfo.plist")
        )
        guard
            let info = try PropertyListSerialization.propertyList(
                from: data,
                format: nil
            ) as? [String: Any],
            let payload = info["Payload Image Info"] as? [String: Any],
            payload["URL"] as? String == "InstallESD.dmg",
            payload["id"] as? String == "com.apple.dmg.InstallESD",
            payload["chunklistURL"] == nil, payload["chunklistid"] == nil
        else {
            throw BuildError.invalidInstallInfo
        }
    }

    private static func supportName(for name: String) -> String {
        name == "InstallESDDmg.pkg" ? "InstallESD.dmg" : name
    }

    private static func validateInstaller(_ app: URL) throws {
        guard app.pathExtension.lowercased() == "app" else {
            throw BuildError.invalidInstaller
        }
        try requireDirectory(app)
        try requireDirectory(app.appendingPathComponent("Contents"))
        try requireDirectory(app.appendingPathComponent("Contents/MacOS"))
        let infoURL = app.appendingPathComponent("Contents/Info.plist")
        let values = try infoURL.resourceValues(forKeys: [
            .isRegularFileKey, .isSymbolicLinkKey,
        ])
        guard values.isRegularFile == true, values.isSymbolicLink != true,
            let info = try PropertyListSerialization.propertyList(
                from: Data(contentsOf: infoURL),
                format: nil
            ) as? [String: Any],
            let identifier = info["CFBundleIdentifier"] as? String,
            identifier == "com.apple.InstallAssistant"
                || identifier.hasPrefix("com.apple.InstallAssistant."),
            let executable = info["CFBundleExecutable"] as? String,
            !executable.isEmpty, !executable.contains("/"), executable != ".",
            executable != ".."
        else {
            throw BuildError.invalidInstaller
        }
        let executableURL = app.appendingPathComponent(
            "Contents/MacOS/\(executable)"
        )
        let executableValues = try executableURL.resourceValues(forKeys: [
            .isRegularFileKey, .isSymbolicLinkKey,
        ])
        let executableAttributes = try FileManager.default.attributesOfItem(
            atPath: executableURL.path
        )
        // Sandbox execution policy is irrelevant when copying a readable installer bundle.
        guard executableValues.isRegularFile == true,
            executableValues.isSymbolicLink != true,
            let permissions = executableAttributes[.posixPermissions]
                as? NSNumber,
            permissions.intValue & 0o111 != 0
        else {
            throw BuildError.invalidInstaller
        }
    }

    private static func requireDirectory(_ url: URL) throws {
        let values = try url.resourceValues(forKeys: [
            .isDirectoryKey, .isSymbolicLinkKey,
        ])
        guard values.isDirectory == true, values.isSymbolicLink != true else {
            throw BuildError.invalidInstaller
        }
    }

    private static func itemExists(_ url: URL) throws -> Bool {
        // fileExists follows links and misses dangling links, which must also prevent replacement.
        do {
            _ = try FileManager.default.attributesOfItem(atPath: url.path)
            return true
        } catch let error as CocoaError
            where error.code == .fileNoSuchFile
            || error.code == .fileReadNoSuchFile
        {
            return false
        }
    }
}

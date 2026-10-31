import Foundation

@main
struct LegacyInstallerBuilderChecks {
    static func require(_ condition: Bool, _ message: String) {
        precondition(condition, message)
    }

    static func expectFailure(_ message: String, _ operation: () throws -> Void) {
        do {
            try operation()
            preconditionFailure(message)
        } catch {
            print("Expected rejection: \(error.localizedDescription)")
        }
    }

    static func plist(_ value: [String: Any], format: PropertyListSerialization.PropertyListFormat = .xml) throws -> Data {
        try PropertyListSerialization.data(fromPropertyList: value, format: format, options: 0)
    }

    static func main() throws {
        let files = FileManager.default
        let root = files.temporaryDirectory.appendingPathComponent("LegacyInstallerBuilderChecks-\(UUID().uuidString)")
        try files.createDirectory(at: root, withIntermediateDirectories: false)
        defer {
            do { try files.removeItem(at: root) }
            catch { preconditionFailure("Fixture cleanup failed: \(error)") }
        }
        let components = root.appendingPathComponent("components with spaces")
        let volume = root.appendingPathComponent("Base System")
        let source = volume.appendingPathComponent("Install macOS High Sierra.app")
        try files.createDirectory(at: components, withIntermediateDirectories: false)
        try files.createDirectory(at: source.appendingPathComponent("Contents/MacOS"), withIntermediateDirectories: true)
        try plist([
            "CFBundleIdentifier": "com.apple.InstallAssistant.HighSierra",
            "CFBundleExecutable": "InstallAssistant_springboard",
        ]).write(to: source.appendingPathComponent("Contents/Info.plist"))
        let executable = source.appendingPathComponent("Contents/MacOS/InstallAssistant_springboard")
        try Data("fixture executable".utf8).write(to: executable)
        try files.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)
        let payload: [String: Any] = [
            "Payload Image Info": [
                "URL": "InstallESDDmg.pkg", "id": "com.apple.pkg.InstallESDDmg",
                "chunklistURL": "old.chunklist", "chunklistid": "old.id", "version": "10.13.6",
            ],
            "System Image Info": ["URL": "BaseSystem.dmg", "chunklistURL": "BaseSystem.chunklist"],
            "Other": "preserve me",
        ]
        var sizes: [String: Int] = [:]
        var originals: [String: Data] = [:]
        for name in LegacyInstallerComponents.names {
            let data = name == "InstallInfo.plist" ? try plist(payload, format: .binary) : Data("fixture: \(name)".utf8)
            try data.write(to: components.appendingPathComponent(name))
            sizes[name] = data.count
            originals[name] = data
        }
        require(try LegacyInstallerBuilder.installerApp(in: volume).path == source.path, "Installer discovery failed")
        for permissions in [0o744, 0o654, 0o645] {
            try files.setAttributes([.posixPermissions: permissions], ofItemAtPath: executable.path)
            require(try LegacyInstallerBuilder.installerApp(in: volume).path == source.path,
                    "Executable mode bits rejected")
        }
        try files.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)
        let patched = try LegacyInstallerBuilder.patchedInstallInfo(originals["InstallInfo.plist"]!)
        let info = try PropertyListSerialization.propertyList(from: patched, format: nil) as! [String: Any]
        let image = info["Payload Image Info"] as! [String: Any]
        require(image["URL"] as? String == "InstallESD.dmg", "Payload URL not patched")
        require(image["id"] as? String == "com.apple.dmg.InstallESD", "Payload identifier not patched")
        require(image["chunklistURL"] == nil && image["chunklistid"] == nil, "Obsolete chunklist references remain")
        require(image["version"] as? String == "10.13.6" && info["Other"] as? String == "preserve me", "Unrelated metadata changed")
        require((info["System Image Info"] as! [String: Any])["chunklistURL"] as? String == "BaseSystem.chunklist", "Base System chunklist changed")
        require(try LegacyInstallerBuilder.patchedInstallInfo(patched) == patched, "Patch is not idempotent")
        expectFailure("Missing metadata accepted") {
            _ = try LegacyInstallerBuilder.patchedInstallInfo(plist(["Other": "value"]))
        }
        expectFailure("Remote payload accepted") {
            _ = try LegacyInstallerBuilder.patchedInstallInfo(plist([
                "Payload Image Info": ["URL": "https://example.invalid/InstallESDDmg.pkg", "id": "com.apple.pkg.InstallESDDmg"],
            ]))
        }

        // A source SharedSupport link must be replaced locally, never written through.
        let outside = root.appendingPathComponent("outside")
        try files.createDirectory(at: outside, withIntermediateDirectories: false)
        try Data("untouched".utf8).write(to: outside.appendingPathComponent("sentinel"))
        try files.createSymbolicLink(at: source.appendingPathComponent("Contents/SharedSupport"), withDestinationURL: outside)
        let output = try LegacyInstallerBuilder.build(from: source, components: components, expectedSizes: sizes)
        require(output.path == components.appendingPathComponent(source.lastPathComponent).path, "Unexpected output location")
        try LegacyInstallerBuilder.validateOutput(output, expectedSizes: sizes)
        let outputExecutable = output.appendingPathComponent("Contents/MacOS/InstallAssistant_springboard")
        require(try files.attributesOfItem(atPath: outputExecutable.path)[.posixPermissions] as? Int == 0o755,
                "Executable permissions changed")
        require(try Data(contentsOf: outside.appendingPathComponent("sentinel")) == Data("untouched".utf8), "Source link target changed")
        require(try files.contentsOfDirectory(atPath: outside.path) == ["sentinel"], "Files copied through source link")
        let support = output.appendingPathComponent("Contents/SharedSupport")
        require(!files.fileExists(atPath: support.appendingPathComponent("InstallESDDmg.pkg").path), "Package was not renamed")
        for name in LegacyInstallerComponents.names {
            require(try Data(contentsOf: components.appendingPathComponent(name)) == originals[name], "Downloaded component changed")
            if name != "InstallInfo.plist" {
                let targetName = name == "InstallESDDmg.pkg" ? "InstallESD.dmg" : name
                require(try Data(contentsOf: support.appendingPathComponent(targetName)) == originals[name], "Component bytes changed")
            }
        }
        expectFailure("Existing app overwritten") {
            _ = try LegacyInstallerBuilder.build(from: source, components: components, expectedSizes: sizes)
        }
        try LegacyInstallerBuilder.validateOutput(output, expectedSizes: sizes)
        try files.removeItem(at: output)
        try files.createSymbolicLink(atPath: output.path, withDestinationPath: root.appendingPathComponent("missing").path)
        expectFailure("Dangling destination link replaced") {
            _ = try LegacyInstallerBuilder.build(from: source, components: components, expectedSizes: sizes)
        }
        try files.removeItem(at: output)
        var wrongSizes = sizes
        wrongSizes["BaseSystem.dmg"]! += 1
        expectFailure("Truncated input accepted") {
            _ = try LegacyInstallerBuilder.build(from: source, components: components, expectedSizes: wrongSizes)
        }
        expectFailure("Incomplete catalog accepted") {
            try LegacyInstallerBuilder.validateComponents(in: components, expectedSizes: [:])
        }
        let base = components.appendingPathComponent("BaseSystem.dmg")
        try files.removeItem(at: base)
        expectFailure("Missing file accepted") {
            try LegacyInstallerBuilder.validateComponents(in: components, expectedSizes: sizes)
        }
        let externalBase = root.appendingPathComponent("external-base")
        try originals["BaseSystem.dmg"]!.write(to: externalBase)
        try files.createSymbolicLink(at: base, withDestinationURL: externalBase)
        expectFailure("Input symlink accepted") {
            try LegacyInstallerBuilder.validateComponents(in: components, expectedSizes: sizes)
        }
        try files.removeItem(at: base)
        try originals["BaseSystem.dmg"]!.write(to: base)

        // Trigger failure after staging is created and verify no partial app is published.
        try files.removeItem(at: source.appendingPathComponent("Contents/SharedSupport"))
        try Data("not a directory".utf8).write(to: source.appendingPathComponent("Contents/SharedSupport"))
        expectFailure("Invalid SharedSupport accepted") {
            _ = try LegacyInstallerBuilder.build(from: source, components: components, expectedSizes: sizes)
        }
        require(!files.fileExists(atPath: output.path), "Partial app published")
        require(try files.contentsOfDirectory(atPath: components.path).allSatisfy { !$0.hasPrefix(".installer-build-") }, "Staging folder leaked")
        try files.setAttributes([.posixPermissions: 0o644], ofItemAtPath: executable.path)
        expectFailure("Non-executable source accepted") {
            _ = try LegacyInstallerBuilder.installerApp(in: volume)
        }
        print("Legacy installer builder fixture checks passed")
    }
}

import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

@main
struct LegacyInstallerChecks {
    static func require(_ condition: @autoclosure () -> Bool, _ message: String) {
        precondition(condition(), message)
    }

    static func main() throws {
        require(MetaInfo(installAssistantPackageIdentifiers: ["OSInstall": "com.apple.mpkg.OSInstall"]).isInstaller,
                "Legacy installer marker rejected")
        require(MetaInfo(installAssistantPackageIdentifiers: ["SharedSupport": "com.apple.pkg.InstallAssistant.macOSBigSur"]).isInstaller,
                "Modern installer marker rejected")
        require(!MetaInfo(installAssistantPackageIdentifiers: ["OSInstall": "unrelated.update"]).isInstaller,
                "Unrelated update accepted")
        require(!MetaInfo(installAssistantPackageIdentifiers: ["SharedSupport": "unrelated.package"]).isInstaller,
                "Unrelated shared support accepted")
        require(!MetaInfo(installAssistantPackageIdentifiers: nil).isInstaller, "Missing metadata accepted")
        require(LegacyInstallerComponents.names.count == 6, "Unexpected legacy component list")

        for (buildKey, versionKey, build, version, releaseName) in [
            ("BUILD", "VERSION", "17G66", "10.13.6", "High Sierra"),
            ("macOSProductBuildVersion", "macOSProductVersion", "18G103", "10.14.6", "Mojave"),
            ("BUILD", "VERSION", "19H2026", "10.15.7", "Catalina"),
            ("BUILD", "VERSION", "24G90", "15.6", "Sequoia"),
        ] {
            for title in ["Install macOS", "SU_TITLE"] {
                let xml = """
                <?xml version="1.0"?>
                <installer-gui-script><title>\(title)</title>
                <auxinfo><dict><key>\(buildKey)</key><string>\(build)</string>
                <key>\(versionKey)</key><string>\(version)</string></dict></auxinfo>
                </installer-gui-script>
                """
                let parser = XMLParser(data: Data(xml.utf8))
                let delegate = DistParserDelegate()
                parser.delegate = delegate
                require(parser.parse(), "Distribution XML did not parse")
                require(delegate.buildVersion == build && delegate.productVersion == version, "Distribution metadata mismatch")
                let expectedTitle = title == "SU_TITLE" ? releaseName : title
                require(delegate.title == expectedTitle, "Distribution title mismatch for \(build)")
            }
        }
        require(nameOS["17"] == "High Sierra" && nameOS["18"] == "Mojave", "Legacy release mapping missing")
        print("Legacy installer fixture checks passed")
    }
}

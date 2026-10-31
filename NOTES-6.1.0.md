# Release notes

## Unreleased

- Discover catalog-based multipart Intel installers for High Sierra, Mojave, and Catalina when Apple's `OSInstall` catalog metadata provides them.
- Download the six required components into separate product folders using the shared download queue. Do not treat an ESD component as a standalone InstallAssistant package.
- Add in-app multipart installer assembly: open `BaseSystem.dmg` with macOS's DiskImageMounter, authorize its mounted volume, copy the installer app and six components, and patch `InstallInfo.plist`. Publish only a complete bundle in the component folder without overwriting existing apps.
- Validate installer executable permission bits instead of sandbox execution access, avoiding rejection of a readable mounted Base System installer during assembly.
- Present each multipart installer as one compact card with a single Download and Create Installer App button, and show its six components as one aggregated download (total progress, one Cancel/Show in Finder entry) in the Downloads panel. Components are queued within the 3-download limit.
- Parse both legacy and modern distribution version/build keys and identify releases from their build numbers
- Show only the newest available multipart installer for each of High Sierra, Mojave, and Catalina in the detail panel, without changing the catalog or download behavior.

Availability depends on Apple's catalogs.
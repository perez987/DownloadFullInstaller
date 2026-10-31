# Download legacy macOS

## Direct link to DMG (Sierra, El Capitan, Yosemite, Mpuntain Lion, Lion)

There are be users interested in obtaining legacy versions of macOS, prior to Big Sur. The most significant challenge is finding direct links to legacy versions of macOS that can be integrated into Download Full Installer without requiring extensive code modifications.

There is a support article by Apple on "[How to download and install macOS](https://support.apple.com/en-us/102662)” with a section called "Use a web browser for older versions" that contains direct download links for macOS Lion to Sierra:

- [macOS Sierra 10.12](http://updates-http.cdn-apple.com/2019/cert/061-39476-20191023-48f365f4-0015-4c41-9f44-39d3d2aca067/InstallOS.dmg) 
- [OS X El Capitan 10.11](http://updates-http.cdn-apple.com/2019/cert/061-41424-20191024-218af9ec-cf50-4516-9011-228c78eda3d2/InstallMacOSX.dmg) 
- [OS X Yosemite 10.10](http://updates-http.cdn-apple.com/2019/cert/061-41343-20191023-02465f92-3ab5-4c92-bfe2-b725447a070d/InstallMacOSX.dmg) 
- [Mac OS X Mountain Lion 10.8](https://updates.cdn-apple.com/2021/macos/031-0627-20210614-90D11F33-1A65-42DD-BBEA-E1D9F43A6B3F/InstallMacOSX.dmg) 
- [Mac OS X Lion 10.7](https://updates.cdn-apple.com/2021/macos/041-7683-20210614-E610947E-C7CE-46EB-8860-D26D71F0D3EA/InstallMacOSX.dmg)

These legacy systems use a different method than Big Sur and later systems. While the latter download a PKG installer, differentiate between versions, that can easily be converted into the Install macOS app, the legacy systems have a single link to the latest available version of each system and download a DMG disk image containing the PKG installer.

The disk images can use the same download queue as modern installers, but creating an installer app requires opening the downloaded image in Finder and running the package inside it.

### Implementation

Starting with version 6.0.0, the five legacy macOS versions appear at the end of the main window's left-hand installer list. Select a release to display its download card and disk-image instructions in the right-hand pane. A separate legacy window is no longer needed.

Legacy downloads are managed similarly to modern downloads:

- They can be canceled before completion
- They share the same queue and three-download limit as installers and firmware
- Progress remains visible when switching releases or content types
- Completed images can be revealed in Finder
- The download destination folder is the one configured in the app settings
- The selected software update catalog does not affect these fixed Apple download links.

## Catalog-based installers: High Sierra,  Mojave and Catalina

The five fixed disk-image links above remain independent of the catalog. Additional pre-Big Sur installers are discovered dynamically in Apple's software update catalogs, using the `OSInstall = com.apple.mpkg.OSInstall` metadata marker. The previous catalog filter only recognized the newer `SharedSupport` marker.

High Sierra and Mojave can therefore appear under **Available Releases** rather than the fixed-link legacy section. Catalina can also be discovered if Apple publishes a matching entry; no particular release or build is guaranteed. Try the **Regular** catalog if a seed catalog does not contain older installers. No App Store links or third-party installer mirrors are used.

Unlike a modern `InstallAssistant.pkg`, `InstallESDDmg.pkg` is **not a standalone installer**. Opening it in Installer produces the "requires additional components" error, even if all catalog packages are beside it. Merely putting files in the same folder does not assemble an installer application.

The multipart card offers the six inputs needed for in-app assembly, the same inputs used by gibMacOS's `BuildmacOSInstallApp.py`:

| File | Purpose |
| --- | --- |
| `BaseSystem.dmg` | Base system image containing the installer application |
| `BaseSystem.chunklist` | Base system chunk metadata |
| `InstallESDDmg.pkg` | Main installation image; the builder copies it as `InstallESD.dmg`, rather than running it |
| `InstallInfo.plist` | Image references used by the installer |
| `AppleDiagnostics.dmg` | Diagnostics image |
| `AppleDiagnostics.chunklist` | Diagnostics chunk metadata |

### Download and create the app

1. Select a catalog-based legacy release, then download **all six components** using their individual buttons. They share the existing three-transfer limit, cancellation, retry, replacement confirmation, and Finder actions. Start the remaining files as slots become available.
2. Wait for all six green checkmarks. Files retain their original names under `macOS-<catalog-product-ID>` inside the configured download folder, preventing collisions between releases/builds.
3. Choose **Create Installer App**. macOS's DiskImageMounter opens the downloaded `BaseSystem.dmg`. Wait for any macOS image verification or prompts to finish.
4. In Download Full Installer's folder picker, select the **mounted Base System volume itself** under Locations (usually `macOS Base System`), not the installer app inside it. Select the image from this exact download, not another release/build's mounted image. This grants sandbox access to its contents. If mounting fails or no volume appears, cancel; the app cannot proceed without a readable mounted image.
5. Keep the app open while it copies the installer application and the six components. Progress remains visible when switching releases. Creation blocks replacement downloads for those inputs and normal app termination; copying a multi-gigabyte component may take several minutes.
6. Finder reveals `Install macOS <release>.app` **inside that component folder**, not in `/Applications`. An existing item with the same name is never replaced: move or rename it before trying again. Keep the original downloads until the result has been checked.

No Python, Terminal command, administrator password, or external builder is required. DiskImageMounter is part of macOS. The sandbox is disabled so assembly also works in a custom download folder. Input access is retained throughout the operation, including if the configured folder changes.

The app uses Launch Services (`NSWorkspace`) to open the image rather than launching `hdiutil attach`. The folder picker is a deliberate authorization step, not an automatic mount detector: successful launch of DiskImageMounter does not prove the image mounted. After assembly or a copy failure, the app asks `NSWorkspace` to eject the selected volume if it was not already mounted before this operation. Eject errors are reported without discarding a completed installer. If selection is canceled, invalid, or the image was already mounted, eject the Base System image yourself in Finder; the app does not force-unmount or guess which other volumes to eject.

`LegacyInstallerBuilder.swift` is an independent Swift implementation of the assembly format described by the upstream builder. It checks all six catalog sizes, regular files, the Apple installer bundle and executable, and the payload metadata. It builds in a unique hidden staging directory on the destination volume, copies `InstallESDDmg.pkg` as `InstallESD.dmg`, changes the payload URL/id, removes only the payload's obsolete chunklist references, and checks the output before moving the complete app into place. It preserves other plist fields, source files, bundle executable permissions, and bundle contents. A `SharedSupport` symbolic link in the source bundle is replaced with a real local directory so files are not written through the link. Failures remove the staging folder, with explicit errors if cleanup fails.

Executable validation reads the binary's POSIX permission bits. Assembly only copies the installer.

### Why gibMacOS downloads eleven files

In its normal installer-download mode, gibMacOS downloads every package listed for the catalog product. For the High Sierra product reported here, the five additional files are `InstallAssistantAuto.pkg`, `InstallESDDmg.chunklist`, `MajorOSInfo.pkg`, `OSInstall.mpkg`, and `RecoveryHDMetaDmg.pkg`. Its separate app builder does not use those five files. Downloading them therefore does not make `InstallESDDmg.pkg` independently installable, and they are not needed for that builder's six-file workflow.

The [upstream builder source](https://github.com/corpnewt/gibMacOS/blob/bf8f2abdadd56694519f1f04ff9c4b0cd89c6063/BuildmacOSInstallApp.py) defines the same six required filenames as this app. It mounts `BaseSystem.dmg`, copies the installer application from that image, and populates its `Contents/SharedSupport` directory with the six components. In that copy, it renames `InstallESDDmg.pkg` to `InstallESD.dmg` and updates `InstallInfo.plist`'s payload URL and identifier, removing the old payload chunklist references. Simply opening the PKG, or renaming it alone, does not perform these assembly steps.

These are **Intel** installers. Downloading them on macOS 15+ does not make them compatible with Apple Silicon or permit installation on unsupported hardware. No Mavericks download has been added.

### Validation on macOS

Build the application with Xcode 26, then check High Sierra and Mojave in the Regular catalog if available, plus Catalina when published. Exercise all six downloads, the three-download limit, cancel/retry, replacement, switching releases, and a custom download folder.

Verify creation stays disabled until all six files are complete. Use **Create Installer App**, approve the mounted volume in the picker, and check the resulting bundle has the six `Contents/SharedSupport` files (`InstallESD.dmg` instead of `InstallESDDmg.pkg`). Check `InstallInfo.plist` has payload URL `InstallESD.dmg`, id `com.apple.dmg.InstallESD`, no payload chunklist keys, and unchanged Base System/diagnostics metadata. Compare copied component hashes with the downloads and confirm executable permissions and bundle resources survive copying.

Repeat with spaces in the custom folder path, with the image already mounted, and while changing the download folder or selected release. Test canceling the picker, a failed mount, selecting a wrong volume/release, missing/truncated files, an existing output app, insufficient destination space, and eject failure. Failures must be visible and must not publish a partial app or overwrite an existing app. Confirm the image is ejected when appropriate, and that cancellation tells the user to eject it manually. Check installer/bootable-media use separately on compatible Intel hardware; assembly is not proof of host compatibility. Also check a modern Big Sur-or-newer PKG and the five fixed legacy DMGs, whose flows are unchanged.

The standalone fixture checks in `Xcode-project/Checks/LegacyInstallerChecks.swift` exercise the catalog metadata and distribution parsing logic without downloading multi-gigabyte installers:

```sh
swiftc -swift-version 6 \
  Xcode-project/DownloadFullInstaller/Model/LegacyInstallerComponents.swift \
  Xcode-project/DownloadFullInstaller/Model/DistParserDelegate.swift \
  Xcode-project/DownloadFullInstaller/Model/MetaInfo.swift \
  Xcode-project/DownloadFullInstaller/Model/OSNames.swift \
  Xcode-project/Checks/LegacyInstallerChecks.swift \
  -o /tmp/LegacyInstallerChecks && /tmp/LegacyInstallerChecks
```

The independent assembly fixture checks cover plist patching (including binary input), metadata preservation, exact component copies, executable permissions, missing/truncated inputs, unsafe symlinks, existing destinations, and staging cleanup. They do not mount images or prove sandbox or installer compatibility:

```sh
swiftc -swift-version 6 \
  Xcode-project/DownloadFullInstaller/Model/LegacyInstallerComponents.swift \
  Xcode-project/DownloadFullInstaller/Model/LegacyInstallerBuilder.swift \
  Xcode-project/Checks/LegacyInstallerBuilderChecks.swift \
  -o /tmp/LegacyInstallerBuilderChecks && /tmp/LegacyInstallerBuilderChecks
```

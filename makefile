FetchInstallerPkg:
	@echo "Building DownloadFullInstaller..."
	@$/xcodebuild -project "Download-Full-Installer.xcodeproj" -alltargets -configuration Release
	@$/Open ./build/Release

.PHONY: DownloadFullInstaller clean

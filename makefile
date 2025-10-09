FetchInstallerPkg:
	@echo "Building DownloadFullInstaller..."
	@$/xcodebuild -project "DownloadFullInstaller.xcodeproj" -alltargets -configuration Release
	@$/Open ./build/Release


.PHONY: FetchInstallerPkg clean

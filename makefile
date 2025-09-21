FetchInstallerPkg:
	@echo "Building OpenCore Creator..."
	@$/xcodebuild -project "FetchInstallerPkg.xcodeproj" -alltargets -configuration Release
	@$/Open ./build/Release


.PHONY: FetchInstallerPkg clean


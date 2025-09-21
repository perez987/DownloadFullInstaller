FetchInstallerPkg:
	@echo "Building FetchInstallerPkg..."
	@$/xcodebuild -project "FetchInstallerPkg.xcodeproj" -alltargets -configuration Release
	@$/Open ./build/Release


.PHONY: FetchInstallerPkg clean


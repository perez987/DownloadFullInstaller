## 1.9 (92)

### App for macOS 11+

- Platform:

	- Standard architecture `x86_64` + `arm64`.
	- DownloadFullInstaller.app runs on macOS 11 Big Sur or newer.
	- Xcode requires macOS 11 Big Sur or newer.

- Add constants and URL catalog for Tahoe.

- Add Tahoe icons.

- Add sleep prevention logic:
	- Installation packages are quite large (up to 17 GB on Tahoe); computer may go to sleep before completing the download.
	- Add logic to disable sleep while the app window is open.
	- Sleep resumes when the app window is closed.

- Update copyright info.

- Add localization (English, Spanish, French).

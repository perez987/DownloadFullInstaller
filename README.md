# Download Full Installer 2

![Platform](https://img.shields.io/badge/macOS-11+-orange.svg)
![Xcode](https://img.shields.io/badge/Xcode-macOS13+-lavender.svg)
![Downloads](https://img.shields.io/github/downloads/perez987/DownloadFullInstaller-2/total?label=Downloads&color=00cd00)


<img src="Images/DownloadFullInstaller-bigsur.png" width="624px">

## Download Full Installer from macOS 11 up to 26 

This branch of DownloadFullInstaller runs on macOS 11 Big Sur up to macOS 26 Tahoe.

### Build 1.8 (81)

- Platform:

	- x86_64.
	- DownloadFullInstaller.app runs on macOS 11 Big Sur or newer.
	- Xcode requires macOS Ventura or newer.

- Add constants and URL catalog for Tahoe.

- Add Tahoe icons.

- Add sleep prevention logic:
	- Installation packages are quite large (up to 17 GB on Tahoe); computer may go to sleep before completing the download.
	- Add logic to disable sleep while the app window is open.
	- Sleep resumes when the app window is closed.

- Update copyright info.

- Add localization (English, Spanish, French).

## Original repository

### Preface

This is a Swift UI implementation of my [fetch-installer-pkg](https://github.com/scriptingosx/fetch-installer-pkg) script. It will list the full macOS Big Sur (and later) installer pkgs available for download in Apple's software update catalogs. You can then choose to download one of them.

### Motivation

You may want to download the installer pkg instead of the installer application directly, because you want to re-deploy the installer application with a management system, such as Jamf. 

Since the Big Sur macOS installer application contains a single file larger than 8GB, normal packaging tools will fail. I have described the problem and some solutions in detail in [this blog post](https://scriptingosx.com/2020/11/deploying-the-big-sur-installer-application/).

### Extras

- Copy the download URL for a given installer pkg from the context menu.
- Change the seed program in the Preferences dropdown menu.
- Create the installer without leaving the application.

### Questions

#### Can this download older versions of the macOS installer application?

No. Apple only provides installer PKGs for Big Sur and later. Earlier versions of the Big Sur installer are removed regularly.

#### Will you update this so it can download older versions?

No.

#### How is this different from other command tools?

As far as I can tell, this downloads the same pkg as `softwareupdate --fetch-full-installer` and `installinstallmacOS.py`.

The difference is that the other tools then immediately perform the installation so that you get the installer application in the `/Applications` folder. This tool just downloads the pkg, so you can use it in your management system, archive the installer pkg, or manually run the installation.

<!-- Commented as obsolete
#### Skip sleep while downloading the installer

> **Note**: In August 2025, this has been superseded by Swift code integrated into the app.

Download Full Installer does not prevent the system from going to sleep while an installer is being downloaded. You can prevent this with the `caffeinate` command:

- open Terminal
- type `top | grep "Download"`
- stop `top` with Ctrl + C
- the output shows at the beginning of each line the PID of Download Full Installer
- type `caffeinate -w PID`(where PID is a number)
- sleep is blocked until Download Full Installer is closed.

``` bash
/Users/yo > top | grep "Download"
2233  Download Full In (more text...)
#stop with Ctrl + C
/Users/yo > caffeinate -w 2233
```
-->

### Credits

- Both [fetch-installer-pkg](https://github.com/scriptingosx/fetch-installer-pkg) and this application are based on [Greg Neagle's installinstallmacos.py](https://github.com/munki/macadmin-scripts/blob/main/installinstallmacos.py) script.

# Create Installer App Feature

## Overview

This feature adds a new button to the Download Full Installer application that allows users to create the macOS installer application (e.g., "Install macOS Sequoia.app") directly from the downloaded InstallAssistant.pkg file.

## User Interface Changes

### New Button

- **Location**: Next to the existing "Download Installer PKG" button in each installer row
- **Icon**: `square.and.arrow.down.on.square` (SF Symbol)
- **Tooltip**: "Create Installer App"
- **Visual States**:
  - Normal: Shows the icon
  - Processing: Shows a spinning progress indicator
  - Disabled: When downloading or creating an installer

## Functionality

### What It Does

When the user clicks the "Create Installer App" button:

1. **Validation**: Checks if the InstallAssistant.pkg exists in the Downloads folder
   - If not found, shows an error alert prompting to download it first

2. **Privilege Escalation**: Uses AppleScript to request administrator privileges
   - A system authentication dialog appears asking for the admin password

3. **Installation**: Runs the command:
   ```bash
   installer -pkg '<path-to-pkg>' -target /
   ```

4. **Result**: The installer application (e.g., "Install macOS Sequoia.app") is created in /Applications

### User Feedback

#### Success

- Alert Message: "The installer app has been created successfully in /Applications"

#### Error Scenarios

1. **PKG Not Found**
   - Title: "Error Creating Installer"
   - Message: "The installer package 'InstallAssistant-X.X.X-XXXXX.pkg' does not exist in the Downloads folder. Please download it first."

2. **AppleScript Error**
   - Title: "Error Creating Installer"
   - Message: "Failed to create AppleScript"

3. **Installation Error**
   - Title: "Error Creating Installer"
   - Message: "Failed to create installer app. Error: [error details]"

## Technical Implementation

### Files Modified

- `FetchInstallerPkg/View/InstallerView.swift`
  - Added state variables for tracking installer creation
  - Added new button UI component
  - Implemented `createInstallerApp()` function
  - Added alert handling for success/error messages

### Security Considerations

- Prompts for admin authentication through macOS system dialog
- Does not store or handle passwords directly
- Runs in an async queue to avoid blocking the UI

## Usage Example

### Typical Workflow

1. User opens Download Full Installer
2. User selects a macOS version to download
3. User clicks the download button
4. Wait for download to complete
5. User clicks the "Create Installer App" button
6. System prompts for admin password
7. Installer app is created in /Applications
8. Success alert is displayed

### Alternative Workflow (PKG Already Downloaded)

1. User opens Download Full Installer
2. User sees an installer that was previously downloaded
3. User clicks the "Create Installer App" button directly
4. System prompts for admin password
5. Installer app is created in /Applications
6. Success alert is displayed

## Notes
	
- This feature is equivalent to double-clicking the InstallAssistant.pkg file and completing the installation
- The installer app will be placed in /Applications, ready to create bootable installers or perform clean installations
- The button is disabled during downloads to prevent conflicts
- The button is disabled while another installer is being created
		

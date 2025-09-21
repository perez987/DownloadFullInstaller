# MP3Player

![Platform](https://img.shields.io/badge/macOS-13+-orange.svg)
![Xcode](https://img.shields.io/badge/Xcode-macOS15+-lavender.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.5+-blue.svg)

A simple SwiftUI MP3 Player application for macOS that supports MP3 files and M3U playlists.

## Features

- Load and play MP3 files and other audio formats (M4A, WAV, AIFF, AAC)
- Support for M3U playlist files
- Player controls: Play, Pause, Stop, Next, Previous
- Time display: Elapsed and remaining time with progress bar
- Single instance application (prevents multiple instances from running)
- Drag and drop support for adding files
- Clean separation between Model and View components
- Modern SwiftUI interface with macOS system integration

## Requirements

- macOS 13 Ventura or later
- Xcode 15+ for building from source

## Architecture

The application follows a clean architecture with separation of concerns:

### Model Layer
- **AudioFile**: Represents individual audio files with metadata
- **Playlist**: Manages collection of audio files and current playback position  
- **AudioPlayer**: Handles audio playback, state management, and time tracking

### View Layer
- **MP3PlayerContentView**: Main application view with drag-and-drop support
- **PlayerControlsView**: Media controls and progress display
- **PlaylistView**: Displays and manages the current playlist

## Usage

1. Launch the MP3Player application
2. Add music files by:
   - Clicking "Add Files" button and selecting MP3/audio files
   - Dragging and dropping MP3 files or M3U playlists onto the window
3. Use the player controls to play, pause, stop, or navigate between tracks
4. View elapsed and remaining time with the progress slider
5. Manage your playlist by removing songs or clearing the entire playlist

## Single Instance

The application implements single instance behavior - if you try to launch a second instance, it will bring the existing instance to the front instead of creating a duplicate.

## Building from Source

1. Clone this repository
2. Open `FetchInstallerPkg.xcodeproj` in Xcode
3. Build and run the project

## License

This project is available under the MIT License. See the LICENSE file for more details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
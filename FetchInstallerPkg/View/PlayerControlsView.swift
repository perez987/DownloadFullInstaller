//
//  PlayerControlsView.swift
//  MP3Player
//
//  Created for MP3Player application
//

import SwiftUI

struct PlayerControlsView: View {
    @ObservedObject var audioPlayer: AudioPlayer
    @ObservedObject var playlist: Playlist
    
    var body: some View {
        VStack(spacing: 16) {
            // Current song info
            if let currentFile = audioPlayer.currentFile {
                VStack(spacing: 4) {
                    Text(currentFile.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if let artist = currentFile.artist {
                        Text(artist)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.bottom, 8)
            }
            
            // Progress bar
            VStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: { audioPlayer.progress },
                        set: { newValue in
                            let newTime = newValue * audioPlayer.duration
                            audioPlayer.seek(to: newTime)
                        }
                    ),
                    in: 0...1
                )
                .disabled(audioPlayer.currentFile == nil)
                
                // Time labels
                HStack {
                    Text(audioPlayer.formattedCurrentTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("-\(audioPlayer.formattedRemainingTime)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Control buttons
            HStack(spacing: 20) {
                // Previous button
                Button(action: {
                    if playlist.moveToPrevious(), let prevFile = playlist.currentFile {
                        audioPlayer.loadFile(prevFile)
                        if audioPlayer.currentState == .playing {
                            audioPlayer.play()
                        }
                    }
                }) {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                }
                .disabled(!playlist.hasPrevious)
                
                // Play/Pause button
                Button(action: {
                    switch audioPlayer.currentState {
                    case .stopped, .paused:
                        if audioPlayer.currentFile == nil, let currentFile = playlist.currentFile {
                            audioPlayer.loadFile(currentFile)
                        }
                        audioPlayer.play()
                    case .playing:
                        audioPlayer.pause()
                    }
                }) {
                    Image(systemName: audioPlayer.currentState == .playing ? "pause.fill" : "play.fill")
                        .font(.title)
                }
                .disabled(playlist.files.isEmpty)
                
                // Stop button
                Button(action: {
                    audioPlayer.stop()
                }) {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                }
                .disabled(audioPlayer.currentState == .stopped)
                
                // Next button
                Button(action: {
                    if playlist.moveToNext(), let nextFile = playlist.currentFile {
                        audioPlayer.loadFile(nextFile)
                        if audioPlayer.currentState == .playing {
                            audioPlayer.play()
                        }
                    }
                }) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                }
                .disabled(!playlist.hasNext)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}
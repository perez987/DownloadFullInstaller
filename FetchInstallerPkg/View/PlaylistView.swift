//
//  PlaylistView.swift
//  MP3Player
//
//  Created for MP3Player application
//

import SwiftUI

struct PlaylistView: View {
    @ObservedObject var playlist: Playlist
    @ObservedObject var audioPlayer: AudioPlayer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Playlist")
                    .font(.headline)
                
                Spacer()
                
                Text("\(playlist.files.count) songs")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if playlist.files.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No songs in playlist")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Drop MP3 files or M3U playlists here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(8)
            } else {
                List {
                    ForEach(Array(playlist.files.enumerated()), id: \.element.id) { index, audioFile in
                        PlaylistRowView(
                            audioFile: audioFile,
                            isCurrentlyPlaying: index == playlist.currentIndex && audioPlayer.currentState == .playing,
                            isCurrent: index == playlist.currentIndex,
                            onTap: {
                                playlist.moveToIndex(index)
                                audioPlayer.loadFile(audioFile)
                                audioPlayer.play()
                            }
                        )
                        .contextMenu {
                            Button("Remove from playlist") {
                                playlist.removeFile(at: index)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet.sorted(by: >) {
                            playlist.removeFile(at: index)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .padding()
    }
}

struct PlaylistRowView: View {
    let audioFile: AudioFile
    let isCurrentlyPlaying: Bool
    let isCurrent: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            // Play indicator
            Group {
                if isCurrentlyPlaying {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                } else if isCurrent {
                    Image(systemName: "pause.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                } else {
                    Image(systemName: "music.note")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(audioFile.title)
                    .font(.system(size: 13))
                    .fontWeight(isCurrent ? .semibold : .regular)
                    .foregroundColor(isCurrent ? .primary : .primary)
                    .lineLimit(1)
                
                if let artist = audioFile.artist {
                    Text(artist)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Text(audioFile.formattedDuration)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
        .background(isCurrent ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(4)
        .onTapGesture {
            onTap()
        }
    }
}
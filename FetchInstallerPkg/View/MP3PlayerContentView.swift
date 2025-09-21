//
//  MP3PlayerContentView.swift
//  MP3Player
//
//  Created for MP3Player application
//

import SwiftUI
import UniformTypeIdentifiers

struct MP3PlayerContentView: View {
    @StateObject private var playlist = Playlist()
    @StateObject private var audioPlayer = AudioPlayer.shared
    @State private var showingFilePicker = false
    @State private var isDragOver = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Player controls section
            PlayerControlsView(audioPlayer: audioPlayer, playlist: playlist)
                .padding()
            
            Divider()
            
            // Playlist section
            PlaylistView(playlist: playlist, audioPlayer: audioPlayer)
                .frame(minHeight: 300)
        }
        .frame(
            minWidth: 500,
            idealWidth: 600,
            maxWidth: .infinity,
            minHeight: 500,
            idealHeight: 600,
            maxHeight: .infinity
        )
        .background(isDragOver ? Color.blue.opacity(0.1) : Color.clear)
        .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
            handleDrop(providers: providers)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add Files") {
                    showingFilePicker = true
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button("Clear Playlist") {
                    playlist.clear()
                    audioPlayer.stop()
                }
                .disabled(playlist.files.isEmpty)
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.audio, .m3uPlaylist],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                handleSelectedFiles(urls)
            case .failure(let error):
                print("File selection failed: \(error)")
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var urls: [URL] = []
        
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url = url {
                    urls.append(url)
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            handleSelectedFiles(urls)
        }
        
        return true
    }
    
    private func handleSelectedFiles(_ urls: [URL]) {
        for url in urls {
            if url.pathExtension.lowercased() == "m3u" {
                // Handle M3U playlist
                do {
                    try playlist.loadM3UPlaylist(from: url)
                } catch {
                    print("Failed to load M3U playlist: \(error)")
                }
            } else if ["mp3", "m4a", "wav", "aiff", "aac"].contains(url.pathExtension.lowercased()) {
                // Handle individual audio file
                let audioFile = AudioFile(url: url)
                playlist.addFile(audioFile)
            }
        }
        
        // If this is the first file and nothing is currently playing, load it
        if audioPlayer.currentFile == nil && !playlist.files.isEmpty {
            playlist.moveToIndex(0)
            if let firstFile = playlist.currentFile {
                audioPlayer.loadFile(firstFile)
            }
        }
    }
}

extension UTType {
    static var m3uPlaylist: UTType {
        UTType(filenameExtension: "m3u") ?? UTType.plainText
    }
}

struct MP3PlayerContentView_Previews: PreviewProvider {
    static var previews: some View {
        MP3PlayerContentView()
    }
}
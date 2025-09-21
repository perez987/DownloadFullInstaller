//
//  Playlist.swift
//  MP3Player
//
//  Created for MP3Player application
//

import Foundation

class Playlist: ObservableObject {
    @Published var files: [AudioFile] = []
    @Published var currentIndex: Int = 0
    
    var currentFile: AudioFile? {
        guard currentIndex >= 0 && currentIndex < files.count else { return nil }
        return files[currentIndex]
    }
    
    var hasNext: Bool {
        return currentIndex < files.count - 1
    }
    
    var hasPrevious: Bool {
        return currentIndex > 0
    }
    
    func addFile(_ audioFile: AudioFile) {
        files.append(audioFile)
    }
    
    func addFiles(_ audioFiles: [AudioFile]) {
        files.append(contentsOf: audioFiles)
    }
    
    func removeFile(at index: Int) {
        guard index >= 0 && index < files.count else { return }
        files.remove(at: index)
        
        // Adjust current index if necessary
        if index < currentIndex {
            currentIndex -= 1
        } else if index == currentIndex && currentIndex >= files.count {
            currentIndex = max(0, files.count - 1)
        }
    }
    
    func clear() {
        files.removeAll()
        currentIndex = 0
    }
    
    func moveToNext() -> Bool {
        guard hasNext else { return false }
        currentIndex += 1
        return true
    }
    
    func moveToPrevious() -> Bool {
        guard hasPrevious else { return false }
        currentIndex -= 1
        return true
    }
    
    func moveToIndex(_ index: Int) {
        guard index >= 0 && index < files.count else { return }
        currentIndex = index
    }
    
    func loadM3UPlaylist(from url: URL) throws {
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)
        
        var newFiles: [AudioFile] = []
        let baseURL = url.deletingLastPathComponent()
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines and M3U comments
            if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                continue
            }
            
            // Handle both absolute and relative paths
            let fileURL: URL
            if trimmedLine.hasPrefix("/") || trimmedLine.contains("://") {
                fileURL = URL(fileURLWithPath: trimmedLine)
            } else {
                fileURL = baseURL.appendingPathComponent(trimmedLine)
            }
            
            // Check if file exists and is a supported audio format
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let pathExtension = fileURL.pathExtension.lowercased()
                if ["mp3", "m4a", "wav", "aiff", "aac"].contains(pathExtension) {
                    let audioFile = AudioFile(url: fileURL)
                    newFiles.append(audioFile)
                }
            }
        }
        
        addFiles(newFiles)
    }
}
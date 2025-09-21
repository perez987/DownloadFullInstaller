//
//  AudioFile.swift
//  MP3Player
//
//  Created for MP3Player application
//

import Foundation
import AVFoundation

struct AudioFile: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let title: String
    let artist: String?
    let duration: TimeInterval
    
    init(url: URL) {
        self.url = url
        
        // Extract metadata from the audio file
        let asset = AVAsset(url: url)
        let metadata = asset.commonMetadata
        
        var extractedTitle = url.deletingPathExtension().lastPathComponent
        var extractedArtist: String?
        
        for item in metadata {
            if let key = item.commonKey?.rawValue, let value = item.value as? String {
                switch key {
                case "title":
                    extractedTitle = value
                case "artist":
                    extractedArtist = value
                default:
                    break
                }
            }
        }
        
        self.title = extractedTitle
        self.artist = extractedArtist
        self.duration = asset.duration.seconds.isNaN ? 0 : asset.duration.seconds
    }
    
    var displayName: String {
        if let artist = artist {
            return "\(artist) - \(title)"
        }
        return title
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
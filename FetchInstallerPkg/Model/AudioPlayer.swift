//
//  AudioPlayer.swift
//  MP3Player
//
//  Created for MP3Player application
//

import Foundation
import AVFoundation
import Combine

enum PlayerState {
    case stopped
    case playing
    case paused
}

class AudioPlayer: ObservableObject {
    @Published var currentState: PlayerState = .stopped
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var currentFile: AudioFile?
    
    private var player: AVAudioPlayer?
    private var timer: Timer?
    
    static let shared = AudioPlayer()
    
    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func loadFile(_ audioFile: AudioFile) {
        stop()
        
        do {
            player = try AVAudioPlayer(contentsOf: audioFile.url)
            player?.prepareToPlay()
            currentFile = audioFile
            duration = player?.duration ?? 0
            currentTime = 0
        } catch {
            print("Failed to load audio file: \(error)")
            currentFile = nil
            duration = 0
        }
    }
    
    func play() {
        guard let player = player else { return }
        
        if player.play() {
            currentState = .playing
            startTimer()
        }
    }
    
    func pause() {
        player?.pause()
        currentState = .paused
        stopTimer()
    }
    
    func stop() {
        player?.stop()
        player?.currentTime = 0
        currentState = .stopped
        currentTime = 0
        stopTimer()
    }
    
    func seek(to time: TimeInterval) {
        guard let player = player else { return }
        player.currentTime = min(max(time, 0), duration)
        currentTime = player.currentTime
    }
    
    var remainingTime: TimeInterval {
        return duration - currentTime
    }
    
    var formattedCurrentTime: String {
        return formatTime(currentTime)
    }
    
    var formattedRemainingTime: String {
        return formatTime(remainingTime)
    }
    
    var formattedDuration: String {
        return formatTime(duration)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.player else { return }
            
            DispatchQueue.main.async {
                self.currentTime = player.currentTime
                
                // Check if playback finished
                if !player.isPlaying && self.currentState == .playing {
                    self.currentState = .stopped
                    self.stopTimer()
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    deinit {
        stopTimer()
    }
}
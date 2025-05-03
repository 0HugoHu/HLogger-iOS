//
//  SilentAudioManager.swift
//  HCronCore
//
//  Created by Hugooooo on 3/24/25.
//

import AVFoundation

@MainActor
public class SilentAudioManager {
    public static let shared = SilentAudioManager()
    private var player: AVAudioPlayer?
    
    private init() {}
    
    public func startBackgroundAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            
            if let url = Bundle.main.url(forResource: "silence", withExtension: "mp3") {
                player = try AVAudioPlayer(contentsOf: url)
                player?.numberOfLoops = -1
                player?.volume = 0.0
                player?.play()
            }
        } catch {
            print("Failed to play silent audio: \(error)")
        }
    }
    
    public func stopBackgroundAudio() {
        player?.stop()
    }
}

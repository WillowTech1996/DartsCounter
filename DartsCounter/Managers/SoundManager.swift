import Foundation
import AVFoundation

// MARK: - Sound Manager
class SoundManager: ObservableObject {
    static let shared = SoundManager()

    private var audioPlayer: AVAudioPlayer?
    @Published var isSoundEnabled: Bool = true

    private init() {
        // Initialize with sound enabled
    }

    // MARK: - Score Announcements

    /// Announce a visit total (after 3 darts)
    func announceVisitTotal(_ total: Int) {
        guard isSoundEnabled else { return }

        // Special announcement for 180
        if total == 180 {
            playSound(named: "180")
        }
        // For other scores, do nothing for now (we'll add more sounds later)
    }

    /// Announce remaining score
    func announceRemainingScore(_ score: Int) {
        guard isSoundEnabled else { return }
        // Disabled for now - we'll add sounds later
    }

    /// Announce bust
    func announceBust() {
        guard isSoundEnabled else { return }
        // Disabled for now - we'll add sounds later
    }

    /// Announce game over
    func announceGameOver(winner: String) {
        guard isSoundEnabled else { return }
        // Disabled for now - we'll add sounds later
    }

    // MARK: - Private Audio Methods

    private func playSound(named soundName: String) {
        // Try to find the sound file - first try with Sounds subdirectory, then without
        var soundURL: URL?

        // Try subdirectory first
        soundURL = Bundle.main.url(forResource: soundName, withExtension: "mp3", subdirectory: "Sounds")

        // If not found, try root
        if soundURL == nil {
            soundURL = Bundle.main.url(forResource: soundName, withExtension: "mp3")
        }

        // If still not found, try looking for the file directly
        if soundURL == nil {
            soundURL = Bundle.main.url(forResource: "Sounds/\(soundName)", withExtension: "mp3")
        }

        guard let url = soundURL else {
            print("❌ Sound file not found: \(soundName).mp3")
            print("Searched in: Sounds folder, root, and Sounds/\(soundName)")
            return
        }

        print("✅ Found sound file: \(url.path)")

        do {
            // Stop any currently playing audio
            audioPlayer?.stop()

            // Create and play the audio
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = 1.0
            audioPlayer?.play()
            print("🔊 Playing sound: \(soundName)")
        } catch {
            print("❌ Error playing sound: \(error.localizedDescription)")
        }
    }

    /// Stop all current audio
    func stopSpeaking() {
        audioPlayer?.stop()
    }
}

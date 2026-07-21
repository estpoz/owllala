//
//  AudioService.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//
//  OVERVIEW
//  --------
//  Plays the short feedback sounds used by the gameplay components in
//  `ImmediateFeedback.swift`:
//
//    • Clap        — with the confetti when the child answers correctly.
//    • Wrong buzz  — when the child picks a wrong answer.
//
//  SOUND FILES
//  -----------
//  Assets live under `Resources/Audios/...` (copied flat into the bundle).
//  The service looks up each sound by candidate names, in every known
//  subdirectory, with mp3/wav/m4a; lookups are case-sensitive:
//
//    "Confetti Sound"  → playConfettiSound()
//    "Clap"            → playClapSound()
//    "Oooo Owwww"      → playWrongAnswerSound()
//
//  Missing files are a safe no-op (DEBUG-only console note), so the UI
//  features work before their audio assets are imported.
//

import AVFoundation
import Foundation

// MARK: - Audio Service

/// Plays short gameplay sounds and story voice-over narration.
///
/// A shared instance keeps one `AVAudioPlayer` cached per sound so repeated
/// plays (e.g. several wrong answers) don't re-read the file from disk.
@MainActor
final class AudioService {

    /// The app-wide shared instance.
    static let shared = AudioService()

    /// Cached players, keyed by sound name.
    private var players: [String: AVAudioPlayer] = [:]
    private var voiceOverPlayer: AVAudioPlayer?

    /// File extensions to try, in order, when locating a sound in the bundle.
    private let supportedExtensions = ["mp3", "wav", "m4a"]

    /// Configures the audio session so feedback sounds mix politely with any
    /// other audio (they never interrupt background music).
    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
    }

    /// Bundle subdirectories to search, in order. Audio assets live under
    /// `Resources/Audios/...`, but depending on how Xcode copies them they may
    /// land at the bundle root, so that is tried first.
    private let searchSubdirectories = [
        "",
        "Audios/Immediate Feedback",
        "Audios/Chapter 1",
        "Audios/Chapter 2",
        "Audios/Chapter 3",
        "Audios/Chapter 4",
        "Audios/Chapter 5",
        "Audios",
        "Immediate Feedback",
        "Chapter 1",
        "Chapter 2",
        "Chapter 3",
        "Chapter 4",
        "Chapter 5"
    ]

    // MARK: Gameplay Sounds

    /// Plays the confetti sound of the correct-answer celebration.
    ///
    /// Called by `CorrectAnswerCelebration.startConfetti()` as the confetti
    /// starts falling. Wired to the imported "Confetti Sound" asset.
    func playConfettiSound() {
        play(candidates: ["Confetti Sound", "confetti"])
    }

    /// Plays the clap sound of the correct-answer celebration.
    ///
    /// Called by `CorrectAnswerCelebration.playClapSound()` together with the
    /// confetti. Wired to the imported "Clap" asset.
    func playClapSound() {
        play(candidates: ["Clap", "clap"])
    }

    /// Plays the wrong-answer sound.
    ///
    /// Called by the `wrongAnswerFeedback` modifier together with the shake and
    /// vibration. Wired to the imported "Oooo Owwww" asset.
    func playWrongAnswerSound() {
        play(candidates: ["Oooo Owwww", "Wrong Sound", "wrong"])
    }

    /// Plays one story-page voice-over, replacing any narration currently
    /// playing. Feedback sounds use their own cached players and continue to
    /// work independently.
    func playVoiceOver(named name: String) {
        stopVoiceOver()

        guard let player = makePlayer(candidates: [name]) else {
            #if DEBUG
            print("AudioService: voice-over \(name) not found in bundle — skipping playback.")
            #endif
            return
        }

        voiceOverPlayer = player
        player.currentTime = 0
        player.play()
    }

    func stopVoiceOver() {
        voiceOverPlayer?.stop()
        voiceOverPlayer = nil
    }

    // MARK: Playback

    /// Plays the first bundle sound found among the candidate names, caching
    /// the player under the first candidate.
    ///
    /// Missing files are tolerated silently (DEBUG log only) so features can
    /// ship ahead of their audio assets.
    ///
    /// - Parameter candidates: File names (without extension) to try in order.
    private func play(candidates: [String]) {
        let cacheKey = candidates[0]

        if let cachedPlayer = players[cacheKey] {
            cachedPlayer.currentTime = 0
            cachedPlayer.play()
            return
        }

        guard let player = makePlayer(candidates: candidates) else {
            #if DEBUG
            print("AudioService: none of \(candidates) found in bundle — skipping playback.")
            #endif
            return
        }

        players[cacheKey] = player
        player.play()
    }

    /// Builds a player for the first matching bundle file, trying every
    /// candidate name, extension, and known subdirectory.
    ///
    /// - Parameter candidates: File names (without extension) to try in order.
    /// - Returns: A prepared player, or `nil` when no asset is bundled yet.
    private func makePlayer(candidates: [String]) -> AVAudioPlayer? {
        for name in candidates {
            for subdirectory in searchSubdirectories {
                for fileExtension in supportedExtensions {
                    let url = subdirectory.isEmpty
                        ? Bundle.main.url(forResource: name, withExtension: fileExtension)
                        : Bundle.main.url(forResource: name, withExtension: fileExtension, subdirectory: subdirectory)

                    if let url, let player = try? AVAudioPlayer(contentsOf: url) {
                        player.prepareToPlay()
                        return player
                    }
                }
            }
        }

        return nil
    }
}

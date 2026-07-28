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
//    • Background music — loops continuously from app launch.
//    • Correct answer   — when the child selects the correct option.
//    • Yay and applause — with the correct-answer celebration.
//    • Wrong buzz       — when the child picks a wrong answer.
//
//  SOUND FILES
//  -----------
//  Assets live under `Resources/Audios/...` (copied flat into the bundle).
//  The service looks up each sound by candidate names, in every known
//  subdirectory, with mp3/wav/m4a; lookups are case-sensitive:
//
//    "backgroundMusic"          → playBackgroundMusic(...)
//    "correctAnswerSoundEffect" → playCorrectAnswerSound()
//    "yaySoundEffect"           → playYaySound()
//    "applauseSoundEffect"      → playApplauseSound()
//    "Oooo Owwww"               → playWrongAnswerSound()
//
//  Missing files are a safe no-op (DEBUG-only console note), so the UI
//  features work before their audio assets are imported.
//

import AVFoundation
import Combine
import Foundation

// MARK: - Audio Service

/// Plays short gameplay sounds and story voice-over narration.
///
/// A shared instance keeps one `AVAudioPlayer` cached per sound so repeated
/// plays (e.g. several wrong answers) don't re-read the file from disk.
@MainActor
final class AudioService: ObservableObject {

    /// The app-wide shared instance.
    static let shared = AudioService()

    /// Whether story narration is enabled for the current app session.
    ///
    /// This intentionally is not persisted because audio preferences are
    /// session-scoped in the MVP.
    @Published private(set) var isVoiceOverEnabled = true

    /// Cached players, keyed by sound name.
    private var players: [String: AVAudioPlayer] = [:]
    private var voiceOverPlayer: AVAudioPlayer?
    private var backgroundMusicPlayer: AVAudioPlayer?
    private var wrongAnswerDuckTask: Task<Void, Never>?
    private var backgroundMusicBaseVolume = BackgroundMusicVolume.voiceOverEnabled

    private enum BackgroundMusicVolume {
        static let voiceOverEnabled: Float = 0.12
        static let voiceOverDisabled: Float = 0.40
        static let wrongAnswer: Float = 0.04
    }

    private static let wrongAnswerDuckDuration: TimeInterval = 2.9

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

    /// Starts or resumes looping gameplay music at the appropriate voice-over volume.
    func playBackgroundMusic(isVoiceOverEnabled: Bool) {
        let volume = backgroundMusicVolume(isVoiceOverEnabled: isVoiceOverEnabled)
        backgroundMusicBaseVolume = volume

        if let backgroundMusicPlayer {
            if wrongAnswerDuckTask == nil {
                backgroundMusicPlayer.volume = volume
            }

            guard !backgroundMusicPlayer.isPlaying else {
                return
            }

            backgroundMusicPlayer.play()
            return
        }

        guard let player = makePlayer(candidates: ["backgroundMusic"]) else {
            #if DEBUG
            print("AudioService: backgroundMusic not found in bundle — skipping playback.")
            #endif
            return
        }

        player.numberOfLoops = -1
        player.volume = wrongAnswerDuckTask == nil
            ? volume
            : BackgroundMusicVolume.wrongAnswer
        backgroundMusicPlayer = player
        player.play()
    }

    /// Smoothly updates gameplay-music volume after the voice-over toggle changes.
    func updateBackgroundMusicVolume(isVoiceOverEnabled: Bool) {
        backgroundMusicBaseVolume = backgroundMusicVolume(
            isVoiceOverEnabled: isVoiceOverEnabled
        )

        guard wrongAnswerDuckTask == nil else {
            return
        }

        backgroundMusicPlayer?.setVolume(
            backgroundMusicBaseVolume,
            fadeDuration: 0.25
        )
    }

    /// Toggles narration for the current app session.
    ///
    /// Disabling narration immediately stops the active story voice-over.
    /// The returned value lets the gameplay view resume the current page when
    /// narration is turned back on.
    @discardableResult
    func toggleVoiceOver() -> Bool {
        isVoiceOverEnabled.toggle()
        updateBackgroundMusicVolume(isVoiceOverEnabled: isVoiceOverEnabled)

        if !isVoiceOverEnabled {
            stopVoiceOver()
        }

        return isVoiceOverEnabled
    }

    /// Temporarily lowers gameplay music while wrong-answer feedback is audible.
    /// Repeated wrong answers restart the restoration timer.
    func duckBackgroundMusicForWrongAnswer() {
        guard backgroundMusicPlayer?.isPlaying == true else {
            return
        }

        wrongAnswerDuckTask?.cancel()
        backgroundMusicPlayer?.setVolume(
            BackgroundMusicVolume.wrongAnswer,
            fadeDuration: 0.1
        )

        wrongAnswerDuckTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .seconds(Self.wrongAnswerDuckDuration))
            } catch {
                return
            }

            guard !Task.isCancelled else {
                return
            }

            self?.restoreBackgroundMusicAfterWrongAnswer()
        }
    }

    /// Stops gameplay music and resets it for the next session.
    func stopBackgroundMusic() {
        wrongAnswerDuckTask?.cancel()
        wrongAnswerDuckTask = nil
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer?.currentTime = 0
    }

    /// Returns continuous app music to its normal non-gameplay volume.
    func restoreBackgroundMusicForApp() {
        wrongAnswerDuckTask?.cancel()
        wrongAnswerDuckTask = nil
        backgroundMusicBaseVolume = BackgroundMusicVolume.voiceOverDisabled

        guard backgroundMusicPlayer?.isPlaying == true else {
            playBackgroundMusic(isVoiceOverEnabled: false)
            return
        }

        backgroundMusicPlayer?.setVolume(
            backgroundMusicBaseVolume,
            fadeDuration: 0.25
        )
    }

    /// Plays the correct-answer sound when the correct option is selected.
    func playCorrectAnswerSound() {
        play(candidates: ["correctAnswerSoundEffect"])
    }

    /// Plays the yay sound during the correct-answer celebration.
    func playYaySound() {
        play(candidates: ["yaySoundEffect"])
    }

    /// Plays the applause sound during the correct-answer celebration.
    func playApplauseSound() {
        play(candidates: ["applauseSoundEffect"])
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

    private func backgroundMusicVolume(isVoiceOverEnabled: Bool) -> Float {
        isVoiceOverEnabled
            ? BackgroundMusicVolume.voiceOverEnabled
            : BackgroundMusicVolume.voiceOverDisabled
    }

    private func restoreBackgroundMusicAfterWrongAnswer() {
        backgroundMusicPlayer?.setVolume(
            backgroundMusicBaseVolume,
            fadeDuration: 0.25
        )
        wrongAnswerDuckTask = nil
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

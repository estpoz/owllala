//
//  Settings.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//

import Foundation

/// Stores the user's persisted application preferences.
///
/// These values control audio, feedback, readability, and exit-confirmation
/// behavior. The settings are loaded and saved through `StorageService`.
struct Settings: Codable, Hashable, Sendable {

    /// Controls whether background music may be played.
    var isBackgroundMusicEnabled: Bool

    /// Controls whether interaction sound effects may be played.
    var isSoundEffectEnabled: Bool

    /// Controls whether story narration may be played.
    var isNarrationEnabled: Bool

    /// Controls whether supported devices provide haptic feedback.
    var isHapticFeedbackEnabled: Bool

    /// The preferred background-music volume from zero to one.
    var backgroundMusicVolume: Double

    /// The preferred sound-effect volume from zero to one.
    var soundEffectVolume: Double

    /// The preferred narration volume from zero to one.
    var narrationVolume: Double

    /// The text-size preference used by supported application screens.
    var textSize: AppTextSize

    /// Controls whether the app asks for confirmation before leaving gameplay.
    var shouldConfirmBeforeExit: Bool

    /// The default preferences used when no saved settings are available.
    static let defaultValue = Settings()
}

/// A predefined text-size option used throughout the application.
enum AppTextSize: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {

    /// Displays text slightly below the standard scale.
    case small

    /// Displays text at the standard application scale.
    case medium

    /// Displays text above the standard application scale.
    case large

    var id: String {
        rawValue
    }

    /// The Indonesian label displayed in the settings interface.
    var displayName: String {
        switch self {
        case .small:
            return "Kecil"
        case .medium:
            return "Sedang"
        case .large:
            return "Besar"
        }
    }

    /// The multiplier applied to supported base font sizes.
    var scale: Double {
        switch self {
        case .small:
            return 0.9
        case .medium:
            return 1.0
        case .large:
            return 1.2
        }
    }
}
//
//  Settings.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//

import Foundation

// MARK: - Settings

/// Stores the user's persisted application preferences.
///
/// The same settings are used by the main Settings screen and the Settings
/// overlay presented during gameplay.
struct Settings: Codable, Hashable, Sendable {

    /// The minimum supported background-brightness value.
    static let minimumBackgroundBrightness = 0.6

    /// The maximum supported background-brightness value.
    static let maximumBackgroundBrightness = 1.0

    /// The minimum text-scale value (1.0 = follow the system size).
    static let minimumTextScale = 1.0

    /// The maximum text-scale value.
    static let maximumTextScale = 1.4

    /// The default preferences used when no saved settings are available.
    static let defaultValue = Settings(
        backgroundBrightness: 1.0,
        colorVisionSimulation: nil,
        textScale: 1.0
    )

    /// Controls the brightness of supported application background layers.
    ///
    /// The value should remain between
    /// `minimumBackgroundBrightness` and `maximumBackgroundBrightness`.
    ///
    /// This setting must only affect designated background assets. Foreground
    /// objects, controls, illustrations, and text should remain unchanged.
    var backgroundBrightness: Double

    /// The active color-vision simulation.
    ///
    /// A `nil` value means that color simulation is disabled.
    /// When the simulation is disabled, the previously selected type is not
    /// retained.
    var colorVisionSimulation: ColorVisionSimulation?

    /// The preferred text-size scale ("Ukuran Teks").
    ///
    /// `1.0` follows the system Dynamic Type size unchanged; larger values
    /// scale the app's text up, within `minimumTextScale...maximumTextScale`.
    var textScale: Double

    /// Indicates whether a color-vision simulation is currently active.
    var isColorVisionSimulationEnabled: Bool {
        colorVisionSimulation != nil
    }

    /// Creates application settings with normalized values.
    ///
    /// Background brightness and text scale are clamped to their supported
    /// ranges.
    ///
    /// - Parameters:
    ///   - backgroundBrightness: The preferred background-brightness level.
    ///   - colorVisionSimulation: The optional active simulation type.
    ///   - textScale: The preferred text-size scale.
    init(
        backgroundBrightness: Double = 1.0,
        colorVisionSimulation: ColorVisionSimulation? = nil,
        textScale: Double = 1.0
    ) {
        self.backgroundBrightness = min(
            max(
                backgroundBrightness,
                Self.minimumBackgroundBrightness
            ),
            Self.maximumBackgroundBrightness
        )

        self.colorVisionSimulation = colorVisionSimulation

        self.textScale = min(
            max(textScale, Self.minimumTextScale),
            Self.maximumTextScale
        )
    }

    /// Restores settings from persisted data.
    ///
    /// `textScale` is decoded leniently (defaulting to `1.0`) so settings saved
    /// by versions of the app from before the text-size feature still load.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.init(
            backgroundBrightness: try container.decode(Double.self, forKey: .backgroundBrightness),
            colorVisionSimulation: try container.decodeIfPresent(ColorVisionSimulation.self, forKey: .colorVisionSimulation),
            textScale: try container.decodeIfPresent(Double.self, forKey: .textScale) ?? Self.minimumTextScale
        )
    }

    private enum CodingKeys: String, CodingKey {
        case backgroundBrightness
        case colorVisionSimulation
        case textScale
    }

    /// Updates the preferred background brightness.
    ///
    /// Values outside the supported range are clamped automatically.
    ///
    /// - Parameter value: The requested brightness value.
    mutating func setBackgroundBrightness(_ value: Double) {
        backgroundBrightness = min(
            max(
                value,
                Self.minimumBackgroundBrightness
            ),
            Self.maximumBackgroundBrightness
        )
    }

    /// Enables the selected color-vision simulation.
    ///
    /// - Parameter simulation: The simulation type to apply.
    mutating func enableColorVisionSimulation(
        _ simulation: ColorVisionSimulation
    ) {
        colorVisionSimulation = simulation
    }

    /// Disables the active color-vision simulation.
    ///
    /// The previously selected simulation type is not retained.
    mutating func disableColorVisionSimulation() {
        colorVisionSimulation = nil
    }

    /// Updates the preferred text-size scale.
    ///
    /// Values outside the supported range are clamped automatically.
    ///
    /// - Parameter value: The requested text scale.
    mutating func setTextScale(_ value: Double) {
        textScale = min(
            max(value, Self.minimumTextScale),
            Self.maximumTextScale
        )
    }
}

// MARK: - Color Vision Simulation

/// A color-vision deficiency type that can be simulated by the application.
///
/// The simulation is intended for preview and testing purposes. It does not
/// diagnose the user's color vision.
enum ColorVisionSimulation:
    String,
    Codable,
    CaseIterable,
    Identifiable,
    Hashable,
    Sendable {

    /// Simulates reduced or absent sensitivity to red light.
    case protanopia

    /// Simulates reduced or absent sensitivity to green light.
    case deuteranopia

    /// Simulates reduced or absent sensitivity to blue light.
    case tritanopia

    var id: String {
        rawValue
    }

    /// The label displayed in the settings interface.
    var displayName: String {
        switch self {
        case .protanopia:
            return "Red/Green"

        case .deuteranopia:
            return "Green/Red"

        case .tritanopia:
            return "Blue/Yellow"
        }
    }
}

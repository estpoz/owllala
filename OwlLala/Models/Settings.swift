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

    /// The default preferences used when no saved settings are available.
    static let defaultValue = Settings(
        backgroundBrightness: 1.0,
        colorVisionSimulation: nil,
        textSize: .large
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
    var colorVisionSimulation: ColorVisionSimulation?

    /// The most recently selected simulation, retained while the filter is off
    /// so enabling it again restores the child's previous choice.
    var lastColorVisionSimulation: ColorVisionSimulation

    /// The preferred app-wide Dynamic Type category ("Ukuran Teks").
    var textSize: AppTextSize

    /// Indicates whether a color-vision simulation is currently active.
    var isColorVisionSimulationEnabled: Bool {
        colorVisionSimulation != nil
    }

    /// Creates application settings with normalized values.
    ///
    /// Background brightness is clamped to its supported range.
    ///
    /// - Parameters:
    ///   - backgroundBrightness: The preferred background-brightness level.
    ///   - colorVisionSimulation: The optional active simulation type.
    ///   - lastColorVisionSimulation: The most recently selected simulation.
    ///   - textSize: The preferred app-wide Dynamic Type category.
    init(
        backgroundBrightness: Double = 1.0,
        colorVisionSimulation: ColorVisionSimulation? = nil,
        lastColorVisionSimulation: ColorVisionSimulation? = nil,
        textSize: AppTextSize = .large
    ) {
        self.backgroundBrightness = min(
            max(
                backgroundBrightness,
                Self.minimumBackgroundBrightness
            ),
            Self.maximumBackgroundBrightness
        )

        self.colorVisionSimulation = colorVisionSimulation
        self.lastColorVisionSimulation = lastColorVisionSimulation
            ?? colorVisionSimulation
            ?? .protanopia

        self.textSize = textSize
    }

    /// Restores settings from persisted data.
    ///
    /// Settings saved by the earlier multiplier-based text-size slider are
    /// migrated to the closest matching Dynamic Type category.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let decodedTextSize: AppTextSize
        if let textSize = try container.decodeIfPresent(
            AppTextSize.self,
            forKey: .textSize
        ) {
            decodedTextSize = textSize
        } else if let legacyScale = try container.decodeIfPresent(
            Double.self,
            forKey: .textScale
        ) {
            decodedTextSize = AppTextSize(legacyTextScale: legacyScale)
        } else {
            decodedTextSize = .large
        }

        let decodedSimulation = try container.decodeIfPresent(
            ColorVisionSimulation.self,
            forKey: .colorVisionSimulation
        )

        self.init(
            backgroundBrightness: try container.decode(Double.self, forKey: .backgroundBrightness),
            colorVisionSimulation: decodedSimulation,
            lastColorVisionSimulation: try container.decodeIfPresent(
                ColorVisionSimulation.self,
                forKey: .lastColorVisionSimulation
            ) ?? decodedSimulation,
            textSize: decodedTextSize
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(backgroundBrightness, forKey: .backgroundBrightness)
        try container.encodeIfPresent(
            colorVisionSimulation,
            forKey: .colorVisionSimulation
        )
        try container.encode(
            lastColorVisionSimulation,
            forKey: .lastColorVisionSimulation
        )
        try container.encode(textSize, forKey: .textSize)
    }

    private enum CodingKeys: String, CodingKey {
        case backgroundBrightness
        case colorVisionSimulation
        case lastColorVisionSimulation
        case textSize
        /// Legacy key used before the slider represented Dynamic Type steps.
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
        lastColorVisionSimulation = simulation
    }

    /// Disables the active color-vision simulation.
    ///
    /// The previously selected simulation remains available for the next time
    /// the filter is enabled.
    mutating func disableColorVisionSimulation() {
        colorVisionSimulation = nil
    }

    /// Updates the preferred app-wide Dynamic Type category.
    mutating func setTextSize(_ value: AppTextSize) {
        textSize = value
    }
}

// MARK: - App Text Size

/// A persisted, framework-independent representation of every supported
/// iPadOS Dynamic Type category, from X Small through Accessibility 5.
enum AppTextSize: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case extraSmall
    case small
    case medium
    case large
    case extraLarge
    case extraExtraLarge
    case extraExtraExtraLarge
    case accessibility1
    case accessibility2
    case accessibility3
    case accessibility4
    case accessibility5

    var id: String { rawValue }

    /// Stable ordinal used by the stepped Settings slider.
    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }

    /// Creates the closest valid choice for a slider index.
    init(nearestIndex index: Int) {
        let clampedIndex = min(max(index, 0), Self.allCases.count - 1)
        self = Self.allCases[clampedIndex]
    }

    /// Migrates the previous `1.0...1.4` multiplier into the category it
    /// rendered before this discrete range was introduced.
    fileprivate init(legacyTextScale: Double) {
        switch legacyTextScale {
        case ..<1.05:
            self = .large
        case ..<1.15:
            self = .extraLarge
        case ..<1.25:
            self = .extraExtraLarge
        case ..<1.35:
            self = .extraExtraExtraLarge
        default:
            self = .accessibility1
        }
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

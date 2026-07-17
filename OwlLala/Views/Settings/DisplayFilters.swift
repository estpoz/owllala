//
//  DisplayFilters.swift
//  OwlLala
//
//  OVERVIEW
//  --------
//  The runtime that makes the Settings values actually change what's on screen:
//
//  • Background brightness — dims the wrapped content by layering black at
//    `1 - brightness` opacity (brightness 1.0 = untouched, 0.6 = 40% dimmed,
//    matching `Settings.minimumBackgroundBrightness`).
//  • Color-vision filter — re-maps every rendered pixel through a 3x3 RGB
//    matrix on the GPU (`ColorVisionFilter.metal`), like iOS's accessibility
//    "Color Filters". One matrix per `ColorVisionSimulation` case, using the
//    Machado et al. (2009) full-severity simulation matrices.
//
//  WHERE IT IS USED
//  ----------------
//  `ContentView` applies `.displayAdjustments(for:)` to the WHOLE screen, so
//  both the brightness dim and the color filter cover everything the child
//  sees. Future screens should do the same at their root.
//
//  IMPORTANT LIMITATION (and how this app satisfies it)
//  -----------------------------------------------------
//  SwiftUI shader effects (`colorEffect`) rasterize only SwiftUI-drawn content.
//  UIKit-backed views inside the filtered subtree — `ScrollView`, system
//  `Slider`/`Toggle`, any `UIViewRepresentable` — cannot be captured and simply
//  vanish from the render. Whole-screen filtering therefore requires every
//  view in the subtree to be SwiftUI-drawn: that's why `Buttons.swift` ships
//  `SettingsSlider`/`SettingsToggle` (shape-drawn replacements) and the
//  settings panel avoids `ScrollView`. Keep new screens UIKit-free, or their
//  content will disappear when filtered.
//
//  DEPENDENCIES
//  ------------
//  Reads `Settings` and `ColorVisionSimulation` from the Models layer, and the
//  `colorVisionFilter` Metal function from `ColorVisionFilter.metal`.
//

import SwiftUI

// MARK: - View Modifiers

extension View {

    /// Dims the view to simulate a lower background brightness.
    ///
    /// `brightness` is expected in `Settings.minimumBackgroundBrightness...
    /// Settings.maximumBackgroundBrightness` (0.6...1.0). A value of `1.0`
    /// leaves the content untouched; lower values darken it proportionally by
    /// overlaying black at `1 - brightness` opacity. The overlay ignores touch
    /// input, so controls underneath keep working.
    ///
    /// - Parameter brightness: The brightness level from `Settings`.
    /// - Returns: The dimmed view.
    func backgroundBrightness(_ brightness: Double) -> some View {
        overlay {
            Color.black
                .opacity((1.0 - brightness).clamped(to: 0.0...1.0))
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }

    /// Applies a color-vision-deficiency filter to everything this view renders,
    /// mirroring iOS's accessibility "Color Filters".
    ///
    /// The view subtree is flattened (`compositingGroup`) and every pixel is
    /// re-mapped through the simulation matrix for `simulation` by the
    /// `colorVisionFilter` Metal shader. Passing `nil` (filter off) returns the
    /// view unchanged.
    ///
    /// ⚠️ Every view in the filtered subtree must be SwiftUI-drawn. UIKit-backed
    /// views — `ScrollView`, system `Slider`/`Toggle`, representables — can't
    /// be rasterized by shader effects and will disappear from the render. Use
    /// the shape-drawn `SettingsSlider`/`SettingsToggle` (see `Buttons.swift`)
    /// instead of the system controls on filtered screens.
    ///
    /// - Parameter simulation: The active filter type, or `nil` for none.
    /// - Returns: The filtered (or untouched) view.
    ///
    /// IMPORTANT: this must stay branch-free (no `if let` around the view).
    /// A structural branch changes the subtree's identity when the filter
    /// toggles, which resets all `@State`/`onAppear` below it — that bug made
    /// selecting a filter instantly undo itself. With `nil`, the shader runs
    /// with an identity matrix (no visible change) so the view tree is stable.
    func colorVisionFilter(_ simulation: ColorVisionSimulation?) -> some View {
        compositingGroup()
            .colorEffect(
                ShaderLibrary.colorVisionFilter(
                    .floatArray(simulation?.simulationMatrix ?? ColorVisionSimulation.identityMatrix)
                )
            )
    }

    /// Applies the screen-wide display adjustments from a `Settings` value:
    /// the color-vision filter and the text-size scale.
    ///
    /// Background brightness is intentionally NOT included — per the
    /// `Settings` model rule it only dims designated background layers, which
    /// apply `backgroundBrightness(_:)` / `appBackgroundBrightness()`
    /// themselves.
    ///
    /// ⚠️ The screen must be built from SwiftUI-drawn views only (no
    /// `ScrollView`, no system `Slider`/`Toggle`, no representables), otherwise
    /// those views vanish under the shader — see `colorVisionFilter(_:)`.
    ///
    /// - Parameter settings: The settings to apply.
    /// - Returns: The adjusted view.
    func displayAdjustments(for settings: Settings) -> some View {
        colorVisionFilter(settings.colorVisionSimulation)
            .textSizeAdjustment(for: settings)
    }

    /// Scales the app's text according to the "Ukuran Teks" setting by raising
    /// the subtree's Dynamic Type size.
    ///
    /// `textScale == 1.0` leaves the system size untouched; larger values map
    /// to progressively larger Dynamic Type sizes, which all text using
    /// `@ScaledMetric`/text styles follows automatically.
    ///
    /// - Parameter settings: The settings whose text scale to apply.
    /// - Returns: The view with the adjusted type size.
    ///
    /// Implemented with `transformEnvironment` so it is branch-free: an
    /// `if let` around the view would change the subtree's identity whenever
    /// the scale crosses 1.0, resetting state below (which made the Ukuran
    /// Teks slider snap back while dragging).
    func textSizeAdjustment(for settings: Settings) -> some View {
        transformEnvironment(\.dynamicTypeSize) { dynamicTypeSize in
            if let preferred = settings.preferredDynamicTypeSize {
                dynamicTypeSize = preferred
            }
        }
    }
}

// MARK: - Text Scale Mapping

extension Settings {

    /// The Dynamic Type size the app should render at for the current
    /// `textScale`, or `nil` when the system size should be left untouched
    /// (`textScale` ≈ 1.0).
    ///
    /// Lives here rather than in the model because `DynamicTypeSize` is a
    /// SwiftUI type and the Models layer stays UI-framework-free.
    var preferredDynamicTypeSize: DynamicTypeSize? {
        switch textScale {
        case ..<1.05:
            return nil
        case ..<1.15:
            return .xLarge
        case ..<1.25:
            return .xxLarge
        case ..<1.35:
            return .xxxLarge
        default:
            return .accessibility1
        }
    }
}

// MARK: - App-Wide Adjustments (Environment-Based)

/// Applies the app's *current* display settings — the draft while the child is
/// editing, the saved settings otherwise — read from the `SettingsViewModel`
/// in the SwiftUI environment.
///
/// This is what lets ANY view opt in without plumbing: inject the shared view
/// model once (`.environmentObject(settingsViewModel)`, done at the app root),
/// then any screen can simply write:
///
///     SomeScreen()
///         .appDisplayAdjustments()
///
/// ⚠️ Apply it once per layer (normally at a screen's root). A view already
/// inside an adjusted ancestor must not apply it again, or the color matrix
/// runs twice and distorts.
private struct AppDisplayAdjustments: ViewModifier {

    /// Whether the color-vision shader is included. Screens containing
    /// UIKit-backed views (`ScrollView`, `NavigationStack`, system controls)
    /// must pass `false` — the shader can't rasterize them and SwiftUI renders
    /// a yellow "no entry" placeholder instead of the screen.
    let includesColorFilter: Bool

    /// The shared settings logic, injected via `environmentObject`.
    @EnvironmentObject private var settingsViewModel: SettingsViewModel

    func body(content: Content) -> some View {
        let settings = settingsViewModel.activeDisplaySettings

        if includesColorFilter {
            content
                .colorVisionFilter(settings.colorVisionSimulation)
                .textSizeAdjustment(for: settings)
        } else {
            // Text size is environment based, so it is always safe — only the
            // shader needs rasterizable content.
            content
                .textSizeAdjustment(for: settings)
        }
    }
}

// MARK: - Background Brightness (Environment-Based)

/// Dims the view it is attached to according to the current settings — meant
/// for DESIGNATED BACKGROUND layers only, per the `Settings` model rule:
/// brightness must not darken foreground objects, controls, or text.
///
/// Attach it to each screen's background view (and the settings preview
/// image, which exists to demonstrate the effect):
///
///     MainMenuBackground()
///         .appBackgroundBrightness()
private struct AppBackgroundBrightness: ViewModifier {

    /// The shared settings logic, injected via `environmentObject`.
    @EnvironmentObject private var settingsViewModel: SettingsViewModel

    func body(content: Content) -> some View {
        content.backgroundBrightness(
            settingsViewModel.activeDisplaySettings.backgroundBrightness
        )
    }
}

extension View {

    /// Dims this view per the "Kecerahan Latar Belakang" setting, reading the
    /// shared `SettingsViewModel` from the environment.
    ///
    /// Apply to designated BACKGROUND views only — foreground content
    /// (controls, text, illustrations) must stay at full brightness, per the
    /// `Settings` model rule.
    ///
    /// - Returns: The dimmed background view.
    func appBackgroundBrightness() -> some View {
        modifier(AppBackgroundBrightness())
    }
}

extension View {

    /// Applies the app's current display settings (brightness, color filter,
    /// text size) to this view, using the `SettingsViewModel` from the
    /// environment.
    ///
    /// Apply this at EACH SCREEN'S root, inside any `NavigationStack` — never
    /// around one. Navigation containers are UIKit-backed, and wrapping them in
    /// the color shader makes SwiftUI render a yellow "no entry" placeholder
    /// instead of the app.
    ///
    /// Pass `includeColorFilter: false` for screens that contain UIKit-backed
    /// views (e.g. `StatisticsView` with its `ScrollView`): they still get
    /// brightness and text size, and skip only the shader.
    ///
    /// Requires `.environmentObject(_: SettingsViewModel)` to have been
    /// injected by an ancestor (the app root does this; previews must inject
    /// their own).
    ///
    /// - Parameter includeColorFilter: Whether to include the color-vision
    ///   shader; default `true`.
    /// - Returns: The view with the app-wide adjustments applied.
    func appDisplayAdjustments(includeColorFilter: Bool = true) -> some View {
        modifier(AppDisplayAdjustments(includesColorFilter: includeColorFilter))
    }
}

// MARK: - Simulation Matrices

extension ColorVisionSimulation {

    /// The identity matrix — leaves every pixel unchanged. Used by
    /// `colorVisionFilter(_:)` when no simulation is active, so the shader can
    /// stay permanently attached (keeping the view tree's identity stable)
    /// without altering colors.
    static let identityMatrix: [Float] = [
        1, 0, 0,
        0, 1, 0,
        0, 0, 1
    ]

    /// The row-major 3x3 RGB matrix that simulates this color-vision deficiency
    /// at full severity (Machado, Oliveira & Fernandes, 2009 — the matrices
    /// commonly used for CVD simulation, including by accessibility tooling).
    ///
    /// Consumed by `View.colorVisionFilter(_:)`, which hands the 9 floats to
    /// the `colorVisionFilter` Metal function.
    var simulationMatrix: [Float] {
        switch self {
        case .protanopia:
            return [
                0.152286, 1.052583, -0.204868,
                0.114503, 0.786281, 0.099216,
                -0.003882, -0.048116, 1.051998
            ]

        case .deuteranopia:
            return [
                0.367322, 0.860646, -0.227968,
                0.280085, 0.672501, 0.047413,
                -0.011820, 0.042940, 0.968881
            ]

        case .tritanopia:
            return [
                1.255528, -0.076749, -0.178779,
                -0.078411, 0.930809, 0.147602,
                0.004733, 0.691367, 0.303900
            ]
        }
    }
}

// MARK: - Helpers

private extension Double {
    /// Clamps the value into `range`; used to keep the dim overlay's opacity
    /// valid even if an out-of-range brightness slips through.
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

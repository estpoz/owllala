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
    @ViewBuilder
    func colorVisionFilter(_ simulation: ColorVisionSimulation?) -> some View {
        if let simulation {
            compositingGroup()
                .colorEffect(
                    ShaderLibrary.colorVisionFilter(
                        .floatArray(simulation.simulationMatrix)
                    )
                )
        } else {
            self
        }
    }

    /// Applies both display adjustments from a `Settings` value in one call:
    /// the color-vision filter first, then the brightness dim on top.
    ///
    /// This is the one modifier a screen's root should reach for:
    ///
    ///     SomeScreen()
    ///         .displayAdjustments(for: storageService.settings)
    ///
    /// ⚠️ The screen must be built from SwiftUI-drawn views only (no
    /// `ScrollView`, no system `Slider`/`Toggle`, no representables), otherwise
    /// those views vanish under the shader — see `colorVisionFilter(_:)`.
    ///
    /// - Parameter settings: The settings whose brightness and filter to apply.
    /// - Returns: The adjusted view.
    func displayAdjustments(for settings: Settings) -> some View {
        colorVisionFilter(settings.colorVisionSimulation)
            .backgroundBrightness(settings.backgroundBrightness)
    }
}

// MARK: - Simulation Matrices

extension ColorVisionSimulation {

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

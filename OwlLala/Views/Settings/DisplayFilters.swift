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
//  `ContentView` injects one shared settings source. Navigation destinations
//  are adjusted at centralized choke points, standalone screens use
//  `AppScreen`, and scrolling screens use `AppScrollScreen` or
//  `AppFilteredScrollView`. Backgrounds use `appBackgroundAdjustments()`.
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

// MARK: - Display Filter Scope

/// Tracks whether an ancestor already owns the screen-level color filter.
/// Descendant backgrounds and scroll content use this to avoid applying the
/// simulation matrix twice.
private struct AppColorFilterIsAppliedKey: EnvironmentKey {
    static let defaultValue = false
}

private extension EnvironmentValues {
    var appColorFilterIsApplied: Bool {
        get { self[AppColorFilterIsAppliedKey.self] }
        set { self[AppColorFilterIsAppliedKey.self] = newValue }
    }
}

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

    /// Scales the app's text using BOTH the device's Dynamic Type (iOS Settings
    /// › Larger Text) and the in-game "Ukuran Teks" setting — whichever is
    /// larger wins.
    ///
    /// The device size arrives as the incoming environment value; the in-game
    /// setting can only raise it, and only inside the app. So the device's text
    /// size affects the app (and the whole system), while the in-game setting
    /// affects only the app — never the device.
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
            dynamicTypeSize = max(dynamicTypeSize, settings.preferredDynamicTypeSize)
        }
    }
}

// MARK: - Text Scale Mapping

extension Settings {

    /// The native Dynamic Type size matching the saved app preference.
    ///
    /// Lives here rather than in the model because `DynamicTypeSize` is a
    /// SwiftUI type and the Models layer stays UI-framework-free.
    var preferredDynamicTypeSize: DynamicTypeSize {
        switch textSize {
        case .extraSmall:
            return .xSmall
        case .small:
            return .small
        case .medium:
            return .medium
        case .large:
            return .large
        case .extraLarge:
            return .xLarge
        case .extraExtraLarge:
            return .xxLarge
        case .extraExtraExtraLarge:
            return .xxxLarge
        case .accessibility1:
            return .accessibility1
        case .accessibility2:
            return .accessibility2
        case .accessibility3:
            return .accessibility3
        case .accessibility4:
            return .accessibility4
        case .accessibility5:
            return .accessibility5
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
                .environment(\.appColorFilterIsApplied, true)
        } else {
            // Text size is environment based, so it is always safe — only the
            // shader needs rasterizable content.
            content
                .textSizeAdjustment(for: settings)
                .environment(\.appColorFilterIsApplied, false)
        }
    }
}

/// Applies the current color filter only when no ancestor already owns it.
/// This is used for pure-SwiftUI islands inside screens whose `ScrollView`
/// prevents a shader from being attached at the screen root.
private struct AppAdaptiveColorFilter: ViewModifier {

    @Environment(\.appColorFilterIsApplied) private var isAppliedByAncestor
    @EnvironmentObject private var settingsViewModel: SettingsViewModel

    func body(content: Content) -> some View {
        content
            .colorVisionFilter(
                isAppliedByAncestor
                    ? nil
                    : settingsViewModel.activeDisplaySettings.colorVisionSimulation
            )
            .environment(\.appColorFilterIsApplied, true)
    }
}

// MARK: - Background Brightness (Environment-Based)

/// Dims the view it is attached to according to the current settings — meant
/// for DESIGNATED BACKGROUND layers only, per the `Settings` model rule:
/// brightness must not darken foreground objects, controls, or text.
///
/// Used internally by `appBackgroundAdjustments()` so feature screens cannot
/// accidentally apply brightness without also participating in color filtering.
///
///     MainMenuBackground()
///         .appBackgroundAdjustments()
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

    /// Applies every setting that belongs to a screen background: background
    /// brightness plus the active color-vision simulation. The adaptive color
    /// filter guarantees the matrix runs exactly once even when the screen is
    /// already wrapped by the navigation-level filter.
    func appBackgroundAdjustments() -> some View {
        modifier(AppBackgroundBrightness())
            .modifier(AppAdaptiveColorFilter())
    }

    /// Applies the active color simulation to a pure-SwiftUI subtree only when
    /// an ancestor has not already applied it. Use this for fixed content next
    /// to an `AppFilteredScrollView`.
    func appAdaptiveColorFilter() -> some View {
        modifier(AppAdaptiveColorFilter())
    }

    /// Starts a new color-filter ownership boundary for content presented by
    /// UIKit outside the source screen's render layer, such as a transparent
    /// `fullScreenCover`. The presented Settings surface can then apply its
    /// own standard or accessibility-safe filtering exactly once.
    func appIndependentColorFilterScope() -> some View {
        environment(\.appColorFilterIsApplied, false)
    }
}

extension View {

    /// Applies the app's current color filter and text size to this view, using
    /// the `SettingsViewModel` from the environment. Background brightness is
    /// centralized separately by `AppScreen` / `appBackgroundAdjustments()`.
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

// MARK: - Standard Screen Containers

/// The standard root for a new non-scrolling screen. It centralizes background
/// brightness and color filtering so feature views contain no settings logic.
/// Screens routed through an already-adjusted navigation destination remain
/// safe because the adaptive filter prevents double application.
struct AppScreen<Background: View, Content: View>: View {

    private let background: Background
    private let content: Content

    init(
        @ViewBuilder background: () -> Background,
        @ViewBuilder content: () -> Content
    ) {
        self.background = background()
        self.content = content()
    }

    var body: some View {
        ZStack {
            background
                .appBackgroundAdjustments()

            content
        }
        .appAdaptiveColorFilter()
    }
}

/// A centralized scroll container for screens that participate in the app's
/// display settings. The UIKit-backed `ScrollView` stays outside the shader;
/// its pure SwiftUI content is filtered inside, and the navigation layer is
/// notified not to wrap the scroll view itself.
struct AppFilteredScrollView<Content: View>: View {

    private let axes: Axis.Set
    private let showsIndicators: Bool
    private let appliesColorFilter: Bool
    private let content: Content

    init(
        _ axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        appliesColorFilter: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.appliesColorFilter = appliesColorFilter
        self.content = content()
    }

    var body: some View {
        ScrollView(axes, showsIndicators: showsIndicators) {
            Group {
                if appliesColorFilter {
                    content
                        .appAdaptiveColorFilter()
                } else {
                    content
                }
            }
        }
        .screenContainsScrollingContent()
    }
}

/// The standard root for a new scrolling screen. Future scrolling screens use
/// this container instead of composing a raw `ScrollView`, which guarantees
/// their background and scroll content inherit the shared saved settings.
struct AppScrollScreen<Background: View, Content: View>: View {

    private let axes: Axis.Set
    private let showsIndicators: Bool
    private let appliesColorFilterToContent: Bool
    private let background: Background
    private let content: Content

    init(
        _ axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        appliesColorFilterToContent: Bool = true,
        @ViewBuilder background: () -> Background,
        @ViewBuilder content: () -> Content
    ) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.appliesColorFilterToContent = appliesColorFilterToContent
        self.background = background()
        self.content = content()
    }

    var body: some View {
        ZStack {
            background
                .appBackgroundAdjustments()

            AppFilteredScrollView(
                axes,
                showsIndicators: showsIndicators,
                appliesColorFilter: appliesColorFilterToContent
            ) {
                content
            }
        }
    }
}

// MARK: - Automatic Adjustments (Choke-Point Based)

/// Preference through which a screen tells the navigation layer that it
/// contains scrolling (UIKit-backed) content, so the automatic wrapper skips
/// the color shader for it (the shader can't rasterize UIKit views).
private struct SkipColorFilterPreferenceKey: PreferenceKey {
    static let defaultValue = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

/// Applies the display adjustments automatically, adapting to the screen's
/// declared content: full adjustments by default, shader skipped when the
/// screen declares scrolling content via `screenContainsScrollingContent()`.
private struct AutoDisplayAdjustments: ViewModifier {

    /// Whether the wrapped screen declared UIKit-backed scrolling content.
    @State private var skipsColorFilter = false

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(SkipColorFilterPreferenceKey.self) { skipsColorFilter = $0 }
            .appDisplayAdjustments(includeColorFilter: !skipsColorFilter)
    }
}

extension View {

    /// AUTOMATION ENTRY POINT — apply this once at each navigation choke point
    /// (the `navigationDestination` closures in `MainMenuView`), and every
    /// screen presented through it gets the display adjustments with ZERO
    /// lines in the screen itself:
    ///
    ///     .navigationDestination(item: $vm.destination) { destination in
    ///         destinationView(for: destination)
    ///             .autoDisplayAdjustments()
    ///     }
    ///
    /// `AppFilteredScrollView` declares UIKit-backed scrolling automatically,
    /// so the outer shader steps aside while its inner SwiftUI content and
    /// adjusted background continue to receive every saved setting.
    ///
    /// Do NOT also apply `appDisplayAdjustments()` inside a screen presented
    /// through a wrapped choke point — the color matrix would run twice.
    ///
    /// - Returns: The destination with automatic adjustments.
    func autoDisplayAdjustments() -> some View {
        modifier(AutoDisplayAdjustments())
    }

    /// Internal declaration used by `AppFilteredScrollView`. Feature screens
    /// should use the centralized scroll container instead of calling this
    /// method or constructing a raw `ScrollView`.
    fileprivate func screenContainsScrollingContent() -> some View {
        preference(key: SkipColorFilterPreferenceKey.self, value: true)
    }

    /// Applies ONLY the text-size setting, reading the shared
    /// `SettingsViewModel` from the environment. Environment values propagate
    /// through `NavigationStack` into every pushed screen, so applying this
    /// once at the app root covers text sizing everywhere — even screens that
    /// escape the navigation choke points.
    ///
    /// - Returns: The view with the app's text scale applied.
    func appTextSizeAdjustment() -> some View {
        modifier(AppTextSizeAdjustment())
    }
}

/// Implementation of `appTextSizeAdjustment()`.
private struct AppTextSizeAdjustment: ViewModifier {

    /// The shared settings logic, injected via `environmentObject`.
    @EnvironmentObject private var settingsViewModel: SettingsViewModel

    func body(content: Content) -> some View {
        content.textSizeAdjustment(for: settingsViewModel.activeDisplaySettings)
    }
}

// MARK: - Standard Backgrounds (Self-Dimming)

/// The app's standard screen backgrounds, with brightness and adaptive color
/// filtering built in. A new screen that uses `AppBackground` never has to
/// wire settings modifiers itself:
///
///     ZStack {
///         AppBackground(style: .pattern)   // dims automatically
///         ...screen content...             // stays full-bright
///     }
struct AppBackground: View {

    /// The available standard background looks.
    enum Style {
        /// The flat pale backdrop used by story selection and gameplay.
        case flat
        /// The "PatternBG" illustration used by chapter selection & training.
        case pattern
    }

    /// The chosen look; defaults to the flat backdrop.
    var style: Style = .flat

    var body: some View {
        Group {
            switch style {
            case .flat:
                Color(red: 0.937, green: 0.953, blue: 0.957)

            case .pattern:
                Image("PatternBG")
                    .resizable()
                    .scaledToFill()
            }
        }
        .ignoresSafeArea()
        .appBackgroundAdjustments()
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

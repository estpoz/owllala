//
//  Buttons.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//
//  OVERVIEW
//  --------
//  Reusable, presentation-only building blocks for the Settings feature, plus
//  the two small button styles they are built from. Everything here is "dumb
//  UI": no view owns persistent state — values come in through `@Binding`s and
//  user intent goes out through closures, so the same views work in the app,
//  in previews, and in tests.
//
//  WHAT'S IN THIS FILE
//  -------------------
//  • `CircleIconButton`   — round blue icon button (back / close).
//  • `PrimaryActionButton`— filled blue "Simpan"-style confirmation button.
//  • `SettingsScreen`     — full-screen settings page (main menu → Settings).
//  • `SettingsOverlay`    — the same settings content as a modal over gameplay.
//  • `SettingsPanelBody`  — private shared body used by the two settings views
//                           so they can never drift apart visually.
//
//  WHERE THESE ARE USED
//  --------------------
//  Intended integration (the `Views/` files are still stubs, so these are the
//  planned call sites, not existing ones):
//   • `SettingsScreen`  → hosted by `Views/Settings/SettingsView`, reached from
//     `MainMenuViewModel.Destination.settings`.
//   • `SettingsOverlay` → hosted by `Views/Settings/SettingsModalView`, shown as
//     an overlay during a chapter mini-game.
//  Both are designed to be driven by `SettingsViewModel`: bind its
//  `draftSettings` fields in, call `save()`/`cancel()` from the callbacks.
//
//  DEPENDENCIES
//  ------------
//  Reads `ColorVisionSimulation` and `Settings` (brightness bounds) from the
//  Models layer. Writes nothing directly — persistence is the caller's job.
//

import SwiftUI

// MARK: - Shared Palette

/// The OwlLala brand blue, shared by every control in this file (button fills,
/// selected states, borders). File-scoped so all the settings UI stays on one
/// color; kept in sync with the same value in `ExitConfirmation.swift`.
private let primaryBlue = Color(red: 0.02, green: 0.28, blue: 0.70)

// MARK: - Circle Icon Button

/// A round, blue, filled icon button used for the navigation controls in the
/// settings views — the back arrow on `SettingsScreen` and the close (✕) on
/// `SettingsOverlay`.
///
/// Icon-only by design, so it takes an explicit `accessibilityLabel` rather
/// than relying on the SF Symbol name. Scales with Dynamic Type.
struct CircleIconButton: View {
    /// SF Symbol name to render (e.g. `"arrow.left"`, `"xmark"`).
    let systemImageName: String
    /// Spoken label for VoiceOver, since the button shows no text.
    let accessibilityLabel: String
    /// Invoked on tap.
    let action: () -> Void

    /// Grows the icon and its circular background with the user's text size.
    @ScaledMetric(relativeTo: .title) private var buttonScale: CGFloat = 1

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImageName)
                .font(.system(size: 26 * buttonScale, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 64 * buttonScale, height: 64 * buttonScale)
                .background(primaryBlue, in: Circle())
        }
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - Primary Action Button

/// The filled, rounded-rectangle blue button used for the main confirmation
/// action on a panel — currently the "Simpan" (Save) button in the settings
/// views. Scales with Dynamic Type.
struct PrimaryActionButton: View {
    /// The button's label text.
    let title: String
    /// Invoked on tap.
    let action: () -> Void

    /// Grows the label and the button's minimum height with the text size.
    @ScaledMetric(relativeTo: .title2) private var buttonScale: CGFloat = 1

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 24 * buttonScale, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 56 * buttonScale)
                .frame(minHeight: 60 * buttonScale)
                .background(primaryBlue)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

// MARK: - Settings Screen

/// The full-screen settings page opened from the main menu's settings button.
///
/// Lays the shared `SettingsPanelBody` on a plain white background and pins a
/// back-arrow `CircleIconButton` to the top-left.
///
/// Presentation only: the host supplies the draft values through the bindings
/// and reacts to the callbacks — typically wired to `SettingsViewModel` like:
///
///     SettingsScreen(
///         brightness: $viewModel.draftSettings.backgroundBrightness,
///         colorVisionSimulation: $viewModel.draftSettings.colorVisionSimulation,
///         onSave: { viewModel.save() },
///         onBack: { viewModel.cancel() }
///     )
struct SettingsScreen: View {
    /// Background-brightness draft value, bound to the caller's state/model.
    @Binding var brightness: Double
    /// Selected color-vision filter (`nil` = filter off), bound to the caller.
    @Binding var colorVisionSimulation: ColorVisionSimulation?
    /// Asset-catalog name of the preview image; defaults to the `settingReference` asset.
    var previewImageAssetName: String = "settingReference"
    /// Invoked when the child taps "Simpan" — the host should persist the draft.
    let onSave: () -> Void
    /// Invoked when the child taps the back arrow — the host should dismiss.
    let onBack: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white
                .ignoresSafeArea()

            SettingsPanelBody(
                brightness: $brightness,
                colorVisionSimulation: $colorVisionSimulation,
                previewImageAssetName: previewImageAssetName,
                saveTitle: "Simpan",
                onSave: onSave
            )

            CircleIconButton(
                systemImageName: "arrow.left",
                accessibilityLabel: "Kembali",
                action: onBack
            )
            .padding(24)
        }
    }
}

// MARK: - Settings Overlay

/// The same settings content as `SettingsScreen`, presented as a modal card on
/// a dimmed backdrop — meant to be shown over a chapter mini-game.
///
/// Sizes the card relative to the available space, adds a close (✕)
/// `CircleIconButton` in the corner, and matches `ExitConfirmation`'s scrim and
/// shadow so all in-game modals feel consistent.
///
/// Presentation only, like `SettingsScreen`; wire it to `SettingsViewModel` and
/// use `onClose` for the dismiss/cancel path.
struct SettingsOverlay: View {
    /// Background-brightness draft value, bound to the caller's state/model.
    @Binding var brightness: Double
    /// Selected color-vision filter (`nil` = filter off), bound to the caller.
    @Binding var colorVisionSimulation: ColorVisionSimulation?
    /// Asset-catalog name of the preview image; defaults to the `settingReference` asset.
    var previewImageAssetName: String = "settingReference"
    /// Invoked when the child taps "Simpan" — the host should persist the draft.
    let onSave: () -> Void
    /// Invoked when the child taps ✕ — the host should dismiss the overlay.
    let onClose: () -> Void

    var body: some View {
        // Size the card from the space it's presented in (capped so it doesn't
        // grow unbounded on large screens).
        GeometryReader { geometry in
            let panelWidth = min(geometry.size.width * 0.82, 900)
            let panelHeight = min(geometry.size.height * 0.86, 720)

            ZStack {
                // Dimmed backdrop over the game behind the card.
                Color.black
                    .opacity(0.36)
                    .ignoresSafeArea()

                // The white card: shared body + corner close button.
                ZStack(alignment: .topLeading) {
                    SettingsPanelBody(
                        brightness: $brightness,
                        colorVisionSimulation: $colorVisionSimulation,
                        previewImageAssetName: previewImageAssetName,
                        saveTitle: "Simpan",
                        onSave: onSave
                    )

                    CircleIconButton(
                        systemImageName: "xmark",
                        accessibilityLabel: "Tutup",
                        action: onClose
                    )
                    .padding(20)
                }
                .frame(width: panelWidth, height: panelHeight)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 28, x: 0, y: 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Shared Panel Body

/// The settings content shared by `SettingsScreen` and `SettingsOverlay`:
/// the "Pengaturan" title, the brightness slider, the color-filter toggle and
/// its three options, the preview image, and the save button.
///
/// Extracting this into one private view is the reason the full-screen page and
/// the in-game overlay always match — there is a single source of truth for the
/// layout. It is `private` because only the two settings views in this file use
/// it.
private struct SettingsPanelBody: View {
    /// Background-brightness draft, forwarded from the hosting view.
    @Binding var brightness: Double
    /// Selected color-vision filter (`nil` = off), forwarded from the host.
    @Binding var colorVisionSimulation: ColorVisionSimulation?
    /// Asset name of the preview image to display.
    let previewImageAssetName: String
    /// Label for the confirmation button (e.g. "Simpan").
    let saveTitle: String
    /// Invoked when the confirmation button is tapped.
    let onSave: () -> Void

    /// Whether the color filter section is turned on. Local UI state only: it is
    /// initialized from `colorVisionSimulation` in `onAppear` and, when turned
    /// off, clears the bound `colorVisionSimulation` back to `nil`.
    @State private var isFilterEnabled = false

    /// Dynamic Type multipliers for the title and for the body labels/controls.
    @ScaledMetric(relativeTo: .largeTitle) private var titleScale: CGFloat = 1
    @ScaledMetric(relativeTo: .title3) private var labelScale: CGFloat = 1

    var body: some View {
        VStack(spacing: 0) {
            // Screen/card title.
            Text("Pengaturan")
                .font(.system(size: 52 * titleScale, weight: .bold))
                .foregroundStyle(.black)
                .padding(.top, 28)

            ScrollView {
                // Side-by-side (controls | image) when there's width; stacks
                // vertically when narrow. `ScrollView` keeps everything
                // reachable at large text sizes.
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 48) {
                        controls
                            .frame(maxWidth: 460, alignment: .leading)

                        previewImage
                    }
                    .padding(.horizontal, 56)

                    VStack(alignment: .leading, spacing: 32) {
                        controls
                        previewImage
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.top, 44)
            }

            // Save action, shared style from `PrimaryActionButton`.
            PrimaryActionButton(title: saveTitle, action: onSave)
                .padding(.vertical, 28)
        }
        // Sync the local toggle with the incoming filter value on first show.
        .onAppear {
            isFilterEnabled = colorVisionSimulation != nil
        }
    }

    /// The left column: brightness label + slider, the "Filter Warna" toggle,
    /// and the row of color-vision options.
    private var controls: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Kecerahan Latar Belakang")
                .font(.system(size: 24 * labelScale, weight: .bold))
                .foregroundStyle(.black)

            // Brightness slider, bounded by the Settings model's supported
            // range so the UI can never produce an out-of-range value.
            HStack(spacing: 14) {
                Image(systemName: "sun.min")
                    .font(.system(size: 20 * labelScale, weight: .semibold))
                    .foregroundStyle(.black)

                Slider(
                    value: $brightness,
                    in: Settings.minimumBackgroundBrightness...Settings.maximumBackgroundBrightness
                )
                .tint(.blue)
                .accessibilityLabel("Kecerahan Latar Belakang")

                Image(systemName: "sun.max")
                    .font(.system(size: 26 * labelScale, weight: .semibold))
                    .foregroundStyle(.black)
            }

            // Color-filter on/off. Turning it off clears any chosen simulation.
            HStack(spacing: 16) {
                Text("Filter Warna")
                    .font(.system(size: 24 * labelScale, weight: .bold))
                    .foregroundStyle(.black)

                Toggle("", isOn: $isFilterEnabled)
                    .labelsHidden()
                    .accessibilityLabel("Filter Warna")
                    .onChange(of: isFilterEnabled) { _, isEnabled in
                        if !isEnabled {
                            colorVisionSimulation = nil
                        }
                    }
            }
            .padding(.top, 6)

            // One radio option per simulation type, driven by the model enum.
            HStack(spacing: 26) {
                ForEach(ColorVisionSimulation.allCases) { simulation in
                    simulationOption(simulation)
                }
            }
            .padding(.top, 2)
        }
    }

    /// Builds one selectable color-vision option (radio dot + label).
    ///
    /// Disabled and greyed while `isFilterEnabled` is false; shows the filled
    /// blue dot only for the currently selected simulation. Tapping it sets the
    /// bound `colorVisionSimulation`.
    ///
    /// - Parameter simulation: The `ColorVisionSimulation` this option selects.
    /// - Returns: The option view for use inside the options row.
    private func simulationOption(_ simulation: ColorVisionSimulation) -> some View {
        let isSelected = colorVisionSimulation == simulation

        return Button {
            colorVisionSimulation = simulation
        } label: {
            HStack(spacing: 8) {
                // Radio indicator: grey base, with a blue/white dot on top when
                // this option is the active selection.
                ZStack {
                    Circle()
                        .fill(Color(white: 0.78))
                        .frame(width: 22 * labelScale, height: 22 * labelScale)

                    if isSelected && isFilterEnabled {
                        Circle()
                            .fill(primaryBlue)
                            .frame(width: 22 * labelScale, height: 22 * labelScale)
                        Circle()
                            .fill(.white)
                            .frame(width: 8 * labelScale, height: 8 * labelScale)
                    }
                }

                Text(simulation.displayName)
                    .font(.system(size: 20 * labelScale, weight: .semibold))
                    .foregroundStyle(
                        isFilterEnabled
                            ? (isSelected ? primaryBlue : .black)
                            : Color(white: 0.72)
                    )
            }
        }
        .disabled(!isFilterEnabled)
        .accessibilityLabel(simulation.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// The preview image shown next to the controls.
    ///
    /// Loads the asset named `previewImageAssetName` (default: `settingReference`).
    /// If the asset is missing — or on non-UIKit platforms, e.g. macOS previews —
    /// it falls back to `previewPlaceholder` so the layout never breaks. Framed
    /// at a 3:2 aspect ratio to match the source artwork.
    @ViewBuilder
    private var previewImage: some View {
        Group {
            #if canImport(UIKit)
            if let uiImage = UIImage(named: previewImageAssetName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                previewPlaceholder
            }
            #else
            previewPlaceholder
            #endif
        }
        .frame(maxWidth: 420)
        .aspectRatio(3 / 2, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityLabel("Pratinjau kecerahan latar belakang")
    }

    /// A colorful gradient stand-in used when the real preview asset can't be
    /// loaded, so the settings panel still looks intentional in that case.
    private var previewPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.55, blue: 0.25),
                    Color(red: 0.90, green: 0.30, blue: 0.35),
                    Color(red: 0.25, green: 0.60, blue: 0.45),
                    Color(red: 0.20, green: 0.40, blue: 0.75)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "photo")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(.white.opacity(0.85))
        }
    }
}

// MARK: - Previews

// Xcode-canvas previews only; each uses `@Previewable @State` to stand in for
// the values a real host (or `SettingsViewModel`) would provide.

#Preview("Settings Screen") {
    @Previewable @State var brightness = 0.8
    @Previewable @State var simulation: ColorVisionSimulation?

    SettingsScreen(
        brightness: $brightness,
        colorVisionSimulation: $simulation,
        onSave: {},
        onBack: {}
    )
}

#Preview("Settings Overlay") {
    @Previewable @State var brightness = 0.8
    @Previewable @State var simulation: ColorVisionSimulation?

    ZStack {
        Color(white: 0.85)
            .ignoresSafeArea()

        SettingsOverlay(
            brightness: $brightness,
            colorVisionSimulation: $simulation,
            onSave: {},
            onClose: {}
        )
    }
}

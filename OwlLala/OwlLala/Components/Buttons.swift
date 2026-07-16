//
//  Buttons.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//
//  OVERVIEW
//  --------
//  Small reusable buttons. The settings *content* does not live here: its
//  logic is in `ViewModels/SettingsViewModel.swift` and its screens are in
//  `Views/Settings/SettingsView.swift` (main menu) and
//  `Views/Settings/SettingsModalView.swift` (gameplay overlay).
//
//  WHAT'S IN THIS FILE
//  -------------------
//  • `CircleIconButton`    — round blue icon button (back / close / gear).
//  • `PrimaryActionButton` — filled blue "Simpan"-style confirmation button.
//  • `SettingsButton`      — the gear entry point into Settings.
//
//  HOW SETTINGS ARE PRESENTED
//  --------------------------
//  `SettingsButton` only *triggers* — the host presents the settings screen as
//  an in-tree overlay (see `MainMenuView` for the pattern). Presentation must
//  stay in-tree (no `fullScreenCover`): covers render in a separate layer that
//  escapes the root `displayAdjustments(for:)` in `ContentView`, which is what
//  applies brightness and the color filter to every view in the app.
//

import SwiftUI

// MARK: - Shared Palette

/// The OwlLala brand blue (#0042AA), from the shared theme (`AppTheme.swift`).
private let primaryBlue = AppColor.primary

// MARK: - Circle Icon Button

/// A round, blue, filled icon button used for navigation controls — the back
/// arrow and close (✕) in the settings views, and the gear in `SettingsButton`.
///
/// Icon-only by design, so it takes an explicit `accessibilityLabel` rather
/// than relying on the SF Symbol name. Scales with Dynamic Type.
struct CircleIconButton: View {

    /// SF Symbol name to render (e.g. `"arrow.left"`, `"xmark"`, `"gearshape.fill"`).
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
/// action on a panel — e.g. the "Simpan" (Save) button in the settings views.
/// Scales with Dynamic Type.
struct PrimaryActionButton: View {

    /// The button's label text.
    let title: String

    /// Invoked on tap.
    let action: () -> Void

    /// Grows the label and the button's minimum height with the text size.
    @ScaledMetric(relativeTo: .title2) private var buttonScale: CGFloat = 1

    var body: some View {
        Button(action: action) {
            // Button — SF Pro Rounded 44pt Bold, per the shared type scale.
            Text(title)
                .font(.owlRounded(AppFontSize.button * buttonScale, .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 48 * buttonScale)
                .frame(minHeight: 72 * buttonScale)
                .background(primaryBlue)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

// MARK: - Settings Button

/// The gear button that opens Settings.
///
/// It only reports the tap — the host decides how to present the settings
/// screen, keeping it inside the app's single view tree so the root display
/// adjustments cover it. Typical gameplay usage:
///
///     @State private var isShowingSettings = false
///
///     SettingsButton { isShowingSettings = true }
///
///     // In the screen's ZStack:
///     if isShowingSettings {
///         SettingsModalView(viewModel: settingsViewModel) {
///             isShowingSettings = false
///         }
///     }
///
/// (`MainMenuView` drives the same pattern through
/// `MainMenuViewModel.Destination.settings` instead of local state.)
struct SettingsButton: View {

    /// Invoked on tap; the host presents the settings screen.
    let action: () -> Void

    var body: some View {
        CircleIconButton(
            systemImageName: "gearshape.fill",
            accessibilityLabel: "Pengaturan",
            action: action
        )
    }
}

// MARK: - Previews

#Preview("Buttons") {
    VStack(spacing: 32) {
        SettingsButton {}

        CircleIconButton(
            systemImageName: "arrow.left",
            accessibilityLabel: "Kembali"
        ) {}

        PrimaryActionButton(title: "Simpan") {}
    }
}

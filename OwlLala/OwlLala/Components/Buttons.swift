//
//  Buttons.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//
//  OVERVIEW
//  --------
//  Small reusable buttons. The settings *content* does not live here anymore:
//  its logic is in `ViewModels/SettingsViewModel.swift` and its screens are in
//  `Views/Settings/SettingsView.swift` (main menu) and
//  `Views/Settings/SettingsModalView.swift` (gameplay overlay). This file only
//  provides the entry-point buttons that present those views, plus the two
//  generic button styles they share.
//
//  WHAT'S IN THIS FILE
//  -------------------
//  • `CircleIconButton`      — round blue icon button (back / close / gear).
//  • `PrimaryActionButton`   — filled blue "Simpan"-style confirmation button.
//  • `SettingsButton`        — gear button for the MAIN MENU; presents the
//                              full-screen `SettingsView`.
//  • `SettingsOverlayButton` — gear button for GAMEPLAY; presents the
//                              `SettingsModalView` overlay on a clear cover so
//                              the game stays visible behind the dimmed card.
//
//  WHERE THESE ARE USED
//  --------------------
//  • `SettingsButton` → place on the main menu (e.g. `MainMenuView`).
//  • `SettingsOverlayButton` → place on the gameplay screens' HUD.
//  Both need only the shared `StorageService`; each presented view creates its
//  own `SettingsViewModel` from it.
//

import SwiftUI

// MARK: - Shared Palette

/// The OwlLala brand blue, shared by the buttons in this file. Kept in sync
/// with the same value in `ExitConfirmation.swift` and `SettingsView.swift`.
private let primaryBlue = Color(red: 0.02, green: 0.28, blue: 0.70)

// MARK: - Circle Icon Button

/// A round, blue, filled icon button used for navigation controls — the back
/// arrow and close (✕) in the settings views, and the gear in the settings
/// entry buttons below.
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

// MARK: - Settings Button (Main Menu)

/// The gear button that opens Settings from the MAIN MENU.
///
/// Self-contained: tapping it presents the full-screen `SettingsView` as a
/// cover. The host only supplies the shared `StorageService`:
///
///     SettingsButton(storageService: storageService)
struct SettingsButton: View {

    /// The app's shared storage; handed to `SettingsView`, which builds its
    /// own `SettingsViewModel` from it.
    let storageService: StorageService

    /// Whether the settings page is currently presented.
    @State private var isPresentingSettings = false

    var body: some View {
        CircleIconButton(
            systemImageName: "gearshape.fill",
            accessibilityLabel: "Pengaturan"
        ) {
            isPresentingSettings = true
        }
        .fullScreenCover(isPresented: $isPresentingSettings) {
            SettingsView(storageService: storageService)
        }
    }
}

// MARK: - Settings Overlay Button (Gameplay)

/// The gear button that opens the settings overlay DURING GAMEPLAY.
///
/// Self-contained like `SettingsButton`, but presents `SettingsModalView` on a
/// clear full-screen cover, so the modal's own dimmed scrim shows the paused
/// game behind the card:
///
///     SettingsOverlayButton(storageService: storageService)
struct SettingsOverlayButton: View {

    /// The app's shared storage; handed to `SettingsModalView`, which builds
    /// its own `SettingsViewModel` from it.
    let storageService: StorageService

    /// Whether the settings overlay is currently presented.
    @State private var isPresentingSettings = false

    var body: some View {
        CircleIconButton(
            systemImageName: "gearshape.fill",
            accessibilityLabel: "Pengaturan"
        ) {
            isPresentingSettings = true
        }
        .fullScreenCover(isPresented: $isPresentingSettings) {
            SettingsModalView(storageService: storageService)
                .presentationBackground(.clear)
        }
    }
}

// MARK: - Previews

#Preview("Settings Buttons") {
    HStack(spacing: 40) {
        SettingsButton(storageService: StorageService())
        SettingsOverlayButton(storageService: StorageService())
    }
}

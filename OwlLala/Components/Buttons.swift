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
//  • `CircleIconButton`    — round icon button (back / close / gear).
//  • `PrimaryActionButton` — filled blue "Simpan"-style confirmation button.
//  • `SettingsButton`      — the gear entry point into Settings.
//  • `GameplayTopBar`      — story-page exit, page count, sound, settings controls.
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

/// The OwlLala brand blue, shared by the buttons in this file. Kept in sync
/// with the same value in `ExitConfirmation.swift` and `SettingsView.swift`.
public let primaryBlue = Color(red: 0.02, green: 0.28, blue: 0.70)
public let gold = Color(red: 1.0, green: 0.78, blue: 0.16)
public let woodBrown = Color(red: 0.58, green: 0.38, blue: 0.22)
public let cream = Color(red: 0.99, green: 0.96, blue: 0.88)

// MARK: - Circle Icon Button

enum CircleIconButtonStyle {
    case filled
    case outlined
}

/// A round icon button used for navigation controls — the back arrow and close
/// (✕) in the settings views, and the gear in `SettingsButton`.
///
/// Icon-only by design, so it takes an explicit `accessibilityLabel` rather
/// than relying on the SF Symbol name.
struct CircleIconButton: View {

    /// SF Symbol name to render (e.g. `"arrow.left"`, `"xmark"`, `"gearshape.fill"`).
    let systemImageName: String

    /// Spoken label for VoiceOver, since the button shows no text.
    let accessibilityLabel: String

    /// Visual treatment for the circular button.
    var style: CircleIconButtonStyle = .filled

    /// Invoked on tap.
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImageName)
                .font(.system(size: 46, weight: .bold))
                .foregroundStyle(foregroundColor)
                .frame(width: 98, height: 98)
                .background(backgroundColor, in: Circle())
                .overlay(
                    Circle()
                        .stroke(borderColor, lineWidth: borderWidth)
                )
        }
        .accessibilityLabel(accessibilityLabel)
    }

    private var foregroundColor: Color {
        switch style {
        case .filled:
            return .white

        case .outlined:
            return primaryBlue
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .filled:
            return primaryBlue

        case .outlined:
            return .white
        }
    }

    private var borderColor: Color {
        switch style {
        case .filled:
            return .clear

        case .outlined:
            return primaryBlue
        }
    }

    private var borderWidth: CGFloat {
        switch style {
        case .filled:
            return 0

        case .outlined:
            return 6
        }
    }
}

// MARK: - Back Button

struct BackButton: View {

    var style: CircleIconButtonStyle = .filled
    let action: () -> Void

    var body: some View {
        CircleIconButton(
            systemImageName: "arrow.left",
            accessibilityLabel: "Kembali",
            style: style,
            action: action
        )
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
    @ScaledMetric(relativeTo: .title3) private var buttonScale: CGFloat = 1

    var body: some View {
        Button(action: action) {
            // Button — SF Pro Rounded 44pt Bold, per the shared type scale.
            Text(title)
//                .font(.system(size: 24 * buttonScale, weight: .semibold))
//                .foregroundStyle(.white)
//                .padding(.horizontal, 56 * buttonScale)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 30)
                .padding(.vertical, 16)
                .frame(minHeight: 20 * buttonScale)
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

    var style: CircleIconButtonStyle = .filled

    /// Invoked on tap; the host presents the settings screen.
    let action: () -> Void

    var body: some View {
        CircleIconButton(
            systemImageName: "gearshape.fill",
            accessibilityLabel: "Pengaturan",
            style: style,
            action: action
        )
    }
}

// MARK: - Gameplay Top Bar

/// The bundled control bar used at the top of gameplay story pages.
///
/// The host owns the behavior for exit, sound, and settings. Page progress is
/// passed in as display state so this component does not depend on a gameplay
/// view model or chapter model.
struct GameplayTopBar: View {

    let currentPage: Int
    let totalPages: Int
    let isVoiceOverEnabled: Bool
    let onShowExitConfirmation: () -> Void
    let onToggleVoiceOver: () -> Void
    let onShowSettings: () -> Void

    private let indicatorIconSize: CGFloat = 44
    private let indicatorTextSize: CGFloat = 46

    private var displayedCurrentPage: Int {
        min(max(currentPage, 1), displayedTotalPages)
    }

    private var displayedTotalPages: Int {
        max(totalPages, 1)
    }

    var body: some View {
        ZStack {
            HStack {
                GameplayTopBarButton(
                    systemImageName: "rectangle.portrait.and.arrow.right",
                    accessibilityLabel: "Keluar",
                    action: onShowExitConfirmation
                )

                Spacer()

                HStack(spacing: 28) {
                    GameplayTopBarButton(
                        systemImageName: isVoiceOverEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                        accessibilityLabel: isVoiceOverEnabled ? "Matikan narasi" : "Nyalakan narasi",
                        action: onToggleVoiceOver
                    )

                    GameplayTopBarButton(
                        systemImageName: "gearshape.fill",
                        accessibilityLabel: "Pengaturan",
                        action: onShowSettings
                    )
                }
            }

            pageIndicator
        }
        .accessibilityElement(children: .contain)
    }

    private var pageIndicator: some View {
        HStack(spacing: 18) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: indicatorIconSize, weight: .bold))
                .foregroundStyle(primaryBlue)
                .accessibilityHidden(true)

            Text("\(displayedCurrentPage) / \(displayedTotalPages)")
                .font(.system(size: indicatorTextSize, weight: .medium, design: .rounded))
                .foregroundStyle(primaryBlue)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Halaman \(displayedCurrentPage) dari \(displayedTotalPages)")
    }
}

private struct GameplayTopBarButton: View {

    let systemImageName: String
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImageName)
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(primaryBlue)
                .frame(width: 101, height: 101)
                .background(Color.white, in: Circle())
                .overlay(
                    Circle()
                        .stroke(primaryBlue, lineWidth: 6)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - Previews

#Preview("Buttons") {
    VStack(spacing: 32) {
        HStack(spacing: 24) {
            BackButton(style: .filled) {}
            BackButton(style: .outlined) {}
            SettingsButton(style: .filled) {}
            SettingsButton(style: .outlined) {}
        }

        PrimaryActionButton(title: "Simpan") {}

        GameplayTopBar(
            currentPage: 3,
            totalPages: 5,
            isVoiceOverEnabled: true,
            onShowExitConfirmation: {},
            onToggleVoiceOver: {},
            onShowSettings: {}
        )
        .frame(width: 900)
    }
    .padding()
}

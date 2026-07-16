//
//  SettingsModalView.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//
//  OVERVIEW
//  --------
//  The settings *overlay* shown during gameplay: the same panel as the
//  full-screen `SettingsView`, presented as a card over a dimmed scrim with a
//  close (✕) button instead of a back arrow.
//
//  All logic lives in `SettingsViewModel`; the panel itself is the shared
//  `SettingsPanelContent` (defined in `SettingsView.swift`), so the two
//  settings surfaces always have identical functions and can't drift apart.
//
//  WHERE IT IS USED
//  ----------------
//  Show it as an in-tree overlay from a gameplay screen's `ZStack` — NOT as a
//  `fullScreenCover` — so the root `displayAdjustments(for:)` in `ContentView`
//  keeps covering the whole app, and edits preview live on the paused game
//  behind the card:
//
//      ZStack {
//          GameplayContent(...)
//          if isShowingSettings {
//              SettingsModalView(viewModel: settingsViewModel) {
//                  isShowingSettings = false
//              }
//          }
//      }
//
//  The scrim/card sizing mirrors `ExitConfirmation` so all in-game modals feel
//  consistent.
//

import SwiftUI

// MARK: - Settings Modal View (Gameplay Overlay)

/// The gameplay settings overlay. Presentation only: every control calls into
/// the shared `SettingsViewModel`, and the host removes the overlay via
/// `onDismiss`.
struct SettingsModalView: View {

    /// The app-wide settings logic, shared through `ContentView` so the root
    /// can render `activeDisplaySettings` while this overlay edits the draft.
    @ObservedObject var viewModel: SettingsViewModel

    /// Invoked after save/close; the host removes this overlay from the tree.
    let onDismiss: () -> Void

    var body: some View {
        // Size the card from the available space, capped for large screens.
        GeometryReader { geometry in
            let panelWidth = min(geometry.size.width * 0.82, 900)
            let panelHeight = min(geometry.size.height * 0.86, 720)

            ZStack {
                // Dimmed backdrop over the game behind the card.
                Color.black
                    .opacity(0.36)
                    .ignoresSafeArea()

                // The white card: shared panel + corner close button.
                ZStack(alignment: .topLeading) {
                    SettingsPanelContent(viewModel: viewModel) {
                        viewModel.save()
                        onDismiss()
                    }

                    CircleIconButton(
                        systemImageName: "xmark",
                        accessibilityLabel: "Tutup"
                    ) {
                        viewModel.cancel()
                        onDismiss()
                    }
                    .padding(20)
                }
                .frame(width: panelWidth, height: panelHeight)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 28, x: 0, y: 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            viewModel.beginEditing()
        }
    }
}

// MARK: - Preview

#Preview("Settings Overlay") {
    ZStack {
        Color(white: 0.85)
            .ignoresSafeArea()

        SettingsModalView(
            viewModel: SettingsViewModel(storageService: StorageService()),
            onDismiss: {}
        )
    }
}

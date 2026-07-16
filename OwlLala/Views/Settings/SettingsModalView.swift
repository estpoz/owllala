//
//  SettingsModalView.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//
//  OVERVIEW
//  --------
//  The settings *overlay* shown during gameplay: the EXACT same settings page
//  as `SettingsView` (`SettingsSurface`, defined in SettingsView.swift),
//  presented as a rounded card over a dimmed scrim — so the modal can never
//  differ from the page; it is the page, in a modal state.
//
//  All logic lives in `SettingsViewModel`.
//
//  WHERE IT IS USED
//  ----------------
//  Show it as an in-tree overlay from a gameplay screen's `ZStack` — NOT as a
//  `fullScreenCover` — so the root display adjustments keep covering the whole
//  app, and edits preview live on the paused game behind the card:
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

    /// Invoked after save/back; the host removes this overlay from the tree.
    let onDismiss: () -> Void

    var body: some View {
        GeometryReader { geometry in
            // The card is a uniformly scaled-down copy of the FULL SCREEN: the
            // surface is laid out at the screen's size, then shrunk by one
            // factor, so the modal has exactly the same layout/proportions as
            // `SettingsView` — just adjusted to the card's size. The factor is
            // capped so the card never exceeds ~82% of the screen or 900pt.
            let cardWidth = min(geometry.size.width * 0.82, 900)
            let cardHeight = min(geometry.size.height * 0.86, 720)
            let scale = min(cardWidth / max(geometry.size.width, 1),
                            cardHeight / max(geometry.size.height, 1))

            ZStack {
                // Dimmed backdrop over the game behind the card.
                Color.black
                    .opacity(0.36)
                    .ignoresSafeArea()

                // The EXACT same surface as the full-screen settings page
                // (`SettingsSurface` in SettingsView.swift): full-screen
                // layout, uniformly scaled into the card. The larger
                // `saveBottomPadding` lifts the "Simpan" button higher than on
                // the full-screen page.
                SettingsSurface(
                    viewModel: viewModel,
                    saveBottomPadding: 96,
                    onDismiss: onDismiss
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                    .scaleEffect(scale, anchor: .center)
                    .frame(
                        width: geometry.size.width * scale,
                        height: geometry.size.height * scale
                    )
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
    let settingsViewModel = SettingsViewModel(storageService: StorageService())

    return ZStack {
        Color(white: 0.85)
            .ignoresSafeArea()

        SettingsModalView(viewModel: settingsViewModel, onDismiss: {})
    }
    .environmentObject(settingsViewModel)
}

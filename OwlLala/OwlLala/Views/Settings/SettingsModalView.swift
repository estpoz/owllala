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
//  Presented by `SettingsOverlayButton` (`Components/Buttons.swift`) from the
//  gameplay screens. The scrim/card sizing mirrors `ExitConfirmation` so all
//  in-game modals feel consistent.
//

import SwiftUI

// MARK: - Settings Modal View (Gameplay Overlay)

/// The gameplay settings overlay. Owns its `SettingsViewModel`, previews the
/// draft live on the card, and dismisses itself on save/close.
struct SettingsModalView: View {

    /// The settings logic; created from the shared storage instance.
    @StateObject private var viewModel: SettingsViewModel

    /// Dismisses the presentation (`fullScreenCover` from
    /// `SettingsOverlayButton`).
    @Environment(\.dismiss) private var dismiss

    /// Creates the overlay, building its view model from the app's storage.
    ///
    /// - Parameter storageService: The app's shared storage instance.
    init(storageService: StorageService) {
        _viewModel = StateObject(
            wrappedValue: SettingsViewModel(storageService: storageService)
        )
    }

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
                        dismiss()
                    }

                    CircleIconButton(
                        systemImageName: "xmark",
                        accessibilityLabel: "Tutup"
                    ) {
                        viewModel.cancel()
                        dismiss()
                    }
                    .padding(20)
                }
                .frame(width: panelWidth, height: panelHeight)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 28, x: 0, y: 16)
                // Live preview: the draft's adjustments apply to the card while
                // editing. The game behind keeps the saved settings.
                .displayAdjustments(for: viewModel.draftSettings)
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

        SettingsModalView(storageService: StorageService())
    }
}

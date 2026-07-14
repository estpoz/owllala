//
//  ContentView.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//
//  OVERVIEW
//  --------
//  Root view of the app. It owns the shared `StorageService` and currently
//  hosts the settings screen wired for a *live* preview: while the child drags
//  the brightness slider or picks a color filter, `displayAdjustments(for:)`
//  (see `DisplayFilters.swift`) re-renders the whole screen dimmed/filtered in
//  real time. "Simpan" persists the draft; the back arrow discards it.
//
//  When the real navigation flow lands (main menu → settings), move the
//  `StorageService` ownership up to `OwlLalaApp`/the menu and reuse
//  `SettingsHostView` from the settings destination.
//

import SwiftUI

struct ContentView: View {

    /// The app's single storage instance; owns persisted settings and progress.
    @StateObject private var storageService = StorageService()

    var body: some View {
        SettingsHostView(storageService: storageService)
    }
}

// MARK: - Settings Host

/// Bridges `SettingsViewModel` to the presentation-only `SettingsScreen`
/// component and applies the display adjustments so edits preview live.
private struct SettingsHostView: View {

    /// Draft-editing view model for the settings flow.
    @StateObject private var viewModel: SettingsViewModel

    /// Creates the host, building the view model from the shared storage.
    ///
    /// - Parameter storageService: The app's storage instance.
    init(storageService: StorageService) {
        _viewModel = StateObject(
            wrappedValue: SettingsViewModel(storageService: storageService)
        )
    }

    var body: some View {
        SettingsScreen(
            brightness: $viewModel.draftSettings.backgroundBrightness,
            colorVisionSimulation: $viewModel.draftSettings.colorVisionSimulation,
            onSave: { viewModel.save() },
            onBack: { viewModel.cancel() }
        )
        // Live preview while editing: BOTH adjustments apply to the whole
        // screen. This is safe because the settings panel is built exclusively
        // from SwiftUI-drawn views (`SettingsSlider`/`SettingsToggle`, no
        // ScrollView) — UIKit-backed controls would vanish under the shader.
        // See `DisplayFilters.swift` and `SettingsPanelBody`.
        .displayAdjustments(for: viewModel.draftSettings)
        .onAppear {
            viewModel.beginEditing()
        }
    }
}

#Preview {
    ContentView()
}

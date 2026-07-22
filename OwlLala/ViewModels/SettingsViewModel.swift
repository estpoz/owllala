//
//  SettingsViewModel.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//
//  OVERVIEW
//  --------
//  Owns ALL logic for the settings feature. Both presentations of
//  `SettingsView` — the full-screen page opened from the main menu and the
//  modal card (`isModal: true`) used everywhere else — are thin views that
//  only call the functions on this view model; no settings rules live in the
//  views.
//
//  EDITING FLOW
//  ------------
//  Values are edited on a *draft* copy so nothing is persisted until the child
//  taps "Simpan":
//    beginEditing() → setDraftBrightness / setFilterEnabled / selectSimulation
//    → save() (commit to StorageService) or cancel() (discard the draft).
//
//  WHERE IT IS USED
//  ----------------
//  Created by `SettingsView` (via the buttons in `Components/Buttons.swift`).
//  Persisted through `StorageService`. Covered by `SettingsViewModelTests` in
//  `OwlLalaTests`.
//

import Combine
import Foundation

// MARK: - Settings View Model

/// Manages draft editing for the main Settings screen and gameplay settings overlay.
@MainActor
final class SettingsViewModel: ObservableObject {

    /// The settings currently persisted in `StorageService`.
    @Published private(set) var savedSettings: Settings

    /// The working copy being edited; applied live as a preview, but only
    /// persisted when `save()` is called.
    @Published var draftSettings: Settings

    /// Whether an editing session is in progress (between `beginEditing()` and
    /// `save()`/`cancel()`). While `true`, external settings changes do not
    /// overwrite the draft.
    @Published private(set) var isEditing: Bool

    /// Whether the "Filter Warna" section is switched on.
    ///
    /// This is derived UI state. The active simulation becomes `nil` while the
    /// switch is off, but `Settings` retains the last selected type so the next
    /// switch-on restores it.
    @Published private(set) var isFilterEnabled: Bool

    /// The settings the app should currently RENDER with: the draft while an
    /// editing session is open (live preview), otherwise the saved settings.
    ///
    /// The centralized screen, background, and scroll containers read this
    /// value from the environment, so preview and saved settings update every
    /// current screen without feature-specific settings plumbing.
    var activeDisplaySettings: Settings {
        isEditing ? draftSettings : savedSettings
    }

    /// Whether the current draft contains a value that can be persisted.
    ///
    /// `Settings` is `Hashable`, so this comparison covers brightness, text
    /// size, and the optional color-vision simulation in one centralized rule.
    var hasUnsavedChanges: Bool {
        draftSettings != savedSettings
    }

    private let storageService: StorageService
    private var cancellables: Set<AnyCancellable> = []

    /// Creates the view model, mirroring the currently persisted settings and
    /// subscribing to external changes so a non-editing screen stays in sync.
    ///
    /// - Parameter storageService: The app's storage instance.
    init(storageService: StorageService) {
        self.storageService = storageService
        self.savedSettings = storageService.settings
        self.draftSettings = storageService.settings
        self.isEditing = false
        self.isFilterEnabled = storageService.settings.isColorVisionSimulationEnabled

        storageService.$settings
            .dropFirst()
            .sink { [weak self] settings in
                Task { @MainActor in
                    guard let self else {
                        return
                    }

                    self.savedSettings = settings
                    if !self.isEditing {
                        self.draftSettings = settings
                        self.isFilterEnabled = settings.isColorVisionSimulationEnabled
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: Editing Session

    /// Starts an editing session: refreshes the draft from the persisted
    /// settings so editing always begins from the saved state.
    ///
    /// Called by the settings views in `onAppear`. Ignored while a session is
    /// already open, so a re-fired `onAppear` (e.g. after a SwiftUI subtree
    /// rebuild) can never wipe the child's in-progress edits.
    func beginEditing() {
        guard !isEditing else {
            return
        }

        savedSettings = storageService.settings
        draftSettings = storageService.settings
        isFilterEnabled = draftSettings.isColorVisionSimulationEnabled
        isEditing = true
    }

    /// Commits the draft to persistent storage and ends the editing session.
    ///
    /// Called by the "Simpan" button on both settings surfaces.
    func save() {
        let normalizedSettings = Settings(
            backgroundBrightness: draftSettings.backgroundBrightness,
            colorVisionSimulation: draftSettings.colorVisionSimulation,
            lastColorVisionSimulation: draftSettings.lastColorVisionSimulation,
            textSize: draftSettings.textSize
        )

        storageService.updateSettings(normalizedSettings)
        savedSettings = normalizedSettings
        draftSettings = normalizedSettings
        isFilterEnabled = normalizedSettings.isColorVisionSimulationEnabled
        isEditing = false
    }

    /// Discards the draft, restores the persisted settings, and ends the
    /// editing session.
    ///
    /// Called by the back arrow of `SettingsView` (page and modal alike).
    func cancel() {
        savedSettings = storageService.settings
        draftSettings = storageService.settings
        isFilterEnabled = draftSettings.isColorVisionSimulationEnabled
        isEditing = false
    }

    // MARK: Brightness

    /// Updates the draft's background brightness; the `Settings` model clamps
    /// the value into its supported range.
    ///
    /// Bound to the brightness slider on both settings surfaces.
    ///
    /// - Parameter value: The requested brightness.
    func setDraftBrightness(_ value: Double) {
        draftSettings.setBackgroundBrightness(value)
    }

    /// Updates the draft's Dynamic Type category ("Ukuran Teks").
    ///
    /// Bound to the text-size slider on both settings surfaces.
    ///
    /// - Parameter value: The requested app text-size category.
    func setDraftTextSize(_ value: AppTextSize) {
        draftSettings.setTextSize(value)
    }

    // MARK: Color Filter

    /// Switches the "Filter Warna" section on or off.
    ///
    /// Switching off removes the active effect without discarding the selected
    /// type. Switching on restores that last selection. Bound to the filter
    /// toggle on both settings surfaces.
    ///
    /// - Parameter isEnabled: The new switch state.
    func setFilterEnabled(_ isEnabled: Bool) {
        isFilterEnabled = isEnabled

        if isEnabled {
            draftSettings.enableColorVisionSimulation(
                draftSettings.lastColorVisionSimulation
            )
        } else {
            draftSettings.disableColorVisionSimulation()
        }
    }

    /// Selects a color-vision filter type for the draft.
    ///
    /// Ignored while the filter switch is off — the option rows are disabled in
    /// that state, and this guard keeps the rule enforced even if a view calls
    /// it anyway. Called by the Red/Green, Green/Red, and Blue/Yellow options.
    ///
    /// - Parameter simulation: The filter type the child tapped.
    func selectSimulation(_ simulation: ColorVisionSimulation) {
        guard isFilterEnabled else {
            return
        }

        draftSettings.enableColorVisionSimulation(simulation)
    }

    /// Returns whether the given filter type is the draft's current selection.
    ///
    /// Used by the option rows to draw their radio indicator.
    ///
    /// - Parameter simulation: The filter type to check.
    /// - Returns: `true` when it is the current or retained selection.
    func isSimulationSelected(_ simulation: ColorVisionSimulation) -> Bool {
        draftSettings.lastColorVisionSimulation == simulation
    }

    /// Enables a color-vision simulation on the draft directly, without going
    /// through the filter switch.
    ///
    /// Kept for programmatic use and tests; the views use
    /// `selectSimulation(_:)`, which respects the switch state.
    ///
    /// - Parameter simulation: The simulation type to apply.
    func enableSimulation(_ simulation: ColorVisionSimulation) {
        draftSettings.enableColorVisionSimulation(simulation)
    }

    /// Disables the draft's color-vision simulation directly.
    ///
    /// Counterpart of `enableSimulation(_:)`; the views use
    /// `setFilterEnabled(false)` instead.
    func disableSimulation() {
        draftSettings.disableColorVisionSimulation()
    }
}

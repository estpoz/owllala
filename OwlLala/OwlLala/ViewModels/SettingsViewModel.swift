//
//  SettingsViewModel.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//

import Combine
import Foundation

// MARK: - Settings View Model

/// Manages draft editing for the main Settings screen and gameplay settings overlay.
@MainActor
final class SettingsViewModel: ObservableObject {

    @Published private(set) var savedSettings: Settings
    @Published var draftSettings: Settings
    @Published private(set) var isEditing: Bool

    private let storageService: StorageService
    private var cancellables: Set<AnyCancellable> = []

    init(storageService: StorageService) {
        self.storageService = storageService
        self.savedSettings = storageService.settings
        self.draftSettings = storageService.settings
        self.isEditing = false

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
                    }
                }
            }
            .store(in: &cancellables)
    }

    func beginEditing() {
        savedSettings = storageService.settings
        draftSettings = storageService.settings
        isEditing = true
    }

    func setDraftBrightness(_ value: Double) {
        draftSettings.setBackgroundBrightness(value)
    }

    func enableSimulation(_ simulation: ColorVisionSimulation) {
        draftSettings.enableColorVisionSimulation(simulation)
    }

    func disableSimulation() {
        draftSettings.disableColorVisionSimulation()
    }

    func save() {
        let normalizedSettings = Settings(
            backgroundBrightness: draftSettings.backgroundBrightness,
            colorVisionSimulation: draftSettings.colorVisionSimulation
        )

        storageService.updateSettings(normalizedSettings)
        savedSettings = normalizedSettings
        draftSettings = normalizedSettings
        isEditing = false
    }

    func cancel() {
        savedSettings = storageService.settings
        draftSettings = storageService.settings
        isEditing = false
    }
}

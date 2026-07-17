//
//  MainMenuViewModel.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//

import Combine
import Foundation

// MARK: - Main Menu View Model

/// Owns presentation state for the main menu.
@MainActor
final class MainMenuViewModel: ObservableObject {

    enum Destination: Hashable {
        case mainStory
        case trainingMode
        case statistics
        case settings
    }

    @Published var destination: Destination?

    let menuItems: [Destination] = [
        .mainStory,
        .trainingMode,
        .statistics,
        .settings
    ]

    func select(_ destination: Destination) {
        self.destination = destination
    }

    func clearDestination() {
        destination = nil
    }
}

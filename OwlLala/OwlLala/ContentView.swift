//
//  ContentView.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//
//  Root view of the app. Owns the shared `StorageService` and applies the
//  saved display settings (background brightness + color-vision filter) to
//  the whole screen via `displayAdjustments(for:)`.
//
//  The real screens plug in here: the main menu opens Settings with
//  `SettingsButton(storageService:)`, and gameplay uses
//  `SettingsOverlayButton(storageService:)` (see `Components/Buttons.swift`).
//

import SwiftUI

struct ContentView: View {

    /// The app's single storage instance; owns persisted settings and progress.
    @StateObject private var storageService = StorageService()

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            Text("OwlLala")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(.black)
        }
        // Persisted settings shape the whole app's appearance.
        .displayAdjustments(for: storageService.settings)
    }
}

#Preview {
    ContentView()
}

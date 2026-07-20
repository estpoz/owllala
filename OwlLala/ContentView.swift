//
//  ContentView.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//
//  Root view of the app. Owns the single shared `StorageService` and the
//  app-wide `SettingsViewModel`, injects both into the SwiftUI environment,
//  and hosts the main menu.
//
//  HOW SETTINGS APPLY TO VIEWS
//  ---------------------------
//  Any view can apply the current display settings (brightness + color filter)
//  itself with `.appDisplayAdjustments()` — it reads the shared
//  `SettingsViewModel` from the environment, so nothing has to be wired
//  through this file (see `DisplayFilters.swift`). Apply it once per screen
//  root; while the child edits settings the draft previews live, and "Simpan"
//  commits it everywhere at once.
//
//  This root currently applies it around the whole tree, so screens hosted
//  under the main menu are covered by default; a screen rendered outside this
//  tree just calls `.appDisplayAdjustments()` on itself.
//

import SwiftUI

struct ContentView: View {

    /// The app's single storage instance; owns persisted settings and progress.
    @StateObject private var storageService: StorageService

    /// The app-wide settings logic, shared with every screen through the
    /// environment.
    @StateObject private var settingsViewModel: SettingsViewModel

    /// Builds the shared storage and the settings view model on top of it.
    init() {
        let storageService = StorageService()

        _storageService = StateObject(wrappedValue: storageService)
        _settingsViewModel = StateObject(
            wrappedValue: SettingsViewModel(storageService: storageService)
        )
    }

    var body: some View {
        // NOTE: `appDisplayAdjustments()` is deliberately NOT applied here.
        // MainMenuView contains a NavigationStack (UIKit-backed), and wrapping
        // it in the color shader makes SwiftUI render a yellow "no entry"
        // placeholder instead of the app. Each screen applies the modifier at
        // its own root instead (see MainMenuView.destinationView).
        MainMenuView()
            // Text size is environment-based, so applying it ONCE here covers
            // every screen automatically — the environment flows through
            // NavigationStack into all pushed screens.
            .appTextSizeAdjustment()
            // Make the shared objects available to every view in the tree, so
            // any screen can use the display-adjustment modifiers or reach the
            // settings logic without init plumbing.
            .environmentObject(storageService)
            .environmentObject(settingsViewModel)
    }
}

#Preview {
    ContentView()
}

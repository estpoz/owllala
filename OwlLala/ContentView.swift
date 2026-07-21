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
//  This root injects one shared `SettingsViewModel` and applies text sizing to
//  the whole navigation tree. `MainMenuView` centralizes automatic filtering
//  at its navigation destinations. New standalone screens use `AppScreen`;
//  new scrolling screens use `AppScrollScreen` / `AppFilteredScrollView`.
//  Those containers apply saved brightness and color settings without feature
//  views wiring settings themselves (see `DisplayFilters.swift`).
//

import SwiftUI

struct ContentView: View {

    /// The app's single storage instance; owns persisted settings and progress.
    @StateObject private var storageService: StorageService

    /// The app-wide settings logic, shared with every screen through the
    /// environment.
    @StateObject private var settingsViewModel: SettingsViewModel

    /// Shows the splash screen on every app launch before entering the menu.
    @State private var isShowingSplash = true

    /// Builds the shared storage and the settings view model on top of it.
    init() {
        let storageService = StorageService()

        _storageService = StateObject(wrappedValue: storageService)
        _settingsViewModel = StateObject(
            wrappedValue: SettingsViewModel(storageService: storageService)
        )
    }

    var body: some View {
        // The NavigationStack is UIKit-backed, so the Metal shader cannot wrap
        // this root. Screen and scroll containers inside the stack own the
        // centralized filtering boundaries instead.
        ZStack {
            if isShowingSplash {
                SplashScreenView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        isShowingSplash = false
                    }
                }
                .transition(.opacity)
            } else {
                MainMenuView()
                    .transition(.opacity)
            }
        }
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

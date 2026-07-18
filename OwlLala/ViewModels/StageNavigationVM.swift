//
//  StageNavigationVM.swift
//  OwlLala
//
//  Created by Amanda on 17/07/26.
//

import SwiftUI

/// Root coordinator: owns the NavigationStack path and decides which
/// screens get pushed. ChapterSuccessOverlayView is layered ON TOP of
/// ChapterGamePlayView via local @State (not pushed), so the dim
/// background correctly shows the gameplay screen behind it.
struct StageNavigationVM: View {

    @State private var path = NavigationPath()
    @StateObject private var mainMenuViewModel = MainMenuViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel(storageService: StorageService()) // <-- tambahkan

    var body: some View {
        NavigationStack(path: $path) {
            MainMenuView()
                .navigationDestination(for: Story.self) { story in
                    ChapterSelectionView(
                        viewModel: ChapterSelectionViewModel(
                            story: story,
                            storageService: StorageService(
                                firstChapterID: story.chapters.first?.id ?? "",
                                userDefaults: .standard
                            )
                        )
                    )
                    .navigationDestination(for: Chapter.self) { chapter in
                        ChapterGamePlayView(chapter: chapter)
                    }
                }
        }
        .environmentObject(settingsViewModel) // <-- tambahkan, harus jadi ancestor semua view di atas
    }
}

#Preview(traits: .landscapeRight) {
    StageNavigationVM()
}

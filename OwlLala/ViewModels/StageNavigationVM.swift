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
    @StateObject private var storageService: StorageService
    @StateObject private var settingsViewModel: SettingsViewModel

    init() {
        let storageService = StorageService()

        _storageService = StateObject(wrappedValue: storageService)
        _settingsViewModel = StateObject(
            wrappedValue: SettingsViewModel(storageService: storageService)
        )
    }

    var body: some View {
        NavigationStack(path: $path) {
            MainMenuView()
                .navigationDestination(for: Story.self) { story in
                    ChapterSelectionView(
                        viewModel: ChapterSelectionViewModel(
                            story: story,
                            storageService: storageService
                        )
                    )
                    .navigationDestination(for: Chapter.self) { chapter in
                        ChapterGamePlayView(
                            viewModel: ChapterGameplayViewModel(
                                chapter: chapter,
                                source: .mainStory,
                                nextChapterID: nextChapterID(after: chapter, in: story),
                                storageService: storageService
                            )
                        )
                    }
                }
        }
        .environmentObject(storageService)
        .environmentObject(settingsViewModel) // <-- tambahkan, harus jadi ancestor semua view di atas
    }

    private func nextChapterID(after chapter: Chapter, in story: Story) -> String? {
        guard let currentIndex = story.chapters.firstIndex(of: chapter) else {
            return nil
        }

        let nextIndex = story.chapters.index(after: currentIndex)
        guard story.chapters.indices.contains(nextIndex) else {
            return nil
        }

        return story.chapters[nextIndex].id
    }
}

#Preview(traits: .landscapeRight) {
    StageNavigationVM()
}

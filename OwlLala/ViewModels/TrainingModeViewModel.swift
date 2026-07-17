//
//  TrainingModeViewModel.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//

import Combine
import Foundation

// MARK: - Training Chapter Item

struct TrainingChapterItem: Identifiable, Hashable {
    let chapter: Chapter
    let isUnlocked: Bool
    let bestStars: Int
    let playCount: Int

    var id: String {
        chapter.id
    }
}

// MARK: - Training Mode View Model

/// Presents chapter mini-games for Training Mode without changing story progression.
@MainActor
final class TrainingModeViewModel: ObservableObject {

    @Published private(set) var selectedChapter: Chapter?

    let story: Story

    private let storageService: StorageService
    private var cancellables: Set<AnyCancellable> = []

    var isTrainingUnlocked: Bool {
        storageService.userStats.isTrainingUnlocked(for: story)
    }

    var items: [TrainingChapterItem] {
        story.chapters.map { chapter in
            TrainingChapterItem(
                chapter: chapter,
                isUnlocked: isTrainingUnlocked,
                bestStars: storageService.userStats.bestStars(for: chapter.id),
                playCount: storageService.userStats.playCount(for: chapter.id)
            )
        }
    }

    init(
        story: Story,
        storageService: StorageService
    ) {
        self.story = story
        self.storageService = storageService

        storageService.objectWillChange
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
    }

    func selectChapter(_ chapter: Chapter) {
        guard isTrainingUnlocked else {
            selectedChapter = nil
            return
        }

        selectedChapter = chapter
    }

    func makeGameplayViewModel(for chapter: Chapter) -> ChapterGameplayViewModel {
        ChapterGameplayViewModel(
            chapter: chapter,
            source: .training,
            storageService: storageService
        )
    }

    func clearSelection() {
        selectedChapter = nil
    }
}

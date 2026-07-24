//
//  TrainingModeViewModel.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 17/07/26.
//

import Combine
import Foundation

struct TrainingChapterItem: Identifiable, Hashable {
    let chapter: Chapter
    let isUnlocked: Bool
    let bestStars: Int
    let playCount: Int

    var id: String { chapter.id }
}

@MainActor
final class TrainingModeViewModel: ObservableObject {
    @Published var selectedChapter: Chapter?
    @Published var lastCompletedChapterID: String?
    @Published var lastPlayedChapterID: String?

    let story: Story
    let storageService: StorageService?
    private var cancellables: Set<AnyCancellable> = []

    var isTrainingUnlocked: Bool {
        storageService?.userStats.isTrainingUnlocked(for: story) ?? true
    }

    var items: [TrainingChapterItem] {
        story.chapters.map { chapter in
            TrainingChapterItem(
                chapter: chapter,
                isUnlocked: isTrainingUnlocked,
                bestStars: storageService?.userStats.bestStars(for: chapter.id) ?? 0,
                playCount: storageService?.userStats.playCount(for: chapter.id) ?? 0
            )
        }
    }

    init(story: Story, storageService: StorageService? = nil) {
        self.story = story
        self.storageService = storageService

        storageService?.objectWillChange
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
        lastPlayedChapterID = chapter.id
        selectedChapter = chapter
    }

    func clearSelection() {
        selectedChapter = nil
    }

    /// Computes the ID of the chapter directly following the given chapter in training mode.
    func nextChapterID(for chapter: Chapter) -> String? {
        guard let currentIndex = story.chapters.firstIndex(where: { $0.id == chapter.id }),
              currentIndex + 1 < story.chapters.count else {
            return nil
        }
        return story.chapters[currentIndex + 1].id
    }

    /// Records that the player completed a training session.
    func recordChapterCompletion(_ chapterID: String) {
        lastCompletedChapterID = chapterID
    }

    /// Clears completion state after updating carousel focus.
    func clearCompletionState() {
        lastCompletedChapterID = nil
    }
}

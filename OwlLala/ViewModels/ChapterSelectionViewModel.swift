//
//  ChapterSelectionViewModel.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//

import Combine
import Foundation

// MARK: - Chapter Selection Item

struct ChapterSelectionItem: Identifiable, Hashable {
    let chapter: Chapter
    let isUnlocked: Bool
    let isCompleted: Bool
    let bestStars: Int

    var id: String {
        chapter.id
    }
}

// MARK: - Chapter Selection View Model

/// Derives chapter selection state from the selected story and persisted progress.
@MainActor
final class ChapterSelectionViewModel: ObservableObject {

    @Published private(set) var selectedChapter: Chapter?

    let story: Story

    private let storageService: StorageService
    private var cancellables: Set<AnyCancellable> = []

    var items: [ChapterSelectionItem] {
        story.chapters.map { chapter in
            ChapterSelectionItem(
                chapter: chapter,
                isUnlocked: storageService.userStats.isChapterUnlocked(chapter.id),
                isCompleted: storageService.userStats.isChapterCompleted(chapter.id),
                bestStars: storageService.userStats.bestStars(for: chapter.id)
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
        guard storageService.userStats.isChapterUnlocked(chapter.id) else {
            selectedChapter = nil
            return
        }

        selectedChapter = chapter
    }

    func clearSelection() {
        selectedChapter = nil
    }

    func nextChapterID(after chapter: Chapter) -> String? {
        guard let index = story.chapters.firstIndex(where: { $0.id == chapter.id }) else {
            return nil
        }

        let nextIndex = story.chapters.index(after: index)
        guard story.chapters.indices.contains(nextIndex) else {
            return nil
        }

        return story.chapters[nextIndex].id
    }
}

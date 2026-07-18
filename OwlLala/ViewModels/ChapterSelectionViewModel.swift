import Combine
import Foundation

struct ChapterSelectionItem: Identifiable, Hashable {
    let chapter: Chapter
    let isUnlocked: Bool
    let isCompleted: Bool
    let bestStars: Int

    var id: String { chapter.id }
}

@MainActor
final class ChapterSelectionViewModel: ObservableObject {
    @Published var selectedChapter: Chapter?

    let story: Story
    private let storageService: StorageService?
    private var cancellables: Set<AnyCancellable> = []

    var items: [ChapterSelectionItem] {
        story.chapters.map { chapter in
            ChapterSelectionItem(
                chapter: chapter,
                isUnlocked: storageService?.userStats.isChapterUnlocked(chapter.id) ?? (chapter.order == 1),
                isCompleted: storageService?.userStats.isChapterCompleted(chapter.id) ?? false,
                bestStars: storageService?.userStats.bestStars(for: chapter.id) ?? 0
            )
        }
    }

    // Handles live app instances and accommodates clean default values for standalone preview injection
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
        if let storage = storageService {
            guard storage.userStats.isChapterUnlocked(chapter.id) else {
                selectedChapter = nil
                return
            }
        }
        selectedChapter = chapter
    }

    func clearSelection() {
        selectedChapter = nil
    }
}

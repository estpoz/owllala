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

    let story: Story
    private let storageService: StorageService?
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
        selectedChapter = chapter
    }

    func clearSelection() {
        selectedChapter = nil
    }
}

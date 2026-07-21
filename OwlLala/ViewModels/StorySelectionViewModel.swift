import Combine
import Foundation

struct StorySelectionItem: Identifiable, Hashable {
    let story: Story
    let isAvailable: Bool

    var id: String { story.id }
}

@MainActor
final class StorySelectionViewModel: ObservableObject {
    @Published var selectedStory: Story?

    // MARK: - Story Catalog

    private let stories: [Story]

    var items: [StorySelectionItem] {
        stories.map { story in
            StorySelectionItem(story: story, isAvailable: story.isAvailable)
        }
    }

    init() {
        self.stories = StoryCatalog.stories
    }

    init(stories: [Story]) {
        self.stories = stories
    }

    func selectStory(_ story: Story) {
        guard story.isAvailable else {
            selectedStory = nil
            return
        }
        selectedStory = story
    }

    func clearSelection() {
        selectedStory = nil
    }
}

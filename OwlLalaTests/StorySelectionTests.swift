import Testing
import Foundation
@testable import OwlLala

@MainActor
@Suite("Story Selection ViewModel TDD Specifications")
struct StorySelectionTests {

    private let availableStory: Story
    private let unavailableStory: Story

    init() {
        self.availableStory = Story(
            id: "story-1",
            order: 1,
            title: "Cerita 1",
            subtitle: nil,
            description: "Test Description",
            coverAssetName: "storyCover1",
            availability: .available, // Maps to story.isAvailable == true
            chapters: [],
            completionSummary: nil
        )

        self.unavailableStory = Story(
            id: "story-2",
            order: 2,
            title: "Cerita 2",
            subtitle: nil,
            description: "Test Description",
            coverAssetName: "storyCover2",
            availability: .comingSoon, // Maps to story.isAvailable == false
            chapters: [],
            completionSummary: nil
        )
    }

    // MARK: - Initial State Specifications

    @Test("Given injected stories, items collection reflects provided dataset")
    func test_items_whenInitialized_containsAllProvidedStories() {
        // Arrange & Act
        let sut = StorySelectionViewModel(stories: [availableStory, unavailableStory])

        // Assert
        #expect(sut.items.count == 2)
        #expect(sut.selectedStory == nil)
    }

    // MARK: - Selection Specifications

    @Test("Given available story, selecting it updates selectedStory")
    func test_selectStory_whenAvailable_updatesSelectedStory() {
        // Arrange
        let sut = StorySelectionViewModel(stories: [availableStory, unavailableStory])

        // Act
        sut.selectStory(availableStory)

        // Assert
        #expect(sut.selectedStory?.id == availableStory.id)
    }

    @Test("Given unavailable story, selecting it retains nil selection")
    func test_selectStory_whenUnavailable_ignoresSelection() {
        // Arrange
        let sut = StorySelectionViewModel(stories: [availableStory, unavailableStory])

        // Act
        sut.selectStory(unavailableStory)

        // Assert
        #expect(sut.selectedStory == nil)
    }

    @Test("Given active story selection, clearSelection resets state to nil")
    func test_clearSelection_whenCalled_resetsSelectedStoryToNil() {
        // Arrange
        let sut = StorySelectionViewModel(stories: [availableStory])
        sut.selectStory(availableStory)

        // Act
        sut.clearSelection()

        // Assert
        #expect(sut.selectedStory == nil)
    }
}

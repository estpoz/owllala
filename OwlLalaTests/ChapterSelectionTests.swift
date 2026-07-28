import Testing
import Foundation
@testable import OwlLala

@MainActor
@Suite("Chapter Selection ViewModel TDD Specifications")
struct ChapterSelectionTests {

    private let sampleChapters: [Chapter]
    private let sampleStory: Story
    private let storageService: StorageService

    init() {
        // Isolated StorageService instance to guarantee test independence
        let isolatedSuiteName = "ChapterSelectionTests_\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: isolatedSuiteName)!
        self.storageService = StorageService(userDefaults: userDefaults)

        let chapters = [
            Chapter(
                id: "chapter-1",
                order: 1,
                title: "Bab 1",
                subtitle: nil,
                description: "",
                thumbnailAssetName: "",
                competency: .shape,
                storyPages: [],
                gameConfiguration: GameConfiguration(
                    question: GameQuestion(
                        id: "q1",
                        prompt: "Prompt 1",
                        promptImageAssetName: nil,
                        answerOptions: [],
                        correctAnswerID: "a1",
                        hintText: ""
                    )
                ),
                learningSummary: LearningSummary(
                    successMessage: "",
                    explanation: "",
                    mainIllustrationAssetName: "",
                    exampleAssetNames: []
                )
            ),
            Chapter(
                id: "chapter-2",
                order: 2,
                title: "Bab 2",
                subtitle: nil,
                description: "",
                thumbnailAssetName: "",
                competency: .shape,
                storyPages: [],
                gameConfiguration: GameConfiguration(
                    question: GameQuestion(
                        id: "q2",
                        prompt: "Prompt 2",
                        promptImageAssetName: nil,
                        answerOptions: [],
                        correctAnswerID: "a2",
                        hintText: ""
                    )
                ),
                learningSummary: LearningSummary(
                    successMessage: "",
                    explanation: "",
                    mainIllustrationAssetName: "",
                    exampleAssetNames: []
                )
            )
        ]

        self.sampleChapters = chapters
        self.sampleStory = Story(
            id: "story-1",
            order: 1,
            title: "Cerita 1",
            subtitle: "Test Subtitle",
            description: "Test Description",
            coverAssetName: "storyCover1",
            availability: .available,
            chapters: chapters,
            completionSummary: nil
        )
    }

    // MARK: - Initial State Specifications

    @Test("Given fresh story, items count matches story chapters")
    func test_items_whenInitialized_returnsAllStoryChapters() {
        // Arrange
        let sut = ChapterSelectionViewModel(story: sampleStory, storageService: storageService)

        // Act & Assert
        #expect(sut.items.count == 2)
    }

    @Test("Given fresh story, first chapter defaults to unlocked")
    func test_items_whenInitialized_firstChapterIsUnlocked() {
        // Arrange
        let sut = ChapterSelectionViewModel(story: sampleStory, storageService: storageService)

        // Act & Assert
        #expect(sut.items[0].isUnlocked == true)
    }

    @Test("Given fresh state, no chapter is initially selected or tracked as played")
    func test_selectionState_whenInitialized_hasNilSelectionAndTrackingIDs() {
        // Arrange
        let sut = ChapterSelectionViewModel(story: sampleStory, storageService: storageService)

        // Act & Assert
        #expect(sut.selectedChapter == nil)
        #expect(sut.lastPlayedChapterID == nil)
        #expect(sut.lastCompletedChapterID == nil)
    }

    // MARK: - Selection Logic Specifications

    @Test("Given unlocked chapter, selecting it updates selectedChapter and lastPlayedChapterID")
    func test_selectChapter_whenUnlocked_setsSelectedChapterAndLastPlayedID() {
        // Arrange
        let sut = ChapterSelectionViewModel(story: sampleStory, storageService: storageService)
        let targetChapter = sampleChapters[0]

        // Act
        sut.selectChapter(targetChapter)

        // Assert
        #expect(sut.selectedChapter?.id == targetChapter.id)
        #expect(sut.lastPlayedChapterID == targetChapter.id)
    }

    @Test("Given locked chapter, selecting it rejects selection and preserves state")
    func test_selectChapter_whenLocked_deniesSelection() {
        // Arrange
        let sut = ChapterSelectionViewModel(story: sampleStory, storageService: storageService)
        let lockedChapter = sampleChapters[1]

        // Act
        sut.selectChapter(lockedChapter)

        // Assert
        #expect(sut.selectedChapter == nil)
        #expect(sut.lastPlayedChapterID == nil)
    }

    @Test("Given selected chapter, clearing selection clears selectedChapter but preserves lastPlayedChapterID")
    func test_clearSelection_whenCalled_resetsSelectedChapterOnly() {
        // Arrange
        let sut = ChapterSelectionViewModel(story: sampleStory, storageService: storageService)
        sut.selectChapter(sampleChapters[0])

        // Act
        sut.clearSelection()

        // Assert
        #expect(sut.selectedChapter == nil)
        #expect(sut.lastPlayedChapterID == "chapter-1")
    }

    // MARK: - Sequence Navigation Specifications

    @Test("Given non-final chapter, nextChapterID calculates subsequent chapter ID")
    func test_nextChapterID_whenHasNext_returnsNextChapterID() {
        // Arrange
        let sut = ChapterSelectionViewModel(story: sampleStory, storageService: storageService)

        // Act
        let nextID = sut.nextChapterID(for: sampleChapters[0])

        // Assert
        #expect(nextID == "chapter-2")
    }

    @Test("Given final chapter, nextChapterID returns nil")
    func test_nextChapterID_whenIsLastChapter_returnsNil() {
        // Arrange
        let sut = ChapterSelectionViewModel(story: sampleStory, storageService: storageService)

        // Act
        let nextID = sut.nextChapterID(for: sampleChapters[1])

        // Assert
        #expect(nextID == nil)
    }

    // MARK: - Completion Lifecycle Specifications

    @Test("When recording chapter completion, lastCompletedChapterID updates")
    func test_recordChapterCompletion_whenCalled_storesCompletedChapterID() {
        // Arrange
        let sut = ChapterSelectionViewModel(story: sampleStory, storageService: storageService)

        // Act
        sut.recordChapterCompletion("chapter-1")

        // Assert
        #expect(sut.lastCompletedChapterID == "chapter-1")
    }

    @Test("When clearing completion state, lastCompletedChapterID resets to nil")
    func test_clearCompletionState_whenCalled_resetsCompletedIDToNil() {
        // Arrange
        let sut = ChapterSelectionViewModel(story: sampleStory, storageService: storageService)
        sut.recordChapterCompletion("chapter-1")

        // Act
        sut.clearCompletionState()

        // Assert
        #expect(sut.lastCompletedChapterID == nil)
    }
}

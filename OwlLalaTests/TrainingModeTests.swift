import Testing
import Foundation
@testable import OwlLala

@MainActor
@Suite("Training Mode ViewModel TDD Specifications")
struct TrainingModeTests {

    private let sampleChapters: [Chapter]
    private let sampleStory: Story
    private let storageService: StorageService

    init() {
        // Isolated StorageService instance to guarantee test independence
        let isolatedSuiteName = "TrainingModeTests_\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: isolatedSuiteName)!
        self.storageService = StorageService(userDefaults: userDefaults)

        let chapters = [
            Chapter(
                id: "training-chapter-1",
                order: 1,
                title: "Latihan 1",
                subtitle: nil,
                description: "",
                thumbnailAssetName: "",
                competency: .shape,
                storyPages: [],
                gameConfiguration: GameConfiguration(
                    question: GameQuestion(
                        id: "tq1",
                        prompt: "Training Prompt 1",
                        promptImageAssetName: nil,
                        answerOptions: [],
                        correctAnswerID: "ta1",
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
                id: "training-chapter-2",
                order: 2,
                title: "Latihan 2",
                subtitle: nil,
                description: "",
                thumbnailAssetName: "",
                competency: .shape,
                storyPages: [],
                gameConfiguration: GameConfiguration(
                    question: GameQuestion(
                        id: "tq2",
                        prompt: "Training Prompt 2",
                        promptImageAssetName: nil,
                        answerOptions: [],
                        correctAnswerID: "ta2",
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
            subtitle: nil,
            description: "Test Description",
            coverAssetName: "storyCover1",
            availability: .available,
            chapters: chapters,
            completionSummary: nil
        )
    }

    /// Helper to complete story chapters in StorageService so training mode unlocks.
    private func unlockTrainingMode() {
        storageService.updateUserStats { userStats in
            for chapter in sampleChapters {
                userStats.completeChapter(nextChapterID: nil)
                userStats.recordCompletedGame(chapterID: chapter.id, earnedStars: 3)
            }
        }
    }

    // MARK: - Initial State Specifications

    @Test("Given training mode story, items reflect story structure")
    func test_items_whenInitialized_matchesStoryChapterCount() {
        // Arrange & Act
        let sut = TrainingModeViewModel(story: sampleStory, storageService: storageService)

        // Assert
        #expect(sut.items.count == 2)
        #expect(sut.selectedChapter == nil)
        #expect(sut.lastPlayedChapterID == nil)
        #expect(sut.lastCompletedChapterID == nil)
    }

    // MARK: - Selection Specifications

    @Test("Given unlocked training mode, selecting chapter updates selectedChapter and lastPlayedChapterID")
    func test_selectChapter_whenUnlocked_setsSelectionAndLastPlayedID() {
        // Arrange
        unlockTrainingMode()
        let sut = TrainingModeViewModel(story: sampleStory, storageService: storageService)
        let chapter = sampleChapters[0]

        // Act
        sut.selectChapter(chapter)

        // Assert
        #expect(sut.selectedChapter?.id == chapter.id)
        #expect(sut.lastPlayedChapterID == chapter.id)
    }

    @Test("Given locked training mode, selecting chapter denies selection")
    func test_selectChapter_whenLocked_deniesSelection() {
        // Arrange (story incomplete -> training mode locked)
        let sut = TrainingModeViewModel(story: sampleStory, storageService: storageService)
        let chapter = sampleChapters[0]

        // Act
        sut.selectChapter(chapter)

        // Assert
        #expect(sut.selectedChapter == nil)
        #expect(sut.lastPlayedChapterID == nil)
    }

    @Test("Given active selection, clearSelection resets selectedChapter but retains lastPlayedChapterID")
    func test_clearSelection_whenCalled_resetsSelectedChapterOnly() {
        // Arrange
        unlockTrainingMode()
        let sut = TrainingModeViewModel(story: sampleStory, storageService: storageService)
        sut.selectChapter(sampleChapters[0])

        // Act
        sut.clearSelection()

        // Assert
        #expect(sut.selectedChapter == nil)
        #expect(sut.lastPlayedChapterID == "training-chapter-1")
    }

    // MARK: - Sequence Navigation Specifications

    @Test("Given non-final training chapter, nextChapterID returns subsequent chapter ID")
    func test_nextChapterID_whenHasNext_returnsSubsequentChapterID() {
        // Arrange
        let sut = TrainingModeViewModel(story: sampleStory, storageService: storageService)

        // Act
        let nextID = sut.nextChapterID(for: sampleChapters[0])

        // Assert
        #expect(nextID == "training-chapter-2")
    }

    @Test("Given final training chapter, nextChapterID returns nil")
    func test_nextChapterID_whenIsLastChapter_returnsNil() {
        // Arrange
        let sut = TrainingModeViewModel(story: sampleStory, storageService: storageService)

        // Act
        let endID = sut.nextChapterID(for: sampleChapters[1])

        // Assert
        #expect(endID == nil)
    }

    // MARK: - Completion Lifecycle Specifications

    @Test("When recording training completion, lastCompletedChapterID updates")
    func test_recordChapterCompletion_whenCalled_storesCompletedID() {
        // Arrange
        let sut = TrainingModeViewModel(story: sampleStory, storageService: storageService)

        // Act
        sut.recordChapterCompletion("training-chapter-1")

        // Assert
        #expect(sut.lastCompletedChapterID == "training-chapter-1")
    }

    @Test("When clearing completion state, lastCompletedChapterID resets to nil")
    func test_clearCompletionState_whenCalled_resetsCompletedIDToNil() {
        // Arrange
        let sut = TrainingModeViewModel(story: sampleStory, storageService: storageService)
        sut.recordChapterCompletion("training-chapter-1")

        // Act
        sut.clearCompletionState()

        // Assert
        #expect(sut.lastCompletedChapterID == nil)
    }
}

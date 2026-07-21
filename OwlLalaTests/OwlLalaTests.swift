//
//  OwlLalaTests.swift
//  OwlLalaTests
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//
//  OVERVIEW
//  --------
//  Focused TDD tests for the app's view-model functions, written with the
//  Swift Testing framework (`@Suite` / `@Test` / `#expect`).
//  See https://developer.apple.com/documentation/testing
//
//  WHAT THESE TESTS COVER
//  ----------------------
//  One `@Suite` per view model in the `ViewModels/` folder. Each test
//  instantiates the *real* view model (via `@testable import OwlLala`) and calls
//  its own functions, then asserts on the resulting published state. This file
//  only tests view-model behavior — Models and Services are exercised only as
//  the collaborators a view model needs.
//
//  HOW EACH TEST IS SET UP
//  -----------------------
//  There are no helper functions here by design: each test builds the `Chapter`
//  / `Story` inputs inline by calling the real model initializers, because the
//  app ships no shared sample-data source to read from. Every test also gets its
//  own isolated store — `StorageService(userDefaults: UserDefaults(suiteName:
//  UUID().uuidString)!)` — so a brand-new, empty `UserDefaults` suite is used
//  per test and tests never read or write each other's (or the app's) state.
//
//  All suites are `@MainActor` because the view models and `StorageService` are
//  main-actor isolated.
//
//  RUNNING
//  -------
//  Run in Xcode with Product ▸ Test (⌘U). If Xcode reopens this file as an old
//  version, use File ▸ Revert to Saved first so it loads what's on disk.
//

import Foundation
import Testing
@testable import OwlLala

// MARK: - ChapterGameplayViewModel

/// Behavior of `ChapterGameplayViewModel` — the state machine for one chapter
/// mini-game: story-page navigation, answer selection & star scoring, and
/// completion (persisting progress + choosing the next destination).
@MainActor
@Suite("ChapterGameplayViewModel")
struct ChapterGameplayViewModelTests {

    /// Given a Main Story chapter with story pages, when the child pages past
    /// the last one, then `isQuestionPresented` flips from `false` to `true`
    /// (the mini-game question is revealed).
    @Test func storyNavigationRevealsQuestionAfterLastPage() {
        let chapter = Chapter(id: "chapter-1", order: 1, title: "Bab", subtitle: nil, description: "d", thumbnailAssetName: "t", competency: .shape, storyPages: [StoryPage(id: "p1", order: 1, illustrationAssetName: "i", narration: "n", voiceOverAssetName: nil)], gameConfiguration: GameConfiguration(question: GameQuestion(id: "q", prompt: "p", promptImageAssetName: nil, answerOptions: [AnswerOption(id: "correct", text: "B", imageAssetName: nil)], correctAnswerID: "correct", hintText: "h")), learningSummary: LearningSummary(successMessage: "s", explanation: "e", mainIllustrationAssetName: "m", exampleAssetNames: []))
        let viewModel = ChapterGameplayViewModel(chapter: chapter, source: .mainStory, nextChapterID: "chapter-2", storageService: StorageService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!))

        #expect(viewModel.isQuestionPresented == false)
        viewModel.goToNextStoryPage()
        #expect(viewModel.isQuestionPresented == true)
    }

    /// Given a fresh question, when the child selects the correct answer on the
    /// first attempt, then positive feedback is shown and 3 stars are earned
    /// (the maximum, since there were no wrong attempts).
    @Test func selectingCorrectAnswerOnFirstTryEarnsThreeStars() {
        let chapter = Chapter(id: "chapter-1", order: 1, title: "Bab", subtitle: nil, description: "d", thumbnailAssetName: "t", competency: .shape, storyPages: [], gameConfiguration: GameConfiguration(question: GameQuestion(id: "q", prompt: "p", promptImageAssetName: nil, answerOptions: [AnswerOption(id: "correct", text: "B", imageAssetName: nil), AnswerOption(id: "wrong", text: "S", imageAssetName: nil)], correctAnswerID: "correct", hintText: "h")), learningSummary: LearningSummary(successMessage: "s", explanation: "e", mainIllustrationAssetName: "m", exampleAssetNames: []))
        let viewModel = ChapterGameplayViewModel(chapter: chapter, source: .mainStory, nextChapterID: "chapter-2", storageService: StorageService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!))

        viewModel.selectAnswer(AnswerOption(id: "correct", text: "B", imageAssetName: nil))

        #expect(viewModel.isCorrectFeedbackPresented == true)
        #expect(viewModel.earnedStars == 3)
    }

    /// Given one wrong answer was chosen first, when the child then chooses the
    /// correct answer, then the earned stars drop to 2 (the scoring penalty for
    /// a single mistake).
    @Test func retryingAfterAWrongAnswerEarnsTwoStars() {
        let chapter = Chapter(id: "chapter-1", order: 1, title: "Bab", subtitle: nil, description: "d", thumbnailAssetName: "t", competency: .shape, storyPages: [], gameConfiguration: GameConfiguration(question: GameQuestion(id: "q", prompt: "p", promptImageAssetName: nil, answerOptions: [AnswerOption(id: "correct", text: "B", imageAssetName: nil), AnswerOption(id: "wrong", text: "S", imageAssetName: nil)], correctAnswerID: "correct", hintText: "h")), learningSummary: LearningSummary(successMessage: "s", explanation: "e", mainIllustrationAssetName: "m", exampleAssetNames: []))
        let viewModel = ChapterGameplayViewModel(chapter: chapter, source: .mainStory, nextChapterID: "chapter-2", storageService: StorageService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!))

        viewModel.selectAnswer(AnswerOption(id: "wrong", text: "S", imageAssetName: nil))
        #expect(viewModel.wrongAnswerCount == 1)

        viewModel.selectAnswer(AnswerOption(id: "correct", text: "B", imageAssetName: nil))
        #expect(viewModel.earnedStars == 2)
    }

    /// Given a correct Main Story answer, when `finishCorrectFeedback()` runs,
    /// then the destination becomes `.stageCleared`, the earned stars are saved
    /// to the store, and the next chapter is unlocked for progression.
    @Test func finishingMainStoryRecordsProgressAndUnlocksNextChapter() {
        let storage = StorageService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
        let chapter = Chapter(id: "chapter-1", order: 1, title: "Bab", subtitle: nil, description: "d", thumbnailAssetName: "t", competency: .shape, storyPages: [], gameConfiguration: GameConfiguration(question: GameQuestion(id: "q", prompt: "p", promptImageAssetName: nil, answerOptions: [AnswerOption(id: "correct", text: "B", imageAssetName: nil)], correctAnswerID: "correct", hintText: "h")), learningSummary: LearningSummary(successMessage: "s", explanation: "e", mainIllustrationAssetName: "m", exampleAssetNames: []))
        let viewModel = ChapterGameplayViewModel(chapter: chapter, source: .mainStory, nextChapterID: "chapter-2", storageService: storage)

        viewModel.selectAnswer(AnswerOption(id: "correct", text: "B", imageAssetName: nil))
        viewModel.finishCorrectFeedback()

        #expect(viewModel.destination == .stageCleared)
        #expect(storage.userStats.bestStars(for: "chapter-1") == 3)
        #expect(storage.userStats.isChapterUnlocked("chapter-2") == true)
    }
}

// MARK: - ChapterSelectionViewModel

/// Behavior of `ChapterSelectionViewModel` — turning a story plus persisted
/// progress into the chapter list, gating selection to unlocked chapters, and
/// resolving the "next chapter" for progression.
@MainActor
@Suite("ChapterSelectionViewModel")
struct ChapterSelectionViewModelTests {

    /// Given a story whose chapter-1 was completed with 2 stars, then `items`
    /// reflect that state: chapter-1 is completed with `bestStars == 2`, while
    /// chapter-2 remains locked (only the first chapter starts unlocked).
    @Test func itemsReflectUnlockCompletionAndBestStars() {
        let chapters = (1...5).map { i in Chapter(id: "chapter-\(i)", order: i, title: "Bab", subtitle: nil, description: "d", thumbnailAssetName: "t", competency: .shape, storyPages: [], gameConfiguration: GameConfiguration(question: GameQuestion(id: "q", prompt: "p", promptImageAssetName: nil, answerOptions: [AnswerOption(id: "c", text: "B", imageAssetName: nil)], correctAnswerID: "c", hintText: "h")), learningSummary: LearningSummary(successMessage: "s", explanation: "e", mainIllustrationAssetName: "m", exampleAssetNames: [])) }
        let story = Story(id: "story-1", order: 1, title: "Cerita", subtitle: nil, description: "d", coverAssetName: "c", availability: .available, chapters: chapters, completionSummary: nil)
        let storage = StorageService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
        let viewModel = ChapterSelectionViewModel(story: story, storageService: storage)

        storage.updateUserStats { $0.recordCompletedGame(chapterID: "chapter-1", earnedStars: 2) }

        #expect(viewModel.items[0].isCompleted == true)
        #expect(viewModel.items[0].bestStars == 2)
        #expect(viewModel.items[1].isUnlocked == false)
    }

    /// Given only chapter-1 is unlocked, when `selectChapter` is called for a
    /// locked chapter then no selection is made, but calling it for an unlocked
    /// chapter selects it.
    @Test func selectChapterOnlySelectsUnlockedChapters() {
        let chapters = (1...5).map { i in Chapter(id: "chapter-\(i)", order: i, title: "Bab", subtitle: nil, description: "d", thumbnailAssetName: "t", competency: .shape, storyPages: [], gameConfiguration: GameConfiguration(question: GameQuestion(id: "q", prompt: "p", promptImageAssetName: nil, answerOptions: [AnswerOption(id: "c", text: "B", imageAssetName: nil)], correctAnswerID: "c", hintText: "h")), learningSummary: LearningSummary(successMessage: "s", explanation: "e", mainIllustrationAssetName: "m", exampleAssetNames: [])) }
        let story = Story(id: "story-1", order: 1, title: "Cerita", subtitle: nil, description: "d", coverAssetName: "c", availability: .available, chapters: chapters, completionSummary: nil)
        let viewModel = ChapterSelectionViewModel(story: story, storageService: StorageService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!))

        viewModel.selectChapter(story.chapters[2]) // locked
        #expect(viewModel.selectedChapter == nil)

        viewModel.selectChapter(story.chapters[0]) // unlocked
        #expect(viewModel.selectedChapter?.id == "chapter-1")
    }

    // NOTE: `nextChapterID(after:)` was removed from the view model during the
    // new-test refactor, so its test was retired with it.
}

// MARK: - TrainingModeViewModel

/// Behavior of `TrainingModeViewModel` — gating Training Mode until the whole
/// story is finished, and vending gameplay view models configured for training
/// (replay) rather than story progression.
@MainActor
@Suite("TrainingModeViewModel")
struct TrainingModeViewModelTests {

    /// Given a story that isn't finished, `isTrainingUnlocked` is `false`; after
    /// every chapter has been completed in the store, it becomes `true`.
    @Test func trainingUnlocksOnlyAfterEveryChapterIsCompleted() {
        let chapters = (1...5).map { i in Chapter(id: "chapter-\(i)", order: i, title: "Bab", subtitle: nil, description: "d", thumbnailAssetName: "t", competency: .shape, storyPages: [], gameConfiguration: GameConfiguration(question: GameQuestion(id: "q", prompt: "p", promptImageAssetName: nil, answerOptions: [AnswerOption(id: "c", text: "B", imageAssetName: nil)], correctAnswerID: "c", hintText: "h")), learningSummary: LearningSummary(successMessage: "s", explanation: "e", mainIllustrationAssetName: "m", exampleAssetNames: [])) }
        let story = Story(id: "story-1", order: 1, title: "Cerita", subtitle: nil, description: "d", coverAssetName: "c", availability: .available, chapters: chapters, completionSummary: nil)
        let storage = StorageService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
        let viewModel = TrainingModeViewModel(story: story, storageService: storage)

        #expect(viewModel.isTrainingUnlocked == false)

        storage.updateUserStats { stats in
            for chapter in story.chapters { stats.recordCompletedGame(chapterID: chapter.id, earnedStars: 3) }
        }
        #expect(viewModel.isTrainingUnlocked == true)
    }

    /// Given a chapter, when `makeGameplayViewModel(for:)` builds a gameplay
    /// view model, then it is configured with the `.training` source and no next
    /// chapter — so replaying it records stats without advancing the story.
    // NOTE: `makeGameplayViewModel(for:)` was removed from the view model
    // during the new-test refactor, so its test was retired with it.
}

// MARK: - StorySelectionViewModel

/// Behavior of `StorySelectionViewModel` — allowing navigation into available
/// stories only and ignoring taps on "coming soon" ones.
@MainActor
@Suite("StorySelectionViewModel")
struct StorySelectionViewModelTests {

    /// The view model now owns its built-in story list: selecting an
    /// unavailable ("coming soon") story does nothing, while selecting an
    /// available one stores it.
    @Test func selectStoryOnlySelectsAvailableStories() throws {
        let viewModel = StorySelectionViewModel()

        let unavailable = viewModel.items.first { !$0.isAvailable }?.story
        if let unavailable {
            viewModel.selectStory(unavailable)
            #expect(viewModel.selectedStory == nil)
        }

        let available = try #require(viewModel.items.first { $0.isAvailable }?.story)
        viewModel.selectStory(available)
        #expect(viewModel.selectedStory?.id == available.id)
    }
}

// MARK: - MainMenuViewModel

/// Behavior of `MainMenuViewModel` — tracking which menu destination the child
/// has chosen so the main menu can drive navigation.
@MainActor
@Suite("MainMenuViewModel")
struct MainMenuViewModelTests {

    /// When a destination is selected it is stored in `destination`, and when
    /// cleared `destination` returns to `nil`.
    @Test func selectAndClearDestination() {
        let viewModel = MainMenuViewModel()

        viewModel.select(.statistics)
        #expect(viewModel.destination == .statistics)

        viewModel.clearDestination()
        #expect(viewModel.destination == nil)
    }
}

// MARK: - SettingsViewModel

/// Behavior of `SettingsViewModel` — the draft-editing flow for settings:
/// begin editing, mutate a draft, then either commit it to the store (`save`)
/// or throw it away (`cancel`).
@MainActor
@Suite("SettingsViewModel")
struct SettingsViewModelTests {

    /// Given an editing session with brightness and simulation changed on the
    /// draft, when `save()` is called, then editing ends and the changes are
    /// written through to the persisted `StorageService.settings`.
    @Test func saveCommitsDraftToStorageAndEndsEditing() {
        let storage = StorageService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
        let viewModel = SettingsViewModel(storageService: storage)

        viewModel.beginEditing()
        viewModel.setDraftBrightness(0.8)
        viewModel.enableSimulation(.tritanopia)
        viewModel.save()

        #expect(viewModel.isEditing == false)
        #expect(storage.settings.backgroundBrightness == 0.8)
        #expect(storage.settings.colorVisionSimulation == .tritanopia)
    }

    /// Given an editing session with an unsaved brightness change, when
    /// `cancel()` is called, then editing ends and the draft is reverted to the
    /// stored settings (the change is discarded).
    @Test func cancelDiscardsDraftChanges() {
        let storage = StorageService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
        let viewModel = SettingsViewModel(storageService: storage)

        viewModel.beginEditing()
        viewModel.setDraftBrightness(0.7)
        viewModel.cancel()

        #expect(viewModel.isEditing == false)
        #expect(viewModel.draftSettings == storage.settings)
    }
}

// MARK: - StatisticsViewModel

/// Behavior of `StatisticsViewModel` — deriving the parent-facing summary
/// (total stars, completed count, per-competency items, and guidance content)
/// from persisted progress plus static story content.
@MainActor
@Suite("StatisticsViewModel")
struct StatisticsViewModelTests {

    /// Given no completed chapters, then Statistics exposes zero summary values
    /// and zero-score competency rows for the empty-state UI.
    @Test func emptyProgressReportsZeroSummaryAndZeroCompetencies() {
        let storage = StorageService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
        let viewModel = StatisticsViewModel(stories: StoryCatalog.stories, storageService: storage)

        #expect(viewModel.totalStars == 0)
        #expect(viewModel.completedChapterCount == 0)
        #expect(viewModel.completedStoryCount == 0)
        #expect(viewModel.competencyItems.map(\.score) == [0, 0, 0, 0, 0])
        #expect(viewModel.competencyItems.allSatisfy { $0.maximumScore == 3 })
    }

    /// Given partial progress, then competency rows use the app's Statistics
    /// order and map chapter best stars directly onto the 0/3, 1/3, 2/3, 3/3
    /// row scores.
    @Test func competencyItemsUseThreeStarScoresInStatisticsOrder() {
        let storage = StorageService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
        let viewModel = StatisticsViewModel(stories: StoryCatalog.stories, storageService: storage)

        storage.updateUserStats { stats in
            stats.recordCompletedGame(chapterID: "chapter-1", earnedStars: 3)
            stats.recordCompletedGame(chapterID: "chapter-2", earnedStars: 2)
            stats.recordCompletedGame(chapterID: "chapter-3", earnedStars: 1)
            stats.recordCompletedGame(chapterID: "chapter-4", earnedStars: 3)
        }

        #expect(viewModel.competencyItems.map(\.competency) == [
            .shape,
            .labelSymbol,
            .brightnessContrast,
            .pattern,
            .context
        ])
        #expect(viewModel.competencyItems.map(\.chapterID) == [
            "chapter-1",
            "chapter-2",
            "chapter-3",
            "chapter-4",
            "chapter-5"
        ])
        #expect(viewModel.competencyItems.map(\.score) == [3, 2, 1, 3, 0])
        #expect(viewModel.totalStars == 9)
        #expect(viewModel.completedChapterCount == 4)
        #expect(viewModel.completedStoryCount == 0)
    }

    /// Given all five playable chapters are completed, then Statistics reports
    /// the playable story as completed and sums all collected stars.
    @Test func completedStoryCountReflectsFullyCompletedPlayableStory() {
        let storage = StorageService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
        let viewModel = StatisticsViewModel(stories: StoryCatalog.stories, storageService: storage)

        storage.updateUserStats { stats in
            for chapterID in ["chapter-1", "chapter-2", "chapter-3", "chapter-4", "chapter-5"] {
                stats.recordCompletedGame(chapterID: chapterID, earnedStars: 3)
            }
        }

        #expect(viewModel.totalStars == 15)
        #expect(viewModel.completedChapterCount == 5)
        #expect(viewModel.completedStoryCount == 1)
    }

    /// Every displayed competency must have static parent-facing guidance, since
    /// the Statistics detail pane depends on that content and it is not stored in
    /// persisted `UserStats`.
    @Test func guidanceExistsForEveryDisplayedCompetency() throws {
        let storage = StorageService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
        let viewModel = StatisticsViewModel(stories: StoryCatalog.stories, storageService: storage)

        for item in viewModel.competencyItems {
            let guidance = try #require(viewModel.guidance(for: item.competency))
            #expect(guidance.learningSummary.isEmpty == false)
            #expect(guidance.masteredItems.isEmpty == false)
            #expect(guidance.practiceItems.isEmpty == false)
            #expect(guidance.parentTip.isEmpty == false)
        }
    }
}

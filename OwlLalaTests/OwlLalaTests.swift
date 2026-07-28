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
    
    /// Given a selected chapter, when `clearSelection()` is called,
    /// then `selectedChapter` is reset to `nil`.
    @Test func clearSelectionResetsSelectedChapter() {
            let chapters = (1...3).map { i in Chapter(id: "chapter-\(i)", order: i, title: "Bab", subtitle: nil, description: "d", thumbnailAssetName: "t", competency: .shape, storyPages: [], gameConfiguration: GameConfiguration(question: GameQuestion(id: "q", prompt: "p", promptImageAssetName: nil, answerOptions: [AnswerOption(id: "c", text: "B", imageAssetName: nil)], correctAnswerID: "c", hintText: "h")), learningSummary: LearningSummary(successMessage: "s", explanation: "e", mainIllustrationAssetName: "m", exampleAssetNames: [])) }
            let story = Story(id: "story-1", order: 1, title: "Cerita", subtitle: nil, description: "d", coverAssetName: "c", availability: .available, chapters: chapters, completionSummary: nil)
            let viewModel = ChapterSelectionViewModel(story: story, storageService: StorageService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!))

            viewModel.selectChapter(story.chapters[0])
            #expect(viewModel.selectedChapter?.id == "chapter-1")

            viewModel.clearSelection()
            #expect(viewModel.selectedChapter == nil)
        }
}

// MARK: - TrainingModeViewModel

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

    /// Given locked training mode, selecting a chapter does nothing; when training mode unlocks,
    /// selecting a chapter sets `selectedChapter`.
    @Test func selectChapterGatedByTrainingUnlockState() {
        let chapters = [Chapter(id: "chapter-1", order: 1, title: "Bab", subtitle: nil, description: "d", thumbnailAssetName: "t", competency: .shape, storyPages: [], gameConfiguration: GameConfiguration(question: GameQuestion(id: "q", prompt: "p", promptImageAssetName: nil, answerOptions: [AnswerOption(id: "c", text: "B", imageAssetName: nil)], correctAnswerID: "c", hintText: "h")), learningSummary: LearningSummary(successMessage: "s", explanation: "e", mainIllustrationAssetName: "m", exampleAssetNames: []))]
        let story = Story(id: "story-1", order: 1, title: "Cerita", subtitle: nil, description: "d", coverAssetName: "c", availability: .available, chapters: chapters, completionSummary: nil)
        let storage = StorageService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
        let viewModel = TrainingModeViewModel(story: story, storageService: storage)

        // Attempt selection while locked
        viewModel.selectChapter(story.chapters[0])
        #expect(viewModel.selectedChapter == nil)

        // Complete story to unlock training
        storage.updateUserStats { stats in
            stats.recordCompletedGame(chapterID: "chapter-1", earnedStars: 3)
        }

        // Attempt selection while unlocked
        viewModel.selectChapter(story.chapters[0])
        #expect(viewModel.selectedChapter?.id == "chapter-1")
    }

    /// Given a selected chapter in training mode, when `clearSelection()` is called,
    /// then `selectedChapter` is reset to `nil`.
    @Test func clearSelectionResetsSelectedChapter() {
        let chapters = [Chapter(id: "chapter-1", order: 1, title: "Bab", subtitle: nil, description: "d", thumbnailAssetName: "t", competency: .shape, storyPages: [], gameConfiguration: GameConfiguration(question: GameQuestion(id: "q", prompt: "p", promptImageAssetName: nil, answerOptions: [AnswerOption(id: "c", text: "B", imageAssetName: nil)], correctAnswerID: "c", hintText: "h")), learningSummary: LearningSummary(successMessage: "s", explanation: "e", mainIllustrationAssetName: "m", exampleAssetNames: []))]
        let story = Story(id: "story-1", order: 1, title: "Cerita", subtitle: nil, description: "d", coverAssetName: "c", availability: .available, chapters: chapters, completionSummary: nil)
        let storage = StorageService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
        let viewModel = TrainingModeViewModel(story: story, storageService: storage)

        storage.updateUserStats { stats in
            stats.recordCompletedGame(chapterID: "chapter-1", earnedStars: 3)
        }

        viewModel.selectChapter(story.chapters[0])
        #expect(viewModel.selectedChapter?.id == "chapter-1")

        viewModel.clearSelection()
        #expect(viewModel.selectedChapter == nil)
    }

    /// Given completed gameplay stats in storage, `TrainingModeViewModel.items` maps
    /// `isUnlocked`, `bestStars`, and `playCount` for every chapter.
    @Test func trainingItemsReflectPersistedPlayCountAndBestStars() {
        let chapters = [Chapter(id: "chapter-1", order: 1, title: "Bab", subtitle: nil, description: "d", thumbnailAssetName: "t", competency: .shape, storyPages: [], gameConfiguration: GameConfiguration(question: GameQuestion(id: "q", prompt: "p", promptImageAssetName: nil, answerOptions: [AnswerOption(id: "c", text: "B", imageAssetName: nil)], correctAnswerID: "c", hintText: "h")), learningSummary: LearningSummary(successMessage: "s", explanation: "e", mainIllustrationAssetName: "m", exampleAssetNames: []))]
        let story = Story(id: "story-1", order: 1, title: "Cerita", subtitle: nil, description: "d", coverAssetName: "c", availability: .available, chapters: chapters, completionSummary: nil)
        let storage = StorageService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
        
        storage.updateUserStats { stats in
            stats.recordCompletedGame(chapterID: "chapter-1", earnedStars: 3)
            stats.recordCompletedGame(chapterID: "chapter-1", earnedStars: 2) // play count = 2
        }

        let viewModel = TrainingModeViewModel(story: story, storageService: storage)

        #expect(viewModel.items.count == 1)
        #expect(viewModel.items[0].isUnlocked == true)
        #expect(viewModel.items[0].bestStars == 3)
        #expect(viewModel.items[0].playCount == 2)
    }
}

// MARK: - StorySelectionViewModel

@MainActor
@Suite("StorySelectionViewModel")
struct StorySelectionViewModelTests {

    /// The view model owns its built-in story list: selecting an
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

    /// Given a custom set of injected stories, the view model's items match the injected story availability.
    @Test func customInjectedStoriesMapToItems() {
        let availableStory = Story(id: "s1", order: 1, title: "S1", subtitle: nil, description: "d", coverAssetName: "c", availability: .available, chapters: [], completionSummary: nil)
        let comingSoonStory = Story(id: "s2", order: 2, title: "S2", subtitle: nil, description: "d", coverAssetName: "c", availability: .comingSoon, chapters: [], completionSummary: nil)
        
        let viewModel = StorySelectionViewModel(stories: [availableStory, comingSoonStory])

        #expect(viewModel.items.count == 2)
        #expect(viewModel.items[0].isAvailable == true)
        #expect(viewModel.items[1].isAvailable == false)
    }

    /// Given a selected story, when `clearSelection()` is called, then `selectedStory` is reset to `nil`.
    @Test func clearSelectionResetsSelectedStory() {
        let viewModel = StorySelectionViewModel()
        guard let available = viewModel.items.first(where: { $0.isAvailable })?.story else { return }

        viewModel.selectStory(available)
        #expect(viewModel.selectedStory != nil)

        viewModel.clearSelection()
        #expect(viewModel.selectedStory == nil)
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


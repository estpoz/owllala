//
//  OwlLalaTests.swift
//  OwlLalaTests
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//
//  Focused TDD tests for the view-model functions, written with Swift Testing.
//  https://developer.apple.com/documentation/testing
//
//  Each test builds the inputs a view model needs by calling the real
//  Model/Service initializers inline, then calls the view model's own functions.
//  No models or view models are defined in this file.
//

import Foundation
import Testing
@testable import OwlLala

// MARK: - ChapterGameplayViewModel

@MainActor
@Suite("ChapterGameplayViewModel")
struct ChapterGameplayViewModelTests {

    @Test func storyNavigationRevealsQuestionAfterLastPage() {
        let chapter = Chapter(id: "chapter-1", order: 1, title: "Bab", subtitle: nil, description: "d", thumbnailAssetName: "t", competency: .shape, storyPages: [StoryPage(id: "p1", order: 1, illustrationAssetName: "i", narration: "n", voiceOverAssetName: nil)], gameConfiguration: GameConfiguration(question: GameQuestion(id: "q", prompt: "p", promptImageAssetName: nil, answerOptions: [AnswerOption(id: "correct", text: "B", imageAssetName: nil)], correctAnswerID: "correct", hintText: "h")), learningSummary: LearningSummary(successMessage: "s", explanation: "e", mainIllustrationAssetName: "m", exampleAssetNames: []))
        let viewModel = ChapterGameplayViewModel(chapter: chapter, source: .mainStory, nextChapterID: "chapter-2", storageService: StorageService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!))

        #expect(viewModel.isQuestionPresented == false)
        viewModel.goToNextStoryPage()
        #expect(viewModel.isQuestionPresented == true)
    }

    @Test func selectingCorrectAnswerOnFirstTryEarnsThreeStars() {
        let chapter = Chapter(id: "chapter-1", order: 1, title: "Bab", subtitle: nil, description: "d", thumbnailAssetName: "t", competency: .shape, storyPages: [], gameConfiguration: GameConfiguration(question: GameQuestion(id: "q", prompt: "p", promptImageAssetName: nil, answerOptions: [AnswerOption(id: "correct", text: "B", imageAssetName: nil), AnswerOption(id: "wrong", text: "S", imageAssetName: nil)], correctAnswerID: "correct", hintText: "h")), learningSummary: LearningSummary(successMessage: "s", explanation: "e", mainIllustrationAssetName: "m", exampleAssetNames: []))
        let viewModel = ChapterGameplayViewModel(chapter: chapter, source: .mainStory, nextChapterID: "chapter-2", storageService: StorageService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!))

        viewModel.selectAnswer(AnswerOption(id: "correct", text: "B", imageAssetName: nil))

        #expect(viewModel.isCorrectFeedbackPresented == true)
        #expect(viewModel.earnedStars == 3)
    }

    @Test func retryingAfterAWrongAnswerEarnsTwoStars() {
        let chapter = Chapter(id: "chapter-1", order: 1, title: "Bab", subtitle: nil, description: "d", thumbnailAssetName: "t", competency: .shape, storyPages: [], gameConfiguration: GameConfiguration(question: GameQuestion(id: "q", prompt: "p", promptImageAssetName: nil, answerOptions: [AnswerOption(id: "correct", text: "B", imageAssetName: nil), AnswerOption(id: "wrong", text: "S", imageAssetName: nil)], correctAnswerID: "correct", hintText: "h")), learningSummary: LearningSummary(successMessage: "s", explanation: "e", mainIllustrationAssetName: "m", exampleAssetNames: []))
        let viewModel = ChapterGameplayViewModel(chapter: chapter, source: .mainStory, nextChapterID: "chapter-2", storageService: StorageService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!))

        viewModel.selectAnswer(AnswerOption(id: "wrong", text: "S", imageAssetName: nil))
        #expect(viewModel.wrongAnswerCount == 1)

        viewModel.selectAnswer(AnswerOption(id: "correct", text: "B", imageAssetName: nil))
        #expect(viewModel.earnedStars == 2)
    }

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

    @Test func selectChapterOnlySelectsUnlockedChapters() {
        let chapters = (1...5).map { i in Chapter(id: "chapter-\(i)", order: i, title: "Bab", subtitle: nil, description: "d", thumbnailAssetName: "t", competency: .shape, storyPages: [], gameConfiguration: GameConfiguration(question: GameQuestion(id: "q", prompt: "p", promptImageAssetName: nil, answerOptions: [AnswerOption(id: "c", text: "B", imageAssetName: nil)], correctAnswerID: "c", hintText: "h")), learningSummary: LearningSummary(successMessage: "s", explanation: "e", mainIllustrationAssetName: "m", exampleAssetNames: [])) }
        let story = Story(id: "story-1", order: 1, title: "Cerita", subtitle: nil, description: "d", coverAssetName: "c", availability: .available, chapters: chapters, completionSummary: nil)
        let viewModel = ChapterSelectionViewModel(story: story, storageService: StorageService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!))

        viewModel.selectChapter(story.chapters[2]) // locked
        #expect(viewModel.selectedChapter == nil)

        viewModel.selectChapter(story.chapters[0]) // unlocked
        #expect(viewModel.selectedChapter?.id == "chapter-1")
    }

    @Test func nextChapterIDReturnsFollowingChapterOrNil() {
        let chapters = (1...5).map { i in Chapter(id: "chapter-\(i)", order: i, title: "Bab", subtitle: nil, description: "d", thumbnailAssetName: "t", competency: .shape, storyPages: [], gameConfiguration: GameConfiguration(question: GameQuestion(id: "q", prompt: "p", promptImageAssetName: nil, answerOptions: [AnswerOption(id: "c", text: "B", imageAssetName: nil)], correctAnswerID: "c", hintText: "h")), learningSummary: LearningSummary(successMessage: "s", explanation: "e", mainIllustrationAssetName: "m", exampleAssetNames: [])) }
        let story = Story(id: "story-1", order: 1, title: "Cerita", subtitle: nil, description: "d", coverAssetName: "c", availability: .available, chapters: chapters, completionSummary: nil)
        let viewModel = ChapterSelectionViewModel(story: story, storageService: StorageService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!))

        #expect(viewModel.nextChapterID(after: story.chapters[0]) == "chapter-2")
        #expect(viewModel.nextChapterID(after: story.chapters[4]) == nil)
    }
}

// MARK: - TrainingModeViewModel

@MainActor
@Suite("TrainingModeViewModel")
struct TrainingModeViewModelTests {

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

    @Test func makeGameplayViewModelUsesTrainingSource() {
        let chapters = (1...5).map { i in Chapter(id: "chapter-\(i)", order: i, title: "Bab", subtitle: nil, description: "d", thumbnailAssetName: "t", competency: .shape, storyPages: [], gameConfiguration: GameConfiguration(question: GameQuestion(id: "q", prompt: "p", promptImageAssetName: nil, answerOptions: [AnswerOption(id: "c", text: "B", imageAssetName: nil)], correctAnswerID: "c", hintText: "h")), learningSummary: LearningSummary(successMessage: "s", explanation: "e", mainIllustrationAssetName: "m", exampleAssetNames: [])) }
        let story = Story(id: "story-1", order: 1, title: "Cerita", subtitle: nil, description: "d", coverAssetName: "c", availability: .available, chapters: chapters, completionSummary: nil)
        let viewModel = TrainingModeViewModel(story: story, storageService: StorageService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!))

        let gameplay = viewModel.makeGameplayViewModel(for: story.chapters[0])

        #expect(gameplay.source == .training)
        #expect(gameplay.nextChapterID == nil)
    }
}

// MARK: - StorySelectionViewModel

@MainActor
@Suite("StorySelectionViewModel")
struct StorySelectionViewModelTests {

    @Test func selectStoryOnlySelectsAvailableStories() {
        let available = Story(id: "story-1", order: 1, title: "Cerita 1", subtitle: nil, description: "d", coverAssetName: "c", availability: .available, chapters: [], completionSummary: nil)
        let comingSoon = Story(id: "story-2", order: 2, title: "Cerita 2", subtitle: nil, description: "d", coverAssetName: "c", availability: .comingSoon, chapters: [], completionSummary: nil)
        let viewModel = StorySelectionViewModel(stories: [available, comingSoon])

        viewModel.selectStory(comingSoon)
        #expect(viewModel.selectedStory == nil)

        viewModel.selectStory(available)
        #expect(viewModel.selectedStory?.id == "story-1")
    }
}

// MARK: - MainMenuViewModel

@MainActor
@Suite("MainMenuViewModel")
struct MainMenuViewModelTests {

    @Test func selectAndClearDestination() {
        let viewModel = MainMenuViewModel()

        viewModel.select(.statistics)
        #expect(viewModel.destination == .statistics)

        viewModel.clearDestination()
        #expect(viewModel.destination == nil)
    }
}

// MARK: - SettingsViewModel

@MainActor
@Suite("SettingsViewModel")
struct SettingsViewModelTests {

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

@MainActor
@Suite("StatisticsViewModel")
struct StatisticsViewModelTests {

    @Test func summaryValuesReflectRecordedProgress() {
        let chapters = Competency.allCases.enumerated().map { i, c in Chapter(id: "chapter-\(i + 1)", order: i + 1, title: "Bab", subtitle: nil, description: "d", thumbnailAssetName: "t", competency: c, storyPages: [], gameConfiguration: GameConfiguration(question: GameQuestion(id: "q", prompt: "p", promptImageAssetName: nil, answerOptions: [AnswerOption(id: "c", text: "B", imageAssetName: nil)], correctAnswerID: "c", hintText: "h")), learningSummary: LearningSummary(successMessage: "s", explanation: "e", mainIllustrationAssetName: "m", exampleAssetNames: [])) }
        let story = Story(id: "story-1", order: 1, title: "Cerita", subtitle: nil, description: "d", coverAssetName: "c", availability: .available, chapters: chapters, completionSummary: nil)
        let storage = StorageService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
        let viewModel = StatisticsViewModel(stories: [story], storageService: storage)

        storage.updateUserStats { stats in
            stats.recordCompletedGame(chapterID: "chapter-1", earnedStars: 3)
            stats.recordCompletedGame(chapterID: "chapter-2", earnedStars: 2)
        }

        #expect(viewModel.totalStars == 5)
        #expect(viewModel.completedChapterCount == 2)
        #expect(viewModel.competencyItems.count == 5)
    }
}

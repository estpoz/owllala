//
//  ChapterGamePlayVMTests.swift
//  OwlLala
//
//  Created by Amanda on 28/07/26.
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

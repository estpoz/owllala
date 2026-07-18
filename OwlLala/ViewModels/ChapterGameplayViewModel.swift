//
//  ChapterGameplayViewModel.swift
//  OwlLala
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//

import Combine
import Foundation

// MARK: - Gameplay Source

enum GameplaySource: Hashable, Sendable {
    case mainStory
    case training
}

// MARK: - Chapter Gameplay View Model

/// Owns the state transitions for one chapter mini-game.
@MainActor
final class ChapterGameplayViewModel: ObservableObject {

    enum Destination: Hashable {
        case stageCleared
        case chapterList
        case trainingList
        case storyCompletion
    }

    @Published private(set) var currentStoryPageIndex: Int
    @Published private(set) var isQuestionPresented: Bool
    @Published private(set) var selectedAnswerID: String?
    @Published private(set) var incorrectAnswerID: String?
    @Published private(set) var wrongAnswerCount: Int
    @Published private(set) var shakeTrigger: Int
    @Published private(set) var isHintPresented: Bool
    @Published private(set) var isCorrectFeedbackPresented: Bool
    @Published private(set) var earnedStars: Int?
    @Published private(set) var destination: Destination?

    let chapter: Chapter
    let source: GameplaySource
    let nextChapterID: String?

    private let storageService: StorageService
    private var didSaveCompletion = false

    var currentStoryPage: StoryPage? {
        guard chapter.storyPages.indices.contains(currentStoryPageIndex) else {
            return nil
        }

        return chapter.storyPages[currentStoryPageIndex]
    }

    var question: GameQuestion {
        chapter.gameConfiguration.question
    }

    var isFirstStoryPage: Bool {
        currentStoryPageIndex == 0
    }

    var isLastStoryPage: Bool {
        guard !chapter.storyPages.isEmpty else {
            return true
        }

        return currentStoryPageIndex == chapter.storyPages.index(before: chapter.storyPages.endIndex)
    }

    init(
        chapter: Chapter,
        source: GameplaySource,
        nextChapterID: String? = nil,
        storageService: StorageService
    ) {
        self.chapter = chapter
        self.source = source
        self.nextChapterID = nextChapterID
        self.storageService = storageService
        self.currentStoryPageIndex = 0
        self.isQuestionPresented = source == .training || chapter.storyPages.isEmpty
        self.selectedAnswerID = nil
        self.incorrectAnswerID = nil
        self.wrongAnswerCount = 0
        self.shakeTrigger = 0
        self.isHintPresented = false
        self.isCorrectFeedbackPresented = false
        self.earnedStars = nil
        self.destination = nil
    }

    func goToNextStoryPage() {
        guard !isQuestionPresented else {
            return
        }

        let nextIndex = chapter.storyPages.index(after: currentStoryPageIndex)
        if chapter.storyPages.indices.contains(nextIndex) {
            currentStoryPageIndex = nextIndex
        } else {
            isQuestionPresented = true
        }
    }

    func goToPreviousStoryPage() {
        guard !isQuestionPresented, currentStoryPageIndex > 0 else {
            return
        }

        currentStoryPageIndex -= 1
    }

    func startQuestion() {
        isQuestionPresented = true
    }

    func selectAnswer(_ option: AnswerOption) {
        guard !isCorrectFeedbackPresented, !didSaveCompletion else {
            return
        }

        selectedAnswerID = option.id

        guard option.id == question.correctAnswerID else {
            recordIncorrectAnswer(option.id)
            return
        }

        incorrectAnswerID = nil
        earnedStars = calculateStars(wrongAnswerCount: wrongAnswerCount)
        isCorrectFeedbackPresented = true
    }

    func dismissHint() {
        isHintPresented = false
    }

    /// Persists completion after the view finishes correct-answer feedback.
    func finishCorrectFeedback() {
        guard let earnedStars, !didSaveCompletion else {
            return
        }

        didSaveCompletion = true
        isCorrectFeedbackPresented = false

        storageService.updateUserStats { userStats in
            userStats.recordCompletedGame(
                chapterID: chapter.id,
                earnedStars: earnedStars
            )

            if source == .mainStory {
                userStats.completeChapter(nextChapterID: nextChapterID)
            }
        }

        destination = .stageCleared
    }

    /// Emits the destination that follows the reusable stage-cleared screen.
    func finishStageCleared() {
        switch source {
        case .mainStory:
            destination = nextChapterID == nil ? .storyCompletion : .chapterList

        case .training:
            destination = .trainingList
        }
    }

    func clearDestination() {
        destination = nil
    }

    func resetForReplay() {
        currentStoryPageIndex = 0
        isQuestionPresented = source == .training || chapter.storyPages.isEmpty
        selectedAnswerID = nil
        incorrectAnswerID = nil
        wrongAnswerCount = 0
        shakeTrigger = 0
        isHintPresented = false
        isCorrectFeedbackPresented = false
        earnedStars = nil
        destination = nil
        didSaveCompletion = false
    }

    private func recordIncorrectAnswer(_ answerID: String) {
        wrongAnswerCount += 1
        incorrectAnswerID = answerID
        shakeTrigger += 1

        if wrongAnswerCount == 2 {
            isHintPresented = true
        }
    }

    private func calculateStars(wrongAnswerCount: Int) -> Int {
        switch wrongAnswerCount {
        case 0:
            return 3

        case 1:
            return 2

        default:
            return 1
        }
    }
}

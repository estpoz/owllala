//
//  ExitConfirmationTests.swift
//  OwlLalaTests
//
//  Comprehensive Exit Confirmation TDD: the dialog's closure contract, the
//  "Keluar" path that discards the unsaved score of the current attempt, and
//  the "Kembali Belajar" path that must leave the session untouched.
//
//  `ExitConfirmation` is presentation-only — it owns no state and simply runs
//  the two closures it is handed — so `ExitConfirmationHost` below mirrors how
//  `ChapterGamePlayView` wires those closures. That way the tests exercise the
//  real component together with the behaviour the host attaches to it, without
//  rendering a SwiftUI view.
//

import Foundation
import Testing
@testable import OwlLala

// MARK: - Exit Confirmation Test Helpers

/// The option that scores the chapter.
private let correctAnswer = AnswerOption(id: "correct", text: "Benar", imageAssetName: nil)

/// An option that costs a star.
private let wrongAnswer = AnswerOption(id: "wrong", text: "Salah", imageAssetName: nil)

@MainActor
private func makeGameplayStorage() -> StorageService {
    StorageService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
}

/// Builds a chapter for gameplay tests.
///
/// - Parameters:
///   - id: Chapter identifier used for progress lookups.
///   - storyPageCount: How many story pages precede the question.
/// - Returns: A chapter with one correct and one wrong answer option.
private func makeGameplayChapter(
    id: String = "chapter-1",
    storyPageCount: Int = 3
) -> Chapter {
    let storyPages = (0 ..< max(storyPageCount, 0)).map { index in
        StoryPage(
            id: "\(id)-page-\(index + 1)",
            order: index + 1,
            illustrationAssetName: "illustration",
            narration: "Narasi halaman \(index + 1)",
            voiceOverAssetName: nil
        )
    }

    return Chapter(
        id: id,
        order: 1,
        title: "Bab Uji",
        subtitle: nil,
        description: "Deskripsi",
        thumbnailAssetName: "thumbnail",
        competency: .shape,
        storyPages: storyPages,
        gameConfiguration: GameConfiguration(
            question: GameQuestion(
                id: "question",
                prompt: "Pertanyaan",
                promptImageAssetName: nil,
                answerOptions: [correctAnswer, wrongAnswer],
                correctAnswerID: correctAnswer.id,
                hintText: "Petunjuk"
            )
        ),
        learningSummary: LearningSummary(
            successMessage: "Berhasil",
            explanation: "Penjelasan",
            mainIllustrationAssetName: "illustration",
            exampleAssetNames: []
        )
    )
}

/// Mirrors how `ChapterGamePlayView` presents `ExitConfirmation` and what each
/// of its two actions does, so the suites can assert on the real wiring.
///
/// The closure bodies below match the view's:
///
///     showExitConfirmation()  → stopStoryVoiceOver(); isShowingExitConfirmation = true
///     onContinueLearning      → isShowingExitConfirmation = false; resumeStoryVoiceOverIfNeeded()
///     onDiscardProgress       → stopGameplayAudio(); isShowingExitConfirmation = false; dismiss()
@MainActor
private final class ExitConfirmationHost {

    /// The gameplay session the dialog is shown over.
    let viewModel: ChapterGameplayViewModel

    /// The store the session would persist to.
    let storage: StorageService

    /// Whether the confirmation dialog is currently presented.
    private(set) var isShowingExitConfirmation = false

    /// Whether the gameplay screen was dismissed (the child left the chapter).
    private(set) var didDismissGameplay = false

    /// Whether story voice-over was paused for the dialog.
    private(set) var didStopStoryVoiceOver = false

    /// Whether gameplay audio was torn down on the way out.
    private(set) var didStopGameplayAudio = false

    /// Whether narration resumed after choosing to stay.
    private(set) var didResumeStoryVoiceOver = false

    init(storyPageCount: Int = 3, source: GameplaySource = .mainStory) {
        let storage = makeGameplayStorage()
        self.storage = storage
        self.viewModel = ChapterGameplayViewModel(
            chapter: makeGameplayChapter(storyPageCount: storyPageCount),
            source: source,
            nextChapterID: "chapter-2",
            storageService: storage
        )
    }

    /// Mirrors the gameplay top bar's exit button.
    func tapExitButton() {
        didStopStoryVoiceOver = true
        isShowingExitConfirmation = true
    }

    /// The dialog the host presents, wired exactly like `ChapterGamePlayView`.
    func makeDialog() -> ExitConfirmation {
        ExitConfirmation(
            onContinueLearning: {
                self.isShowingExitConfirmation = false
                self.didResumeStoryVoiceOver = true
            },
            onDiscardProgress: {
                self.didStopGameplayAudio = true
                self.isShowingExitConfirmation = false
                self.didDismissGameplay = true
            }
        )
    }
}

// MARK: - Component Contract

/// `ExitConfirmation` is presentation-only, so its whole contract is "hold two
/// actions and run exactly the one that was chosen". These tests pin that it
/// never acts on its own, never confuses the two actions, and never writes.
@MainActor
@Suite("Exit Confirmation — Component Contract")
struct ExitConfirmationComponentTests {

    /// Building the dialog runs neither action — it only shows the question.
    @Test func buildingTheDialogRunsNeitherAction() {
        var continueCount = 0
        var discardCount = 0

        _ = ExitConfirmation(
            onContinueLearning: { continueCount += 1 },
            onDiscardProgress: { discardCount += 1 }
        )

        #expect(continueCount == 0)
        #expect(discardCount == 0)
    }

    /// "Kembali Belajar" runs only the stay action.
    @Test func continueLearningRunsOnlyTheStayAction() {
        var continueCount = 0
        var discardCount = 0
        let dialog = ExitConfirmation(
            onContinueLearning: { continueCount += 1 },
            onDiscardProgress: { discardCount += 1 }
        )

        dialog.onContinueLearning()

        #expect(continueCount == 1)
        #expect(discardCount == 0)
    }

    /// "Keluar" runs only the leave action.
    @Test func discardProgressRunsOnlyTheLeaveAction() {
        var continueCount = 0
        var discardCount = 0
        let dialog = ExitConfirmation(
            onContinueLearning: { continueCount += 1 },
            onDiscardProgress: { discardCount += 1 }
        )

        dialog.onDiscardProgress()

        #expect(discardCount == 1)
        #expect(continueCount == 0)
    }

    /// The dialog holds no state of its own, so the host stays in control of
    /// dismissal — a second tap runs the action again rather than being
    /// swallowed.
    @Test func actionsAreNotSwallowedAfterTheFirstTap() {
        var continueCount = 0
        let dialog = ExitConfirmation(
            onContinueLearning: { continueCount += 1 },
            onDiscardProgress: {}
        )

        dialog.onContinueLearning()
        dialog.onContinueLearning()

        #expect(continueCount == 2)
    }

    /// Two dialogs are independent values; running one does not affect another.
    @Test func separateDialogsAreIndependent() {
        var firstCount = 0
        var secondCount = 0
        let first = ExitConfirmation(
            onContinueLearning: { firstCount += 1 },
            onDiscardProgress: {}
        )
        let second = ExitConfirmation(
            onContinueLearning: { secondCount += 1 },
            onDiscardProgress: {}
        )

        first.onContinueLearning()

        #expect(firstCount == 1)
        #expect(secondCount == 0)
    }

    /// The component itself never writes progress — only the host's action
    /// bodies can. Building and running both actions leaves the store untouched.
    @Test func theComponentNeverTouchesStorageItself() {
        let host = ExitConfirmationHost()
        let statsBefore = host.storage.userStats

        let dialog = host.makeDialog()
        dialog.onContinueLearning()
        dialog.onDiscardProgress()

        #expect(host.storage.userStats == statsBefore)
    }
}

// MARK: - Discarding Progress

/// The promise the dialog makes when the child confirms leaving: the score
/// earned in this session is thrown away. `ChapterGameplayViewModel` only ever
/// persists inside `finishCorrectFeedback()`, so these tests pin that leaving
/// from every earlier point records nothing — and that progress already saved
/// is NOT retroactively removed.
@MainActor
@Suite("Exit Confirmation — Discarding Progress")
struct ExitConfirmationDiscardProgressTests {

    /// Leaving straight away records nothing.
    @Test func leavingBeforePlayingRecordsNothing() {
        let host = ExitConfirmationHost()
        let statsBefore = host.storage.userStats

        host.tapExitButton()
        host.makeDialog().onDiscardProgress()

        #expect(host.storage.userStats == statsBefore)
        #expect(host.storage.userStats.isChapterCompleted("chapter-1") == false)
    }

    /// Reading part of the story is not progress worth saving.
    @Test func leavingMidStoryRecordsNothing() {
        let host = ExitConfirmationHost(storyPageCount: 3)
        let statsBefore = host.storage.userStats

        host.viewModel.goToNextStoryPage()
        #expect(host.viewModel.currentStoryPageIndex == 1)

        host.tapExitButton()
        host.makeDialog().onDiscardProgress()

        #expect(host.storage.userStats == statsBefore)
    }

    /// Wrong attempts are not persisted either.
    @Test func leavingAfterWrongAnswersRecordsNothing() {
        let host = ExitConfirmationHost(storyPageCount: 0)
        let statsBefore = host.storage.userStats

        host.viewModel.selectAnswer(wrongAnswer)
        host.viewModel.selectAnswer(wrongAnswer)
        #expect(host.viewModel.wrongAnswerCount == 2)

        host.tapExitButton()
        host.makeDialog().onDiscardProgress()

        #expect(host.storage.userStats == statsBefore)
        #expect(host.storage.userStats.playCount(for: "chapter-1") == 0)
    }

    /// The important edge: the child answered correctly and stars are showing,
    /// but the celebration has not finished, so nothing is saved yet. Leaving
    /// here loses those stars — exactly what the dialog warns about.
    @Test func leavingAfterACorrectAnswerButBeforeFeedbackFinishesLosesTheStars() {
        let host = ExitConfirmationHost(storyPageCount: 0)
        let statsBefore = host.storage.userStats

        host.viewModel.selectAnswer(correctAnswer)
        #expect(host.viewModel.earnedStars == 3)
        #expect(host.viewModel.isCorrectFeedbackPresented)

        host.tapExitButton()
        host.makeDialog().onDiscardProgress()

        #expect(host.storage.userStats == statsBefore)
        #expect(host.storage.userStats.bestStars(for: "chapter-1") == 0)
        #expect(host.storage.userStats.isChapterCompleted("chapter-1") == false)
    }

    /// Leaving never unlocks what completing would have unlocked.
    @Test func leavingDoesNotUnlockTheNextChapter() {
        let host = ExitConfirmationHost(storyPageCount: 0)

        host.viewModel.selectAnswer(correctAnswer)
        host.tapExitButton()
        host.makeDialog().onDiscardProgress()

        #expect(host.storage.userStats.isChapterUnlocked("chapter-2") == false)
    }

    /// No stars, no completion count, no play count, no stats row.
    @Test func leavingLeavesEveryProgressCounterAtZero() {
        let host = ExitConfirmationHost(storyPageCount: 0)

        host.viewModel.selectAnswer(wrongAnswer)
        host.viewModel.selectAnswer(correctAnswer)
        host.tapExitButton()
        host.makeDialog().onDiscardProgress()

        #expect(host.storage.userStats.totalStars == 0)
        #expect(host.storage.userStats.completedChapterCount == 0)
        #expect(host.storage.userStats.playCount(for: "chapter-1") == 0)
        #expect(host.storage.userStats.stats(for: "chapter-1") == nil)
    }

    /// Training sessions discard the same way.
    @Test func leavingTrainingRecordsNothing() {
        let host = ExitConfirmationHost(storyPageCount: 0, source: .training)
        let statsBefore = host.storage.userStats

        host.viewModel.selectAnswer(correctAnswer)
        host.tapExitButton()
        host.makeDialog().onDiscardProgress()

        #expect(host.storage.userStats == statsBefore)
        #expect(host.storage.userStats.playCount(for: "chapter-1") == 0)
    }

    /// Leaving tears down gameplay audio, dismisses the screen, and closes the
    /// dialog on the way out.
    @Test func leavingStopsAudioAndDismissesGameplay() {
        let host = ExitConfirmationHost()
        host.tapExitButton()

        host.makeDialog().onDiscardProgress()

        #expect(host.didStopGameplayAudio)
        #expect(host.didDismissGameplay)
        #expect(host.isShowingExitConfirmation == false)
    }

    /// Progress that was already saved is NOT undone by leaving afterwards —
    /// the dialog only discards the unsaved score of the current attempt.
    @Test func alreadySavedProgressSurvivesLeaving() {
        let host = ExitConfirmationHost(storyPageCount: 0)

        host.viewModel.selectAnswer(correctAnswer)
        host.viewModel.finishCorrectFeedback()

        #expect(host.storage.userStats.bestStars(for: "chapter-1") == 3)

        host.tapExitButton()
        host.makeDialog().onDiscardProgress()

        #expect(host.storage.userStats.bestStars(for: "chapter-1") == 3)
        #expect(host.storage.userStats.isChapterCompleted("chapter-1"))
        #expect(host.storage.userStats.isChapterUnlocked("chapter-2"))
    }

    /// A discarded attempt leaves the chapter exactly as replayable as before,
    /// so a fresh session starts from the beginning with no stars.
    @Test func aFreshSessionAfterLeavingStartsFromScratch() {
        let host = ExitConfirmationHost(storyPageCount: 2)

        host.viewModel.goToNextStoryPage()
        host.viewModel.selectAnswer(wrongAnswer)
        host.tapExitButton()
        host.makeDialog().onDiscardProgress()

        let replay = ChapterGameplayViewModel(
            chapter: makeGameplayChapter(storyPageCount: 2),
            source: .mainStory,
            nextChapterID: "chapter-2",
            storageService: host.storage
        )

        #expect(replay.currentStoryPageIndex == 0)
        #expect(replay.wrongAnswerCount == 0)
        #expect(replay.earnedStars == nil)
        #expect(replay.isQuestionPresented == false)
    }
}

// MARK: - Continue Learning

/// The other half of the dialog: choosing "Kembali Belajar" must be completely
/// harmless. Opening the dialog and then staying has to leave the session
/// exactly where it was — same page, same attempts, same stars pending — and
/// must not dismiss gameplay or write anything.
@MainActor
@Suite("Exit Confirmation — Continue Learning")
struct ExitConfirmationContinueLearningTests {

    /// Tapping the exit button opens the dialog and pauses narration, without
    /// leaving the chapter.
    @Test func theExitButtonOpensTheDialogAndPausesNarration() {
        let host = ExitConfirmationHost()

        host.tapExitButton()

        #expect(host.isShowingExitConfirmation)
        #expect(host.didStopStoryVoiceOver)
        #expect(host.didDismissGameplay == false)
    }

    /// Staying closes the dialog and keeps the child in the chapter.
    @Test func stayingClosesTheDialogWithoutLeaving() {
        let host = ExitConfirmationHost()
        host.tapExitButton()

        host.makeDialog().onContinueLearning()

        #expect(host.isShowingExitConfirmation == false)
        #expect(host.didDismissGameplay == false)
        #expect(host.didStopGameplayAudio == false)
    }

    /// Staying resumes the narration that opening the dialog paused.
    @Test func stayingResumesNarration() {
        let host = ExitConfirmationHost()
        host.tapExitButton()

        host.makeDialog().onContinueLearning()

        #expect(host.didResumeStoryVoiceOver)
    }

    /// Mid-story position is untouched by the whole open-then-stay round trip.
    @Test func stayingKeepsTheStoryPosition() {
        let host = ExitConfirmationHost(storyPageCount: 3)
        host.viewModel.goToNextStoryPage()
        host.viewModel.goToNextStoryPage()
        let pageBefore = host.viewModel.currentStoryPageIndex

        host.tapExitButton()
        host.makeDialog().onContinueLearning()

        #expect(host.viewModel.currentStoryPageIndex == pageBefore)
        #expect(host.viewModel.isQuestionPresented == false)
    }

    /// Attempts already made are still counted, so the star penalty is not
    /// quietly reset by opening the dialog.
    @Test func stayingKeepsTheAttemptCount() {
        let host = ExitConfirmationHost(storyPageCount: 0)
        host.viewModel.selectAnswer(wrongAnswer)

        host.tapExitButton()
        host.makeDialog().onContinueLearning()

        #expect(host.viewModel.wrongAnswerCount == 1)
        #expect(host.viewModel.incorrectAnswerID == wrongAnswer.id)
    }

    /// Stars pending the celebration are still pending after staying.
    @Test func stayingKeepsPendingStars() {
        let host = ExitConfirmationHost(storyPageCount: 0)
        host.viewModel.selectAnswer(correctAnswer)

        host.tapExitButton()
        host.makeDialog().onContinueLearning()

        #expect(host.viewModel.earnedStars == 3)
        #expect(host.viewModel.isCorrectFeedbackPresented)
    }

    /// Staying writes nothing — it is purely a dismissal.
    @Test func stayingRecordsNothing() {
        let host = ExitConfirmationHost(storyPageCount: 0)
        let statsBefore = host.storage.userStats

        host.viewModel.selectAnswer(correctAnswer)
        host.tapExitButton()
        host.makeDialog().onContinueLearning()

        #expect(host.storage.userStats == statsBefore)
    }

    /// The session still completes normally afterwards, so staying does not
    /// break the path that DOES save progress.
    @Test func finishingAfterStayingStillSavesProgress() {
        let host = ExitConfirmationHost(storyPageCount: 0)

        host.viewModel.selectAnswer(correctAnswer)
        host.tapExitButton()
        host.makeDialog().onContinueLearning()

        host.viewModel.finishCorrectFeedback()

        #expect(host.storage.userStats.bestStars(for: "chapter-1") == 3)
        #expect(host.storage.userStats.isChapterCompleted("chapter-1"))
        #expect(host.storage.userStats.isChapterUnlocked("chapter-2"))
        #expect(host.viewModel.destination == .stageCleared)
    }

    /// Opening and staying repeatedly is harmless.
    @Test func repeatedlyOpeningAndStayingIsHarmless() {
        let host = ExitConfirmationHost(storyPageCount: 3)
        host.viewModel.goToNextStoryPage()
        let statsBefore = host.storage.userStats

        for _ in 0 ..< 5 {
            host.tapExitButton()
            host.makeDialog().onContinueLearning()
        }

        #expect(host.viewModel.currentStoryPageIndex == 1)
        #expect(host.didDismissGameplay == false)
        #expect(host.isShowingExitConfirmation == false)
        #expect(host.storage.userStats == statsBefore)
    }

    /// Staying and then leaving still discards, so the two actions stay
    /// independent across separate presentations.
    @Test func stayingFirstDoesNotPreventLeavingLater() {
        let host = ExitConfirmationHost(storyPageCount: 0)
        host.viewModel.selectAnswer(correctAnswer)

        host.tapExitButton()
        host.makeDialog().onContinueLearning()

        host.tapExitButton()
        host.makeDialog().onDiscardProgress()

        #expect(host.didDismissGameplay)
        #expect(host.storage.userStats.bestStars(for: "chapter-1") == 0)
    }
}

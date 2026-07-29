//
//  ImmediateFeedbackTests.swift
//  OwlLalaTests
//
//  Comprehensive Immediate Feedback TDD covering all three pieces of
//  `Components/ImmediateFeedback.swift` and the gameplay state that drives them:
//
//    1. Correct-answer celebration — duration, action contract, and the
//       view-model flow that raises and clears it (stars, persistence, guards).
//    2. Wrong-answer feedback — the outline/shake/sound trigger values the
//       modifier reads (`incorrectAnswerID`, `shakeTrigger`).
//    3. Second-wrong hint — `ChapterHints` text and cover resolution, the
//       `HintOverlay` initializers, and the rule that the hint appears on the
//       SECOND wrong answer only.
//
//  The visual modifiers themselves (`wrongAnswerFeedback`, `ShakeEffect`,
//  `BubbleTail`) are private and need a rendered view, so these suites pin the
//  values they are driven by plus the public component contracts.
//

import Foundation
import Testing
@testable import OwlLala

// MARK: - Immediate Feedback Test Helpers

/// The option that scores the chapter.
private let feedbackCorrectAnswer = AnswerOption(id: "correct", text: "Benar", imageAssetName: nil)

/// An option that costs a star.
private let feedbackWrongAnswer = AnswerOption(id: "wrong", text: "Salah", imageAssetName: nil)

/// A second wrong option, used to check that any wrong tap counts.
private let feedbackOtherWrongAnswer = AnswerOption(id: "wrong-2", text: "Salah Lagi", imageAssetName: nil)

@MainActor
private func makeFeedbackStorage() -> StorageService {
    StorageService(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
}

/// Builds a chapter for feedback tests.
///
/// - Parameters:
///   - id: Chapter identifier used for progress lookups.
///   - order: The chapter's position, which selects the default hint.
///   - hintText: The hand-written hint stored in the question data.
/// - Returns: A question-only chapter with one correct and two wrong options.
private func makeFeedbackChapter(
    id: String = "chapter-1",
    order: Int = 1,
    hintText: String = "Petunjuk khusus bab ini"
) -> Chapter {
    Chapter(
        id: id,
        order: order,
        title: "Bab Uji",
        subtitle: nil,
        description: "Deskripsi",
        thumbnailAssetName: "thumbnail",
        competency: .shape,
        storyPages: [],
        gameConfiguration: GameConfiguration(
            question: GameQuestion(
                id: "question",
                prompt: "Pertanyaan",
                promptImageAssetName: nil,
                answerOptions: [feedbackCorrectAnswer, feedbackWrongAnswer, feedbackOtherWrongAnswer],
                correctAnswerID: feedbackCorrectAnswer.id,
                hintText: hintText
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

/// Builds the gameplay session the feedback modifiers are driven by.
@MainActor
private func makeFeedbackSession(
    order: Int = 1,
    hintText: String = "Petunjuk khusus bab ini",
    source: GameplaySource = .mainStory
) -> (storage: StorageService, viewModel: ChapterGameplayViewModel) {
    let storage = makeFeedbackStorage()
    let viewModel = ChapterGameplayViewModel(
        chapter: makeFeedbackChapter(order: order, hintText: hintText),
        source: source,
        nextChapterID: "chapter-2",
        storageService: storage
    )

    return (storage, viewModel)
}

// MARK: - 1a. Correct Answer Celebration — Component

/// `CorrectAnswerCelebration` starts every congratulatory effect from one call
/// and reports back once. Its confetti and sound playback need a rendered view,
/// so these tests pin the timing constant and the action contract.
@MainActor
@Suite("Immediate Feedback — Celebration Component")
struct CorrectAnswerCelebrationComponentTests {

    /// The celebration runs for two seconds, as the gameplay flow expects.
    @Test func celebrationRunsForTwoSeconds() {
        #expect(CorrectAnswerCelebration.duration == 2.0)
    }

    /// Building the celebration does not report completion — that only happens
    /// after it has played.
    @Test func buildingTheCelebrationDoesNotReportCompletion() {
        var finishedCount = 0

        _ = CorrectAnswerCelebration(onFinished: { finishedCount += 1 })

        #expect(finishedCount == 0)
    }

    /// The completion action is the single way the celebration hands control
    /// back to the host.
    @Test func completionActionIsInvokable() {
        var finishedCount = 0
        let celebration = CorrectAnswerCelebration(onFinished: { finishedCount += 1 })

        celebration.onFinished()

        #expect(finishedCount == 1)
    }

    /// Separate celebrations are independent values.
    @Test func separateCelebrationsAreIndependent() {
        var firstCount = 0
        var secondCount = 0
        let first = CorrectAnswerCelebration(onFinished: { firstCount += 1 })
        _ = CorrectAnswerCelebration(onFinished: { secondCount += 1 })

        first.onFinished()

        #expect(firstCount == 1)
        #expect(secondCount == 0)
    }
}

// MARK: - 1b. Correct Answer Flow

/// The state the celebration is driven by: a correct tap raises the feedback
/// flag and computes the stars, and `finishCorrectFeedback()` — the celebration's
/// completion action — persists exactly once and moves on.
@MainActor
@Suite("Immediate Feedback — Correct Answer Flow")
struct ImmediateFeedbackCorrectAnswerTests {

    /// A correct tap starts the celebration and clears any wrong marking.
    @Test func aCorrectAnswerStartsTheCelebration() {
        let (_, viewModel) = makeFeedbackSession()

        viewModel.selectAnswer(feedbackCorrectAnswer)

        #expect(viewModel.isCorrectFeedbackPresented)
        #expect(viewModel.selectedAnswerID == feedbackCorrectAnswer.id)
        #expect(viewModel.incorrectAnswerID == nil)
    }

    /// Stars follow the number of wrong attempts: 3, then 2, then 1.
    @Test(arguments: [0, 1, 2, 3, 5])
    func starsDropWithEachWrongAttempt(_ wrongAttempts: Int) {
        let (_, viewModel) = makeFeedbackSession()

        for _ in 0 ..< wrongAttempts {
            viewModel.selectAnswer(feedbackWrongAnswer)
        }
        viewModel.selectAnswer(feedbackCorrectAnswer)

        let expectedStars: Int
        switch wrongAttempts {
        case 0:
            expectedStars = 3
        case 1:
            expectedStars = 2
        default:
            expectedStars = 1
        }

        #expect(viewModel.earnedStars == expectedStars)
    }

    /// Nothing is persisted while the celebration is still playing.
    @Test func nothingIsPersistedUntilTheCelebrationFinishes() {
        let (storage, viewModel) = makeFeedbackSession()
        let statsBefore = storage.userStats

        viewModel.selectAnswer(feedbackCorrectAnswer)

        #expect(storage.userStats == statsBefore)
        #expect(viewModel.destination == nil)
    }

    /// When the celebration reports back, progress is saved and the flow moves
    /// on to Stage Cleared.
    @Test func finishingTheCelebrationSavesProgressAndMovesOn() {
        let (storage, viewModel) = makeFeedbackSession()

        viewModel.selectAnswer(feedbackCorrectAnswer)
        viewModel.finishCorrectFeedback()

        #expect(viewModel.isCorrectFeedbackPresented == false)
        #expect(viewModel.destination == .stageCleared)
        #expect(storage.userStats.bestStars(for: "chapter-1") == 3)
        #expect(storage.userStats.playCount(for: "chapter-1") == 1)
        #expect(storage.userStats.isChapterUnlocked("chapter-2"))
    }

    /// A repeated completion callback must not double-count the play.
    @Test func finishingTwiceRecordsTheGameOnlyOnce() {
        let (storage, viewModel) = makeFeedbackSession()

        viewModel.selectAnswer(feedbackCorrectAnswer)
        viewModel.finishCorrectFeedback()
        viewModel.finishCorrectFeedback()
        viewModel.finishCorrectFeedback()

        #expect(storage.userStats.playCount(for: "chapter-1") == 1)
    }

    /// Finishing without a correct answer is a no-op, so a stray callback can
    /// never invent progress.
    @Test func finishingWithoutACorrectAnswerRecordsNothing() {
        let (storage, viewModel) = makeFeedbackSession()
        let statsBefore = storage.userStats

        viewModel.finishCorrectFeedback()

        #expect(storage.userStats == statsBefore)
        #expect(viewModel.destination == nil)
    }

    /// Taps during the celebration are ignored, so the score cannot change
    /// while the confetti is on screen.
    @Test func tapsDuringTheCelebrationAreIgnored() {
        let (_, viewModel) = makeFeedbackSession()
        viewModel.selectAnswer(feedbackCorrectAnswer)

        viewModel.selectAnswer(feedbackWrongAnswer)

        #expect(viewModel.wrongAnswerCount == 0)
        #expect(viewModel.earnedStars == 3)
        #expect(viewModel.incorrectAnswerID == nil)
    }

    /// Taps after the game was saved are ignored too.
    @Test func tapsAfterSavingAreIgnored() {
        let (storage, viewModel) = makeFeedbackSession()
        viewModel.selectAnswer(feedbackCorrectAnswer)
        viewModel.finishCorrectFeedback()

        viewModel.selectAnswer(feedbackWrongAnswer)

        #expect(viewModel.wrongAnswerCount == 0)
        #expect(storage.userStats.playCount(for: "chapter-1") == 1)
    }

    /// Training completions record a play without unlocking story chapters.
    @Test func trainingCompletionDoesNotUnlockStoryChapters() {
        let (storage, viewModel) = makeFeedbackSession(source: .training)

        viewModel.selectAnswer(feedbackCorrectAnswer)
        viewModel.finishCorrectFeedback()

        #expect(storage.userStats.playCount(for: "chapter-1") == 1)
        #expect(storage.userStats.isChapterUnlocked("chapter-2") == false)
    }
}

// MARK: - 2. Wrong Answer Feedback

/// The values `wrongAnswerFeedback(isWrong:shakeTrigger:)` is driven by. The
/// modifier shows the red outline while the tapped option is the marked wrong
/// one, and replays the shake, vibration, and sound on every trigger increment.
@MainActor
@Suite("Immediate Feedback — Wrong Answer Feedback")
struct ImmediateFeedbackWrongAnswerTests {

    /// A wrong tap marks that option and counts the attempt.
    @Test func aWrongTapMarksThatOption() {
        let (_, viewModel) = makeFeedbackSession()

        viewModel.selectAnswer(feedbackWrongAnswer)

        #expect(viewModel.incorrectAnswerID == feedbackWrongAnswer.id)
        #expect(viewModel.selectedAnswerID == feedbackWrongAnswer.id)
        #expect(viewModel.wrongAnswerCount == 1)
    }

    /// Only the tapped option is outlined — the others stay unmarked.
    @Test func onlyTheTappedOptionIsMarkedWrong() {
        let (_, viewModel) = makeFeedbackSession()

        viewModel.selectAnswer(feedbackWrongAnswer)

        #expect(viewModel.incorrectAnswerID == feedbackWrongAnswer.id)
        #expect(viewModel.incorrectAnswerID != feedbackOtherWrongAnswer.id)
        #expect(viewModel.incorrectAnswerID != feedbackCorrectAnswer.id)
    }

    /// The marking moves when a different wrong option is tapped.
    @Test func markingMovesToTheLatestWrongOption() {
        let (_, viewModel) = makeFeedbackSession()

        viewModel.selectAnswer(feedbackWrongAnswer)
        viewModel.selectAnswer(feedbackOtherWrongAnswer)

        #expect(viewModel.incorrectAnswerID == feedbackOtherWrongAnswer.id)
        #expect(viewModel.wrongAnswerCount == 2)
    }

    /// The shake trigger only ever increases, one step per wrong tap — the
    /// modifier replays its effects on each increment.
    @Test func theShakeTriggerIncrementsOncePerWrongTap() {
        let (_, viewModel) = makeFeedbackSession()

        #expect(viewModel.shakeTrigger == 0)

        viewModel.selectAnswer(feedbackWrongAnswer)
        #expect(viewModel.shakeTrigger == 1)

        viewModel.selectAnswer(feedbackWrongAnswer)
        #expect(viewModel.shakeTrigger == 2)

        viewModel.selectAnswer(feedbackWrongAnswer)
        #expect(viewModel.shakeTrigger == 3)
    }

    /// Tapping the same wrong option again still re-triggers the feedback, so
    /// the child always gets a response.
    @Test func repeatingTheSameWrongOptionRetriggersTheFeedback() {
        let (_, viewModel) = makeFeedbackSession()

        viewModel.selectAnswer(feedbackWrongAnswer)
        let firstTrigger = viewModel.shakeTrigger

        viewModel.selectAnswer(feedbackWrongAnswer)

        #expect(viewModel.shakeTrigger == firstTrigger + 1)
        #expect(viewModel.incorrectAnswerID == feedbackWrongAnswer.id)
    }

    /// A correct answer clears the outline, and the trigger does not advance.
    @Test func aCorrectAnswerClearsTheOutlineWithoutShaking() {
        let (_, viewModel) = makeFeedbackSession()
        viewModel.selectAnswer(feedbackWrongAnswer)
        let triggerAfterWrong = viewModel.shakeTrigger

        viewModel.selectAnswer(feedbackCorrectAnswer)

        #expect(viewModel.incorrectAnswerID == nil)
        #expect(viewModel.shakeTrigger == triggerAfterWrong)
    }

    /// Wrong taps never persist anything on their own.
    @Test func wrongTapsRecordNothing() {
        let (storage, viewModel) = makeFeedbackSession()
        let statsBefore = storage.userStats

        viewModel.selectAnswer(feedbackWrongAnswer)
        viewModel.selectAnswer(feedbackOtherWrongAnswer)

        #expect(storage.userStats == statsBefore)
    }

    /// Replaying resets every wrong-feedback value the modifier reads.
    @Test func replayingResetsTheWrongFeedbackState() {
        let (_, viewModel) = makeFeedbackSession()
        viewModel.selectAnswer(feedbackWrongAnswer)
        viewModel.selectAnswer(feedbackWrongAnswer)

        viewModel.resetForReplay()

        #expect(viewModel.wrongAnswerCount == 0)
        #expect(viewModel.shakeTrigger == 0)
        #expect(viewModel.incorrectAnswerID == nil)
        #expect(viewModel.selectedAnswerID == nil)
        #expect(viewModel.isHintPresented == false)
        #expect(viewModel.isCorrectFeedbackPresented == false)
        #expect(viewModel.earnedStars == nil)
    }
}

// MARK: - 3a. Hint Trigger Rules

/// The hint is the app's help-after-struggling rule: it appears on the SECOND
/// wrong answer, never the first, and is not forced back after being dismissed.
@MainActor
@Suite("Immediate Feedback — Hint Trigger Rules")
struct ImmediateFeedbackHintTriggerTests {

    /// One mistake is not enough to interrupt with help.
    @Test func theFirstWrongAnswerDoesNotShowTheHint() {
        let (_, viewModel) = makeFeedbackSession()

        viewModel.selectAnswer(feedbackWrongAnswer)

        #expect(viewModel.isHintPresented == false)
        #expect(viewModel.wrongAnswerCount == 1)
    }

    /// The second mistake brings the owl in.
    @Test func theSecondWrongAnswerShowsTheHint() {
        let (_, viewModel) = makeFeedbackSession()

        viewModel.selectAnswer(feedbackWrongAnswer)
        viewModel.selectAnswer(feedbackWrongAnswer)

        #expect(viewModel.isHintPresented)
        #expect(viewModel.wrongAnswerCount == 2)
    }

    /// Two different wrong options also count as two mistakes.
    @Test func twoDifferentWrongOptionsAlsoShowTheHint() {
        let (_, viewModel) = makeFeedbackSession()

        viewModel.selectAnswer(feedbackWrongAnswer)
        viewModel.selectAnswer(feedbackOtherWrongAnswer)

        #expect(viewModel.isHintPresented)
    }

    /// "Coba Lagi" closes the hint and returns to the same question.
    @Test func dismissingTheHintReturnsToTheQuestion() {
        let (_, viewModel) = makeFeedbackSession()
        viewModel.selectAnswer(feedbackWrongAnswer)
        viewModel.selectAnswer(feedbackWrongAnswer)

        viewModel.dismissHint()

        #expect(viewModel.isHintPresented == false)
        #expect(viewModel.isQuestionPresented)
        #expect(viewModel.wrongAnswerCount == 2)
    }

    /// Dismissing is idempotent.
    @Test func dismissingTwiceIsHarmless() {
        let (_, viewModel) = makeFeedbackSession()
        viewModel.selectAnswer(feedbackWrongAnswer)
        viewModel.selectAnswer(feedbackWrongAnswer)

        viewModel.dismissHint()
        viewModel.dismissHint()

        #expect(viewModel.isHintPresented == false)
    }

    /// A third mistake does not force the hint back after it was dismissed.
    @Test func aThirdWrongAnswerDoesNotForceTheHintBack() {
        let (_, viewModel) = makeFeedbackSession()
        viewModel.selectAnswer(feedbackWrongAnswer)
        viewModel.selectAnswer(feedbackWrongAnswer)
        viewModel.dismissHint()

        viewModel.selectAnswer(feedbackWrongAnswer)

        #expect(viewModel.wrongAnswerCount == 3)
        #expect(viewModel.isHintPresented == false)
    }

    /// Answering correctly after the hint still scores the one-star result.
    @Test func answeringCorrectlyAfterTheHintScoresOneStar() {
        let (_, viewModel) = makeFeedbackSession()
        viewModel.selectAnswer(feedbackWrongAnswer)
        viewModel.selectAnswer(feedbackWrongAnswer)
        viewModel.dismissHint()

        viewModel.selectAnswer(feedbackCorrectAnswer)

        #expect(viewModel.earnedStars == 1)
        #expect(viewModel.isCorrectFeedbackPresented)
    }

    /// Showing the hint never persists anything.
    @Test func showingTheHintRecordsNothing() {
        let (storage, viewModel) = makeFeedbackSession()
        let statsBefore = storage.userStats

        viewModel.selectAnswer(feedbackWrongAnswer)
        viewModel.selectAnswer(feedbackWrongAnswer)
        viewModel.dismissHint()

        #expect(storage.userStats == statsBefore)
    }
}

// MARK: - 3b. Chapter Hints Content

/// `ChapterHints` resolves what the speech bubble says and which cover sits
/// beside it.
@Suite("Immediate Feedback — Chapter Hints")
struct ChapterHintsTests {

    /// Every chapter has a non-empty hint, including out-of-range orders.
    @Test(arguments: [-3, 0, 1, 2, 3, 4, 5, 6, 99])
    func everyChapterOrderResolvesANonEmptyHint(_ order: Int) {
        #expect(ChapterHints.hint(forChapterOrder: order).isEmpty == false)
    }

    /// Chapters 1–4 each get their own competency-specific hint.
    @Test func chaptersOneToFourHaveDistinctHints() {
        let hints = (1 ... 4).map { ChapterHints.hint(forChapterOrder: $0) }

        #expect(Set(hints).count == 4)
    }

    /// Each hint points at the cue its chapter teaches.
    @Test func eachHintNamesItsOwnVisualCue() {
        #expect(ChapterHints.hint(forChapterOrder: 1).contains("bentuk"))
        #expect(ChapterHints.hint(forChapterOrder: 2).contains("tulisan"))
        #expect(ChapterHints.hint(forChapterOrder: 3).contains("gelap"))
        #expect(ChapterHints.hint(forChapterOrder: 4).contains("pola"))
    }

    /// Chapter 5 combines every cue, and anything beyond the written chapters
    /// safely falls back to that same combined hint.
    @Test(arguments: [5, 6, 42])
    func chapterFiveAndBeyondUseTheCombinedCueHint(_ order: Int) {
        let combined = ChapterHints.hint(forChapterOrder: 5)

        #expect(ChapterHints.hint(forChapterOrder: order) == combined)
        #expect(combined.contains("bentuk"))
        #expect(combined.contains("pola"))
    }

    /// The hand-written hint in the question data wins when present.
    @Test func theChaptersOwnHintTextIsPreferred() {
        let chapter = makeFeedbackChapter(order: 1, hintText: "Petunjuk dari data bab")

        #expect(ChapterHints.hint(for: chapter) == "Petunjuk dari data bab")
    }

    /// An empty or whitespace-only hint falls back to the chapter's default.
    @Test(arguments: ["", "   ", "\n", " \n\t "])
    func blankChapterHintFallsBackToTheOrderDefault(_ blank: String) {
        let chapter = makeFeedbackChapter(order: 4, hintText: blank)

        #expect(ChapterHints.hint(for: chapter) == ChapterHints.hint(forChapterOrder: 4))
    }

    /// Surrounding whitespace does not defeat the hand-written hint.
    @Test func aPaddedChapterHintIsStillUsed() {
        let chapter = makeFeedbackChapter(order: 2, hintText: "  Lihat gambarnya  ")

        #expect(ChapterHints.hint(for: chapter) == "Lihat gambarnya")
    }

    /// Chapters 1–6 show their own cover art.
    @Test(arguments: 1 ... 6)
    func coversMatchTheChapterNumber(_ order: Int) {
        #expect(ChapterHints.coverImageName(forChapterOrder: order) == "chapterCover\(order)")
    }

    /// Orders outside the shipped art fall back to the first cover rather than
    /// asking for a missing asset.
    @Test(arguments: [-1, 0, 7, 100])
    func outOfRangeCoversFallBackToTheFirst(_ order: Int) {
        #expect(ChapterHints.coverImageName(forChapterOrder: order) == "chapterCover1")
    }

    /// The chapter-based lookups agree with the order-based ones.
    @Test func chapterLookupsMatchOrderLookups() {
        let chapter = makeFeedbackChapter(order: 3, hintText: "")

        #expect(ChapterHints.hint(for: chapter) == ChapterHints.hint(forChapterOrder: 3))
        #expect(ChapterHints.coverImageName(for: chapter) == "chapterCover3")
    }
}

// MARK: - 3c. Hint Overlay Component

/// `HintOverlay` is presentation-only: its three initializers resolve what to
/// show, and its single action hands control back to the host.
@MainActor
@Suite("Immediate Feedback — Hint Overlay")
struct HintOverlayComponentTests {

    /// The explicit initializer shows exactly what it was given.
    @Test func theExplicitInitializerKeepsItsContent() {
        let overlay = HintOverlay(
            hintText: "Petunjuk kustom",
            illustrationImageName: "chapterCover4",
            onDismiss: {}
        )

        #expect(overlay.hintText == "Petunjuk kustom")
        #expect(overlay.illustrationImageName == "chapterCover4")
    }

    /// Without a cover, the overlay defaults to chapter 1's art.
    @Test func theExplicitInitializerDefaultsToTheFirstCover() {
        let overlay = HintOverlay(hintText: "Petunjuk", onDismiss: {})

        #expect(overlay.illustrationImageName == "chapterCover1")
    }

    /// The chapter initializer resolves both the text and the cover — the form
    /// gameplay uses.
    @Test func theChapterInitializerResolvesTextAndCover() {
        let chapter = makeFeedbackChapter(order: 5, hintText: "Petunjuk bab lima")
        let overlay = HintOverlay(chapter: chapter, onDismiss: {})

        #expect(overlay.hintText == "Petunjuk bab lima")
        #expect(overlay.illustrationImageName == "chapterCover5")
    }

    /// A chapter with no written hint still gets its default text.
    @Test func theChapterInitializerFallsBackToTheDefaultHint() {
        let chapter = makeFeedbackChapter(order: 2, hintText: "")
        let overlay = HintOverlay(chapter: chapter, onDismiss: {})

        #expect(overlay.hintText == ChapterHints.hint(forChapterOrder: 2))
        #expect(overlay.illustrationImageName == "chapterCover2")
    }

    /// The order initializer is the no-chapter-at-hand form.
    @Test(arguments: 1 ... 5)
    func theOrderInitializerMatchesChapterHints(_ order: Int) {
        let overlay = HintOverlay(chapterOrder: order, onDismiss: {})

        #expect(overlay.hintText == ChapterHints.hint(forChapterOrder: order))
        #expect(overlay.illustrationImageName == "chapterCover\(order)")
    }

    /// Building the overlay does not dismiss it.
    @Test func buildingTheOverlayDoesNotDismissIt() {
        var dismissCount = 0

        _ = HintOverlay(hintText: "Petunjuk", onDismiss: { dismissCount += 1 })

        #expect(dismissCount == 0)
    }

    /// "Coba Lagi" runs the host's dismiss action.
    @Test func theRetryActionIsInvokable() {
        var dismissCount = 0
        let overlay = HintOverlay(hintText: "Petunjuk", onDismiss: { dismissCount += 1 })

        overlay.onDismiss()

        #expect(dismissCount == 1)
    }

    /// The overlay owns no state, so the host stays in control of visibility.
    @Test func theOverlayHoldsNoDismissalState() {
        var dismissCount = 0
        let overlay = HintOverlay(hintText: "Petunjuk", onDismiss: { dismissCount += 1 })

        overlay.onDismiss()
        overlay.onDismiss()

        #expect(dismissCount == 2)
    }

    /// Wiring the overlay to the view model closes the hint, exactly as the
    /// gameplay screen does with `viewModel.dismissHint()`.
    @Test func wiringTheRetryActionToTheViewModelClosesTheHint() {
        let (_, viewModel) = makeFeedbackSession()
        viewModel.selectAnswer(feedbackWrongAnswer)
        viewModel.selectAnswer(feedbackWrongAnswer)
        #expect(viewModel.isHintPresented)

        let overlay = HintOverlay(
            chapter: viewModel.chapter,
            onDismiss: { viewModel.dismissHint() }
        )
        overlay.onDismiss()

        #expect(viewModel.isHintPresented == false)
    }
}

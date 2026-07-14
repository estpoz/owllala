//
//  OwlLalaTests.swift
//  OwlLalaTests
//
//  Created by Farrell Sudjatmiko on 13/07/26.
//
//  TDD suites written with Swift Testing.
//  https://developer.apple.com/documentation/testing
//
//  These tests exercise the production types that live in the OwlLala app
//  target (via `@testable import`), not copies defined inside the test target.
//  Each suite maps to a TDD scenario in TDD.md.
//

import Foundation
import Testing
@testable import OwlLala

// MARK: - Test Helpers

/// Builds a session of shape questions whose correct answer is `answer-<n>`.
private func makeSession(questionCount count: Int) -> LearningSession {
    let questions = (1...count).map { index in
        VisualCueQuestion(
            id: "q\(index)",
            cueType: .shape,
            correctAnswerID: "answer-\(index)"
        )
    }

    return LearningSession(questions: questions)
}

// MARK: - TDD-01: Incorrect Answer Can Be Retried

@Suite("TDD-01 Retryable answers")
struct RetryableAnswerTests {

    @Test func incorrectAnswerKeepsQuestionRetryable() {
        var session = LearningSession(questions: [
            VisualCueQuestion(id: "q1", cueType: .shape, correctAnswerID: "circle")
        ])

        let feedback = session.submitAnswer("square", forQuestionID: "q1")

        #expect(feedback.isCorrect == false)
        #expect(feedback.kind == .tryAgain)
        #expect(session.isQuestionCompleted("q1") == false)
        #expect(session.isQuestionRetryable("q1") == true)
    }

    @Test func correctRetryCompletesQuestion() {
        var session = LearningSession(questions: [
            VisualCueQuestion(id: "q1", cueType: .shape, correctAnswerID: "circle")
        ])

        _ = session.submitAnswer("square", forQuestionID: "q1")
        let feedback = session.submitAnswer("circle", forQuestionID: "q1")

        #expect(feedback.isCorrect == true)
        #expect(feedback.kind == .positive)
        #expect(session.isQuestionCompleted("q1") == true)
    }

    @Test func retryCorrectAnswerAppliesRetryScoringRule() {
        var firstAttemptSession = LearningSession(questions: [
            VisualCueQuestion(id: "q1", cueType: .shape, correctAnswerID: "circle")
        ])
        var retrySession = LearningSession(questions: [
            VisualCueQuestion(id: "q1", cueType: .shape, correctAnswerID: "circle")
        ])

        _ = firstAttemptSession.submitAnswer("circle", forQuestionID: "q1")
        _ = retrySession.submitAnswer("square", forQuestionID: "q1")
        _ = retrySession.submitAnswer("circle", forQuestionID: "q1")

        #expect(retrySession.score < firstAttemptSession.score)
        #expect(retrySession.score == 7)
        #expect(firstAttemptSession.score == 10)
    }
}

// MARK: - TDD-02: Perfect Session Scores 100 Points And 3 Stars

@Suite("TDD-02 Perfect session scoring")
struct PerfectSessionScoringTests {

    @Test func perfectTenQuestionSessionScoresOneHundredPoints() {
        var session = makeSession(questionCount: 10)

        for question in session.questions {
            _ = session.submitAnswer(question.correctAnswerID, forQuestionID: question.id)
        }

        #expect(session.score == 100)
    }

    @Test func perfectTenQuestionSessionAwardsFiveStars() {
        var session = makeSession(questionCount: 10)

        for question in session.questions {
            _ = session.submitAnswer(question.correctAnswerID, forQuestionID: question.id)
        }

        #expect(session.stars == 3)
    }
}

// MARK: - TDD-03: Correct Non-Color Cue Selection Shows Positive Feedback

@Suite("TDD-03 Non-color cue validation")
struct NonColorCueValidationTests {

    @Test func shapeQuestionValidatesByShape() {
        let question = VisualCueQuestion(
            id: "shape-1",
            cueType: .shape,
            correctAnswerID: "triangle",
            colorName: "red"
        )

        #expect(question.validates(answerID: "triangle") == true)
        #expect(question.validates(answerID: "red") == false)
    }

    @Test func patternQuestionValidatesByPattern() {
        let question = VisualCueQuestion(
            id: "pattern-1",
            cueType: .pattern,
            correctAnswerID: "striped",
            colorName: "green"
        )

        #expect(question.validates(answerID: "striped") == true)
        #expect(question.validates(answerID: "green") == false)
    }

    @Test func symbolQuestionValidatesByMeaning() {
        let question = VisualCueQuestion(
            id: "symbol-1",
            cueType: .symbol,
            correctAnswerID: "school-crossing",
            colorName: "yellow"
        )

        #expect(question.validates(answerID: "school-crossing") == true)
        #expect(question.validates(answerID: "yellow") == false)
    }

    @Test func correctAnswerShowsPositiveFeedback() {
        var session = LearningSession(questions: [
            VisualCueQuestion(id: "q1", cueType: .symbol, correctAnswerID: "star")
        ])

        let feedback = session.submitAnswer("star", forQuestionID: "q1")

        #expect(feedback.kind == .positive)
        #expect(feedback.message == "Benar! Kamu hebat mengenali petunjuknya.")
    }
}

// MARK: - TDD-04: Chapter 5 Unlocks After Four Chapters With Enough Stars

@Suite("TDD-04 Chapter 5 unlock")
struct ChapterFiveUnlockTests {

    @Test func chapterFiveIsLockedBeforeRequiredChaptersAreComplete() {
        let progress = ChildProgress()

        #expect(progress.isChapterFiveUnlocked == false)
    }

    @Test func chapterFiveIsLockedWhenAnyRequiredChapterHasLessThanTwoStars() {
        var progress = ChildProgress()
        progress.recordChapterResult(chapterID: "chapter-1", score: 100, stars: 3)
        progress.recordChapterResult(chapterID: "chapter-2", score: 80, stars: 2)
        progress.recordChapterResult(chapterID: "chapter-3", score: 50, stars: 1)
        progress.recordChapterResult(chapterID: "chapter-4", score: 100, stars: 3)

        #expect(progress.isChapterFiveUnlocked == false)
    }

    @Test func chapterFiveUnlocksWhenFirstFourChaptersHaveAtLeastTwoStars() {
        var progress = ChildProgress()
        progress.recordChapterResult(chapterID: "chapter-1", score: 80, stars: 2)
        progress.recordChapterResult(chapterID: "chapter-2", score: 100, stars: 3)
        progress.recordChapterResult(chapterID: "chapter-3", score: 80, stars: 2)
        progress.recordChapterResult(chapterID: "chapter-4", score: 100, stars: 3)

        #expect(progress.isChapterFiveUnlocked == true)
    }
}

// MARK: - TDD-05: Learning Session Progress Is Saved For Parent View

@Suite("TDD-05 Progress persistence")
struct ProgressPersistenceTests {

    @Test func completedSessionSavesProgressRecord() {
        var progress = ChildProgress()
        let result = SessionResult(
            chapterID: "chapter-1",
            score: 90,
            stars: 4,
            isCompleted: true,
            completedAt: Date(timeIntervalSince1970: 1_800)
        )

        progress.recordSession(result)

        #expect(progress.records.count == 1)
        #expect(progress.records.first?.chapterID == "chapter-1")
    }

    @Test func savedProgressIncludesScoreStarsAndCompletionStatus() throws {
        var progress = ChildProgress()
        let completedAt = Date(timeIntervalSince1970: 1_800)

        progress.recordSession(SessionResult(
            chapterID: "chapter-1",
            score: 90,
            stars: 4,
            isCompleted: true,
            completedAt: completedAt
        ))

        let record = try #require(progress.records.first)
        #expect(record.chapterID == "chapter-1")
        #expect(record.score == 90)
        #expect(record.stars == 4)
        #expect(record.isCompleted == true)
        #expect(record.completedAt == completedAt)
    }

    @Test func loadingProgressReturnsLatestSavedResult() throws {
        var store = InMemoryProgressStore()
        let older = SessionResult(
            chapterID: "chapter-1",
            score: 60,
            stars: 3,
            isCompleted: true,
            completedAt: Date(timeIntervalSince1970: 1_000)
        )
        let latest = SessionResult(
            chapterID: "chapter-1",
            score: 90,
            stars: 4,
            isCompleted: true,
            completedAt: Date(timeIntervalSince1970: 2_000)
        )

        store.save(older)
        store.save(latest)

        #expect(try #require(store.loadLatestResult(forChapterID: "chapter-1")) == latest)
    }
}

// MARK: - TDD-06: Completing All Challenges Shows Result And Unlocks Next Activity

@Suite("TDD-06 Completion and unlock")
struct CompletionAndUnlockTests {

    @Test func sessionIsIncompleteWhileChallengesRemain() {
        var session = makeSession(questionCount: 3)

        _ = session.submitAnswer("answer-1", forQuestionID: "q1")
        _ = session.submitAnswer("answer-2", forQuestionID: "q2")

        #expect(session.isCompleted == false)
    }

    @Test func lastCompletedChallengeCompletesSession() {
        var session = makeSession(questionCount: 2)

        _ = session.submitAnswer("answer-1", forQuestionID: "q1")
        _ = session.submitAnswer("answer-2", forQuestionID: "q2")

        #expect(session.isCompleted == true)
    }

    @Test func completedSessionShowsResultSummary() throws {
        var session = makeSession(questionCount: 2)

        _ = session.submitAnswer("answer-1", forQuestionID: "q1")
        _ = session.submitAnswer("answer-2", forQuestionID: "q2")

        let summary = try #require(session.resultSummary)
        #expect(summary.score == 20)
        #expect(summary.stars == 5)
    }

    @Test func completedSessionUnlocksNextActivityWhenThresholdIsMet() {
        var progress = ChildProgress()
        progress.recordChapterResult(chapterID: "chapter-1", score: 80, stars: 4)

        #expect(progress.isActivityUnlocked(afterChapterID: "chapter-1") == true)
    }
}

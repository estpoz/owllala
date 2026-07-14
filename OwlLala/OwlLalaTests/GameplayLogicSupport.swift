//
//  GameplayLogicSupport.swift
//  OwlLalaTests
//
//  TEMPORARY test-target home for the gameplay/progress logic that the TDD
//  suites in OwlLalaTests.swift exercise.
//
//  These types are intentionally kept in the test target so the tests compile
//  and run today. They are grouped by their intended destination so they can be
//  moved into the OwlLala app target's ViewModel/Service files later:
//
//    • CueType, VisualCueQuestion, Feedback, FeedbackKind,
//      ResultSummary, LearningSession   -> ChapterGameplayViewModel.swift
//    • SessionResult, ChildProgress      -> ChapterSelectionViewModel.swift
//    • ProgressStore, InMemoryProgressStore -> StorageService.swift
//
//  Once they live in the app target, delete this file and rely on
//  `@testable import OwlLala`.
//

import Foundation

// MARK: - Destination: ChapterGameplayViewModel.swift

/// The kind of non-color visual cue a question is validated against.
enum CueType {
    case shape
    case pattern
    case symbol
}

/// One tap-to-select question answered by matching a non-color cue.
///
/// The optional `colorName` exists only to prove color is never used when
/// deciding whether an answer is correct.
struct VisualCueQuestion: Equatable {
    let id: String
    let cueType: CueType
    let correctAnswerID: String
    var colorName: String?

    func validates(answerID: String) -> Bool {
        answerID == correctAnswerID
    }
}

/// The kind of feedback shown to the child after an answer is submitted.
enum FeedbackKind {
    case positive
    case tryAgain
}

/// The result of submitting an answer, including child-friendly copy.
struct Feedback: Equatable {
    let isCorrect: Bool
    let kind: FeedbackKind
    let message: String
}

/// The score and stars shown on the result screen once a session completes.
struct ResultSummary: Equatable {
    let score: Int
    let stars: Int
}

/// Drives one chapter mini-game: answer validation, scoring, retry handling,
/// and completion state.
struct LearningSession {
    let questions: [VisualCueQuestion]
    private(set) var attemptsByQuestionID: [String: Int] = [:]
    private(set) var completedQuestionIDs: Set<String> = []
    private(set) var score = 0

    var isCompleted: Bool {
        completedQuestionIDs.count == questions.count
    }

    var stars: Int {
        guard isCompleted else {
            return 0
        }

        let maximumScore = questions.count * 10
        let accuracy = maximumScore == 0 ? 0 : Double(score) / Double(maximumScore)

        switch accuracy {
        case 1:
            return 5
        case 0.8...:
            return 4
        case 0.6...:
            return 3
        case 0.4...:
            return 2
        default:
            return 1
        }
    }

    var resultSummary: ResultSummary? {
        guard isCompleted else {
            return nil
        }

        return ResultSummary(score: score, stars: stars)
    }

    mutating func submitAnswer(_ answerID: String, forQuestionID questionID: String) -> Feedback {
        guard let question = questions.first(where: { $0.id == questionID }) else {
            return Feedback(isCorrect: false, kind: .tryAgain, message: "Pertanyaan tidak ditemukan.")
        }

        attemptsByQuestionID[questionID, default: 0] += 1

        guard question.validates(answerID: answerID) else {
            return Feedback(isCorrect: false, kind: .tryAgain, message: "Coba lagi, perhatikan bentuk atau simbolnya.")
        }

        completedQuestionIDs.insert(questionID)
        score += attemptsByQuestionID[questionID] == 1 ? 10 : 7

        return Feedback(
            isCorrect: true,
            kind: .positive,
            message: "Benar! Kamu hebat mengenali petunjuknya."
        )
    }

    func isQuestionCompleted(_ questionID: String) -> Bool {
        completedQuestionIDs.contains(questionID)
    }

    func isQuestionRetryable(_ questionID: String) -> Bool {
        questions.contains { $0.id == questionID } && !isQuestionCompleted(questionID)
    }
}

// MARK: - Destination: ChapterSelectionViewModel.swift

/// The persisted outcome of one completed learning session.
struct SessionResult: Equatable {
    let chapterID: String
    let score: Int
    let stars: Int
    let isCompleted: Bool
    let completedAt: Date
}

/// Tracks accumulated session results and derives chapter/activity unlock state.
struct ChildProgress {
    private(set) var records: [SessionResult] = []

    var isChapterFiveUnlocked: Bool {
        (1...4).allSatisfy { index in
            bestStarsByChapterID["chapter-\(index)", default: 0] >= 2
        }
    }

    private var bestStarsByChapterID: [String: Int] {
        records.reduce(into: [:]) { result, record in
            guard record.isCompleted else {
                return
            }

            result[record.chapterID] = max(result[record.chapterID, default: 0], record.stars)
        }
    }

    mutating func recordChapterResult(chapterID: String, score: Int, stars: Int) {
        recordSession(SessionResult(
            chapterID: chapterID,
            score: score,
            stars: stars,
            isCompleted: true,
            completedAt: Date()
        ))
    }

    mutating func recordSession(_ result: SessionResult) {
        records.append(result)
    }

    func isActivityUnlocked(afterChapterID chapterID: String) -> Bool {
        bestStarsByChapterID[chapterID, default: 0] >= 4
    }
}

// MARK: - Destination: StorageService.swift

/// Abstracts saving and loading child progress for testability.
protocol ProgressStore {
    mutating func save(_ result: SessionResult)
    func loadLatestResult(forChapterID chapterID: String) -> SessionResult?
}

/// A `ProgressStore` that keeps results in memory.
struct InMemoryProgressStore: ProgressStore {
    private var savedResults: [SessionResult] = []

    mutating func save(_ result: SessionResult) {
        savedResults.append(result)
    }

    func loadLatestResult(forChapterID chapterID: String) -> SessionResult? {
        savedResults
            .filter { $0.chapterID == chapterID }
            .max { $0.completedAt < $1.completedAt }
    }
}

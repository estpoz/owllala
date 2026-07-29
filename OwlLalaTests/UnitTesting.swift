////
////  UnitTesting.swift
////  OwlLalaUITests
////
////  Created by Amanda on 13/07/26.
////
//
//import Foundation
//import Testing
////@testable import OwlLala
//
//
//struct UnitTesting {
//
//    @Test func incorrectAnswerKeepsQuestionRetryable() {
//        var session = LearningSession(questions: [
//            VisualCueQuestion(id: "q1", cueType: .shape, correctAnswerID: "circle")
//        ])
//
//        let feedback = session.submitAnswer("square", forQuestionID: "q1")
//
//        #expect(feedback.isCorrect == false)
//        #expect(feedback.kind == .tryAgain)
//        #expect(session.isQuestionCompleted("q1") == false)
//        #expect(session.isQuestionRetryable("q1") == true)
//    }
//
//    @Test func correctRetryCompletesQuestion() {
//        var session = LearningSession(questions: [
//            VisualCueQuestion(id: "q1", cueType: .shape, correctAnswerID: "circle")
//        ])
//
//        _ = session.submitAnswer("square", forQuestionID: "q1")
//        let feedback = session.submitAnswer("circle", forQuestionID: "q1")
//
//        #expect(feedback.isCorrect == true)
//        #expect(feedback.kind == .positive)
//        #expect(session.isQuestionCompleted("q1") == true)
//    }
//
//    @Test func retryCorrectAnswerAppliesRetryScoringRule() {
//        var firstAttemptSession = LearningSession(questions: [
//            VisualCueQuestion(id: "q1", cueType: .shape, correctAnswerID: "circle")
//        ])
//        var retrySession = LearningSession(questions: [
//            VisualCueQuestion(id: "q1", cueType: .shape, correctAnswerID: "circle")
//        ])
//
//        _ = firstAttemptSession.submitAnswer("circle", forQuestionID: "q1")
//        _ = retrySession.submitAnswer("square", forQuestionID: "q1")
//        _ = retrySession.submitAnswer("circle", forQuestionID: "q1")
//
//        #expect(retrySession.score < firstAttemptSession.score)
//        #expect(retrySession.score == 7)
//        #expect(firstAttemptSession.score == 10)
//    }
//
//    @Test func perfectTenQuestionSessionScoresOneHundredPoints() {
//        var session = LearningSession(questions: Self.makeQuestions(count: 10))
//
//        for question in session.questions {
//            _ = session.submitAnswer(question.correctAnswerID, forQuestionID: question.id)
//        }
//
//        #expect(session.score == 100)
//    }
//
//    @Test func perfectTenQuestionSessionAwardsFiveStars() {
//        var session = LearningSession(questions: Self.makeQuestions(count: 10))
//
//        for question in session.questions {
//            _ = session.submitAnswer(question.correctAnswerID, forQuestionID: question.id)
//        }
//
//        #expect(session.stars == 5)
//    }
//
//    @Test func shapeQuestionValidatesByShape() {
//        let question = VisualCueQuestion(
//            id: "shape-1",
//            cueType: .shape,
//            correctAnswerID: "triangle",
//            colorName: "red"
//        )
//
//        #expect(question.validates(answerID: "triangle") == true)
//        #expect(question.validates(answerID: "red") == false)
//    }
//
//    @Test func patternQuestionValidatesByPattern() {
//        let question = VisualCueQuestion(
//            id: "pattern-1",
//            cueType: .pattern,
//            correctAnswerID: "striped",
//            colorName: "green"
//        )
//
//        #expect(question.validates(answerID: "striped") == true)
//        #expect(question.validates(answerID: "green") == false)
//    }
//
//    @Test func symbolQuestionValidatesByMeaning() {
//        let question = VisualCueQuestion(
//            id: "symbol-1",
//            cueType: .symbol,
//            correctAnswerID: "school-crossing",
//            colorName: "yellow"
//        )
//
//        #expect(question.validates(answerID: "school-crossing") == true)
//        #expect(question.validates(answerID: "yellow") == false)
//    }
//
//    @Test func correctAnswerShowsPositiveFeedback() {
//        var session = LearningSession(questions: [
//            VisualCueQuestion(id: "q1", cueType: .symbol, correctAnswerID: "star")
//        ])
//
//        let feedback = session.submitAnswer("star", forQuestionID: "q1")
//
//        #expect(feedback.kind == .positive)
//        #expect(feedback.message == "Benar! Kamu hebat mengenali petunjuknya.")
//    }
//
//    @Test func chapterFiveIsLockedBeforeRequiredChaptersAreComplete() {
//        let progress = ChildProgress()
//
//        #expect(progress.isChapterFiveUnlocked == false)
//    }
//
//    @Test func chapterFiveIsLockedWhenAnyRequiredChapterHasLessThanTwoStars() {
//        var progress = ChildProgress()
//        progress.recordChapterResult(chapterID: "chapter-1", score: 100, stars: 3)
//        progress.recordChapterResult(chapterID: "chapter-2", score: 80, stars: 2)
//        progress.recordChapterResult(chapterID: "chapter-3", score: 50, stars: 1)
//        progress.recordChapterResult(chapterID: "chapter-4", score: 100, stars: 3)
//
//        #expect(progress.isChapterFiveUnlocked == false)
//    }
//
//    @Test func chapterFiveUnlocksWhenFirstFourChaptersHaveAtLeastTwoStars() {
//        var progress = ChildProgress()
//        progress.recordChapterResult(chapterID: "chapter-1", score: 80, stars: 2)
//        progress.recordChapterResult(chapterID: "chapter-2", score: 100, stars: 3)
//        progress.recordChapterResult(chapterID: "chapter-3", score: 80, stars: 2)
//        progress.recordChapterResult(chapterID: "chapter-4", score: 100, stars: 3)
//
//        #expect(progress.isChapterFiveUnlocked == true)
//    }
//
//    @Test func completedSessionSavesProgressRecord() {
//        var progress = ChildProgress()
//        let result = SessionResult(
//            chapterID: "chapter-1",
//            score: 90,
//            stars: 4,
//            isCompleted: true,
//            completedAt: Date(timeIntervalSince1970: 1_800)
//        )
//
//        progress.recordSession(result)
//
//        #expect(progress.records.count == 1)
//        #expect(progress.records.first?.chapterID == "chapter-1")
//    }
//
//    @Test func savedProgressIncludesScoreStarsAndCompletionStatus() throws {
//        var progress = ChildProgress()
//        let completedAt = Date(timeIntervalSince1970: 1_800)
//
//        progress.recordSession(SessionResult(
//            chapterID: "chapter-1",
//            score: 90,
//            stars: 4,
//            isCompleted: true,
//            completedAt: completedAt
//        ))
//
//        let record = try #require(progress.records.first)
//        #expect(record.chapterID == "chapter-1")
//        #expect(record.score == 90)
//        #expect(record.stars == 4)
//        #expect(record.isCompleted == true)
//        #expect(record.completedAt == completedAt)
//    }
//
//    @Test func loadingProgressReturnsLatestSavedResult() throws {
//        var store = InMemoryProgressStore()
//        let older = SessionResult(
//            chapterID: "chapter-1",
//            score: 60,
//            stars: 3,
//            isCompleted: true,
//            completedAt: Date(timeIntervalSince1970: 1_000)
//        )
//        let latest = SessionResult(
//            chapterID: "chapter-1",
//            score: 90,
//            stars: 4,
//            isCompleted: true,
//            completedAt: Date(timeIntervalSince1970: 2_000)
//        )
//
//        store.save(older)
//        store.save(latest)
//
//        #expect(try #require(store.loadLatestResult(forChapterID: "chapter-1")) == latest)
//    }
//
//    @Test func sessionIsIncompleteWhileChallengesRemain() {
//        var session = LearningSession(questions: Self.makeQuestions(count: 3))
//
//        _ = session.submitAnswer("answer-1", forQuestionID: "q1")
//        _ = session.submitAnswer("answer-2", forQuestionID: "q2")
//
//        #expect(session.isCompleted == false)
//    }
//
//    @Test func lastCompletedChallengeCompletesSession() {
//        var session = LearningSession(questions: Self.makeQuestions(count: 2))
//
//        _ = session.submitAnswer("answer-1", forQuestionID: "q1")
//        _ = session.submitAnswer("answer-2", forQuestionID: "q2")
//
//        #expect(session.isCompleted == true)
//    }
//
//    @Test func completedSessionShowsResultSummary() throws {
//        var session = LearningSession(questions: Self.makeQuestions(count: 2))
//
//        _ = session.submitAnswer("answer-1", forQuestionID: "q1")
//        _ = session.submitAnswer("answer-2", forQuestionID: "q2")
//
//        let summary = try #require(session.resultSummary)
//        #expect(summary.score == 20)
//        #expect(summary.stars == 5)
//    }
//
//    @Test func completedSessionUnlocksNextActivityWhenThresholdIsMet() {
//        var progress = ChildProgress()
//        progress.recordChapterResult(chapterID: "chapter-1", score: 80, stars: 4)
//
//        #expect(progress.isActivityUnlocked(afterChapterID: "chapter-1") == true)
//    }
//
//    private static func makeQuestions(count: Int) -> [VisualCueQuestion] {
//        (1...count).map { index in
//            VisualCueQuestion(
//                id: "q\(index)",
//                cueType: .shape,
//                correctAnswerID: "answer-\(index)"
//            )
//        }
//    }
//}
//
//private enum CueType {
//    case shape
//    case pattern
//    case symbol
//}
//
//private struct VisualCueQuestion: Equatable {
//    let id: String
//    let cueType: CueType
//    let correctAnswerID: String
//    var colorName: String?
//
//    func validates(answerID: String) -> Bool {
//        answerID == correctAnswerID
//    }
//}
//
//private struct LearningSession {
//    let questions: [VisualCueQuestion]
//    private(set) var attemptsByQuestionID: [String: Int] = [:]
//    private(set) var completedQuestionIDs: Set<String> = []
//    private(set) var score = 0
//
//    var isCompleted: Bool {
//        completedQuestionIDs.count == questions.count
//    }
//
//    var stars: Int {
//        guard isCompleted else {
//            return 0
//        }
//
//        let maximumScore = questions.count * 10
//        let accuracy = maximumScore == 0 ? 0 : Double(score) / Double(maximumScore)
//
//        switch accuracy {
//        case 1:
//            return 5
//        case 0.8...:
//            return 4
//        case 0.6...:
//            return 3
//        case 0.4...:
//            return 2
//        default:
//            return 1
//        }
//    }
//
//    var resultSummary: ResultSummary? {
//        guard isCompleted else {
//            return nil
//        }
//
//        return ResultSummary(score: score, stars: stars)
//    }
//
//    mutating func submitAnswer(_ answerID: String, forQuestionID questionID: String) -> Feedback {
//        guard let question = questions.first(where: { $0.id == questionID }) else {
//            return Feedback(isCorrect: false, kind: .tryAgain, message: "Pertanyaan tidak ditemukan.")
//        }
//
//        attemptsByQuestionID[questionID, default: 0] += 1
//
//        guard question.validates(answerID: answerID) else {
//            return Feedback(isCorrect: false, kind: .tryAgain, message: "Coba lagi, perhatikan bentuk atau simbolnya.")
//        }
//
//        completedQuestionIDs.insert(questionID)
//        score += attemptsByQuestionID[questionID] == 1 ? 10 : 7
//
//        return Feedback(
//            isCorrect: true,
//            kind: .positive,
//            message: "Benar! Kamu hebat mengenali petunjuknya."
//        )
//    }
//
//    func isQuestionCompleted(_ questionID: String) -> Bool {
//        completedQuestionIDs.contains(questionID)
//    }
//
//    func isQuestionRetryable(_ questionID: String) -> Bool {
//        questions.contains { $0.id == questionID } && !isQuestionCompleted(questionID)
//    }
//}
//
//private struct Feedback: Equatable {
//    let isCorrect: Bool
//    let kind: FeedbackKind
//    let message: String
//}
//
//private enum FeedbackKind {
//    case positive
//    case tryAgain
//}
//
//private struct ResultSummary: Equatable {
//    let score: Int
//    let stars: Int
//}
//
//private struct SessionResult: Equatable {
//    let chapterID: String
//    let score: Int
//    let stars: Int
//    let isCompleted: Bool
//    let completedAt: Date
//}
//
//private struct ChildProgress {
//    private(set) var records: [SessionResult] = []
//
//    var isChapterFiveUnlocked: Bool {
//        (1...4).allSatisfy { index in
//            bestStarsByChapterID["chapter-\(index)", default: 0] >= 2
//        }
//    }
//
//    private var bestStarsByChapterID: [String: Int] {
//        records.reduce(into: [:]) { result, record in
//            guard record.isCompleted else {
//                return
//            }
//
//            result[record.chapterID] = max(result[record.chapterID, default: 0], record.stars)
//        }
//    }
//
//    mutating func recordChapterResult(chapterID: String, score: Int, stars: Int) {
//        recordSession(SessionResult(
//            chapterID: chapterID,
//            score: score,
//            stars: stars,
//            isCompleted: true,
//            completedAt: Date()
//        ))
//    }
//
//    mutating func recordSession(_ result: SessionResult) {
//        records.append(result)
//    }
//
//    func isActivityUnlocked(afterChapterID chapterID: String) -> Bool {
//        bestStarsByChapterID[chapterID, default: 0] >= 4
//    }
//}
//
//private struct InMemoryProgressStore {
//    private var savedResults: [SessionResult] = []
//
//    mutating func save(_ result: SessionResult) {
//        savedResults.append(result)
//    }
//
//    func loadLatestResult(forChapterID chapterID: String) -> SessionResult? {
//        savedResults
//            .filter { $0.chapterID == chapterID }
//            .max { $0.completedAt < $1.completedAt }
//    }
//}
